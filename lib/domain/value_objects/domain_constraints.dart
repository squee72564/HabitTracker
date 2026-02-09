class DomainConstraints {
  static const int habitNameMinLength = 1;
  static const int habitNameMaxLength = 40;
  static const int habitNoteMaxLength = 120;
  static final RegExp localDayKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  const DomainConstraints._();
}
