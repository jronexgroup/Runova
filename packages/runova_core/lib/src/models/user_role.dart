/// User roles supported by Runova Shop system (PRD Section 4).
enum UserRole {
  admin('Admin / Shop Owner', 'দোকানের মালিক'),
  worker('Repair Worker', 'মেরামত কর্মী');

  final String label;
  final String labelBengali;

  const UserRole(this.label, this.labelBengali);

  bool get isAdmin => this == UserRole.admin;
  bool get isWorker => this == UserRole.worker;
}
