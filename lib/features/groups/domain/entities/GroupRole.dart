enum GroupRole {
  admin,
  member;

  static GroupRole fromValue(String value) {
    final normalized = value.toLowerCase();
    if (normalized == 'admin') {
      return GroupRole.admin;
    }
    return GroupRole.member;
  }

  String get value => name;
}
