String sanitizeHandle(String input) {
  if (input.isEmpty) return input;
  // 1) Replace a broad set of Unicode whitespace characters with a dot
  var s = input.replaceAll(RegExp(r'[\s\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000]+'), '.');
  // 2) Normalize common fullwidth dot characters to ASCII dot
  s = s.replaceAll('。', '.').replaceAll('．', '.');
  // 3) Replace any character not allowed in identifiers with a dot
  s = s.replaceAll(RegExp(r'[^A-Za-z0-9@._-]'), '.');
  // 4) Collapse multiple dots and trim leading/trailing dots
  s = s.replaceAll(RegExp(r'\.+'), '.');
  s = s.replaceAll(RegExp(r'^\.'), '');
  s = s.replaceAll(RegExp(r'\.$'), '');
  return s;
}

String sanitizeHost(String host) {
  if (host.isEmpty) return 'bsky.social';
  var s = host.replaceAll(RegExp(r'[\s\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000]+'), '.');
  s = s.replaceAll('。', '.').replaceAll('．', '.');
  // Allow only letters, digits, dot and hyphen
  s = s.replaceAll(RegExp(r'[^A-Za-z0-9\.-]'), '.');
  s = s.replaceAll(RegExp(r'\.+'), '.');
  s = s.replaceAll(RegExp(r'^\.'), '');
  s = s.replaceAll(RegExp(r'\.$'), '');
  s = s.toLowerCase();
  return s.isEmpty ? 'bsky.social' : s;
}
