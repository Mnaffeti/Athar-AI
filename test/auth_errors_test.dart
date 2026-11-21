import 'package:flutter_test/flutter_test.dart';
import 'package:quit/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('hook 5xx is not treated as offline (Telegram "not linked")', () {
    final e = AuthRetryableFetchException(message: 'hook', statusCode: '500');
    expect(AuthService.isTransient(e), isFalse);
    expect(AuthService.errorMessage(e), isNot(contains('No connection')));
  });

  test('no status code means offline', () {
    final e = AuthRetryableFetchException(message: 'SocketException');
    expect(AuthService.isTransient(e), isTrue);
    expect(AuthService.errorMessage(e), contains('No connection'));
  });

  test('429 is transient', () {
    expect(
      AuthService.isTransient(AuthException('slow down', statusCode: '429')),
      isTrue,
    );
  });
}
