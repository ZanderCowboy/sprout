/// Display-name rules for goals, accounts, and similar user-facing labels.
class EntityName {
  EntityName._();

  static final _hasLetter = RegExp(r'\p{L}', unicode: true);
  static final _allowedChars = RegExp(
    r"^[\p{L}\p{N} '\-&./()#]+$",
    unicode: true,
  );

  /// True when [name] looks like a readable label (not empty symbol soup).
  ///
  /// Requires at least two characters, one letter, and only letters, numbers,
  /// spaces, and `' - & . / ( ) #`.
  static bool isValid(String name) {
    final trimmed = name.trim();
    if (trimmed.length < 2) return false;
    if (!_hasLetter.hasMatch(trimmed)) return false;
    return _allowedChars.hasMatch(trimmed);
  }
}
