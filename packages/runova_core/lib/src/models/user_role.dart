import 'dart:convert';
import 'package:crypto/crypto.dart';

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

/// Shop Information / Multi-tenant entity.
class ShopInfo {
  final String id;
  final String name;
  final String nameBengali;
  final String address;
  final String phone;
  final String ownerUid;
  final DateTime createdAt;

  const ShopInfo({
    required this.id,
    required this.name,
    this.nameBengali = '',
    required this.address,
    required this.phone,
    required this.ownerUid,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'name_bengali': nameBengali,
    'address': address,
    'phone': phone,
    'owner_uid': ownerUid,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory ShopInfo.fromMap(Map<String, dynamic> map) => ShopInfo(
    id: map['id'] as String,
    name: map['name'] as String,
    nameBengali: (map['name_bengali'] ?? '') as String,
    address: (map['address'] ?? '') as String,
    phone: (map['phone'] ?? '') as String,
    ownerUid: map['owner_uid'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}

/// User profile stored in Firestore / Local DB.
class UserProfile {
  final String uid;
  final String shopId;
  final UserRole role;
  final String displayName;
  final String? email;
  final String? workerCode;
  final bool active;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.shopId,
    required this.role,
    required this.displayName,
    this.email,
    this.workerCode,
    this.active = true,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isWorker => role == UserRole.worker;

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'shop_id': shopId,
    'role': role.name,
    'display_name': displayName,
    'email': email,
    'worker_code': workerCode,
    'active': active ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    uid: map['uid'] as String,
    shopId: map['shop_id'] as String,
    role: UserRole.values.firstWhere(
      (r) => r.name == map['role'],
      orElse: () => UserRole.worker,
    ),
    displayName: map['display_name'] as String,
    email: map['email'] as String?,
    workerCode: map['worker_code'] as String?,
    active: map['active'] == true || map['active'] == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}

/// Worker provisioned by Admin with Fast PIN access.
class WorkerAccount {
  final String id;
  final String shopId;
  final String workerCode;
  final String name;
  final String pinHash;
  final bool active;
  final DateTime createdAt;

  const WorkerAccount({
    required this.id,
    required this.shopId,
    required this.workerCode,
    required this.name,
    required this.pinHash,
    this.active = true,
    required this.createdAt,
  });

  /// Cryptographic SHA-256 hash for 4-digit PIN salted with shopId.
  static String hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:runova_pin:$pin');
    return sha256.convert(bytes).toString();
  }

  bool verifyPin(String enteredPin) {
    return pinHash == hashPin(enteredPin, shopId);
  }

  WorkerAccount copyWith({
    String? name,
    String? pinHash,
    bool? active,
  }) {
    return WorkerAccount(
      id: id,
      shopId: shopId,
      workerCode: workerCode,
      name: name ?? this.name,
      pinHash: pinHash ?? this.pinHash,
      active: active ?? this.active,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'shop_id': shopId,
    'worker_code': workerCode,
    'name': name,
    'pin_hash': pinHash,
    'active': active ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory WorkerAccount.fromMap(Map<String, dynamic> map) => WorkerAccount(
    id: map['id'] as String,
    shopId: map['shop_id'] as String,
    workerCode: map['worker_code'] as String,
    name: map['name'] as String,
    pinHash: (map['pin_hash'] ?? '') as String,
    active: map['active'] == 1 || map['active'] == true,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}

/// Active Session stored locally for offline counter usage.
class AppSession {
  final String shopId;
  final String userId;
  final UserRole role;
  final String displayName;
  final String shopName;
  final String? workerCode;
  final DateTime lastLoginAt;

  const AppSession({
    required this.shopId,
    required this.userId,
    required this.role,
    required this.displayName,
    required this.shopName,
    this.workerCode,
    required this.lastLoginAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isWorker => role == UserRole.worker;

  Map<String, dynamic> toMap() => {
    'shop_id': shopId,
    'user_id': userId,
    'role': role.name,
    'display_name': displayName,
    'shop_name': shopName,
    'worker_code': workerCode,
    'last_login_at': lastLoginAt.millisecondsSinceEpoch,
  };

  factory AppSession.fromMap(Map<String, dynamic> map) => AppSession(
    shopId: map['shop_id'] as String,
    userId: map['user_id'] as String,
    role: UserRole.values.firstWhere(
      (r) => r.name == map['role'],
      orElse: () => UserRole.worker,
    ),
    displayName: map['display_name'] as String,
    shopName: map['shop_name'] as String,
    workerCode: map['worker_code'] as String?,
    lastLoginAt: DateTime.fromMillisecondsSinceEpoch(map['last_login_at'] as int),
  );
}
