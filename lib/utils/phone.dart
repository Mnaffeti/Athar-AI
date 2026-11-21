/// Normalizes a typed phone number to E.164 (`+21650123456`), or null if invalid.
/// Accepts spaces, dashes, dots, parentheses and a leading `00`.
String? normalizeE164(String input) {
  var s = input.replaceAll(RegExp(r'[\s\-.()]'), '');
  if (s.startsWith('00')) s = '+${s.substring(2)}';
  return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(s) ? s : null;
}
