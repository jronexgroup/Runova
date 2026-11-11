import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages Firebase initialization and connectivity state.
/// Designed to run gracefully offline-first until Firebase credentials are provided.
class FirebaseManager {
  static final FirebaseManager instance = FirebaseManager._();
  FirebaseManager._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  FirebaseFirestore? get firestore {
    if (!_isInitialized) return null;
    return FirebaseFirestore.instance;
  }

  /// Attempts to initialize Firebase.
  /// If credentials or google-services.json are not present, catches error and remains in local mode.
  Future<bool> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        return true;
      }

      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint('[FirebaseManager] Firebase initialized successfully with active credentials.');
      return true;
    } catch (e) {
      _isInitialized = false;
      debugPrint('[FirebaseManager] Running in Local-First SQLite mode (Waiting for Firebase Credentials): $e');
      return false;
    }
  }
}
