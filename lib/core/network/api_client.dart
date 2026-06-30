import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import 'app_exception.dart';

/// Thin wrapper around `package:http` that centralizes base-URL
/// resolution, JSON encode/decode, timeouts, status-code-to-exception
/// mapping, and bounded retries for idempotent reads.
///
/// Repositories never touch `http` directly — this is the single seam to
/// swap in Dio, add auth headers, or point at a different gateway without
/// touching feature code.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  /// GET is safe to retry automatically: it has no side effects.
  Future<dynamic> get(String path, {Map<String, String>? query}) {
    final uri = _uri(path, query);
    return _retrying(() => _client.get(uri, headers: _headers));
  }

  /// POST mutates server state, so we do NOT retry it automatically on
  /// timeout/network failure — a blind retry of "transfer money" could
  /// double-spend. Callers attach an idempotency key (see
  /// [core/utils/idempotency.dart]) so a *manual* user retry is safe even
  /// if the first attempt actually succeeded server-side.
  Future<dynamic> post(String path, {Object? body}) {
    final uri = _uri(path, null);
    return _single(() => _client.post(
          uri,
          headers: _headers,
          body: body == null ? null : jsonEncode(body),
        ));
  }

  Uri _uri(String path, Map<String, String>? query) {
    return Uri.parse('${AppConstants.baseUrl}$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
  }

  Future<dynamic> _retrying(Future<http.Response> Function() send) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        final response = await send().timeout(AppConstants.requestTimeout);
        return _handleResponse(response);
      } on TimeoutException {
        if (attempt > AppConstants.maxGetRetries) {
          throw const TimeoutAppException();
        }
      } on SocketException {
        if (attempt > AppConstants.maxGetRetries) {
          throw const NetworkException();
        }
      }
      await Future.delayed(Duration(milliseconds: 300 * attempt));
    }
  }

  Future<dynamic> _single(Future<http.Response> Function() send) async {
    try {
      final response = await send().timeout(AppConstants.requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw const TimeoutAppException();
    } on SocketException {
      throw const NetworkException();
    }
  }

  dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;

    if (status >= 200 && status < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String? serverMessage;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] is String) {
        serverMessage = decoded['message'] as String;
      }
    } catch (_) {
      // Body wasn't JSON — fall back to the generic per-status message.
    }

    if (kDebugMode) {
      debugPrint('[ApiClient] HTTP $status on ${response.request?.url}: $serverMessage');
    }

    switch (status) {
      case 400:
      case 422:
        throw ValidationException(serverMessage ?? 'Requête invalide.');
      case 401:
      case 403:
        throw AuthException(serverMessage ?? 'Non autorisé.');
      case 404:
        throw NotFoundException(serverMessage ?? 'Ressource introuvable.');
      default:
        if (status >= 500) throw ServerException(status, serverMessage);
        throw UnknownException(serverMessage ?? 'Erreur inattendue ($status).');
    }
  }

  void close() => _client.close();
}
