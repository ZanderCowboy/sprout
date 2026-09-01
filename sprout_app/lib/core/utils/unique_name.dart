class UniqueName {
  UniqueName._();

  static bool isTaken({
    required Iterable<({String id, String name})> existing,
    required String candidateName,
    String? excludeId,
  }) {
    final normalized = candidateName.trim().toLowerCase();
    return existing.any(
      (e) => e.id != excludeId && e.name.trim().toLowerCase() == normalized,
    );
  }
}
