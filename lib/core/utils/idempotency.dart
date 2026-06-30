import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Generates a fresh idempotency key for a mutating request (transfer,
/// pay-factures). Sent as `idempotencyKey` in the request body so that if
/// the client times out waiting for a response and the user retries, a
/// backend that honors the key processes the operation once instead of
/// double-spending. Generate one key per *user-initiated* attempt — not
/// once per app session.
String newIdempotencyKey() => _uuid.v4();
