import 'package:flutter_test/flutter_test.dart';
import 'package:quit/utils/phone.dart';

void main() {
  test('normalizes common formats to E.164', () {
    expect(normalizeE164('+216 50-123-456'), '+21650123456');
    expect(normalizeE164('0021650123456'), '+21650123456');
    expect(normalizeE164('+1 (415) 555.2671'), '+14155552671');
  });

  test('rejects invalid numbers', () {
    expect(normalizeE164('12345'), isNull);
    expect(normalizeE164('21650123456'), isNull); // no country prefix marker
    expect(normalizeE164('+0123456789'), isNull);
    expect(normalizeE164('abc'), isNull);
    expect(normalizeE164(''), isNull);
  });
}
