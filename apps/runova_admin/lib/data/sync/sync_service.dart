import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../local/app_database.dart';
import '../remote/firebase_manager.dart';

/// High-Priority Bidirectional Synchronization Engine (PRD Section 10.1).
/// Drains local outbox mutations to Cloud Firestore upon network connectivity.
class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  bool _isSyncing = false;

  /// Trigger sync drainage. High priority, safe to invoke after every local mutation.
  Future<void> syncOutbox() async {
    if (_isSyncing) return;
    if (!FirebaseManager.instance.isInitialized) {
      debugPrint('[SyncService] Firebase not yet connected. Mutations saved safely in local SQLite outbox.');
      return;
    }

    _isSyncing = true;
    try {
      final db = AppDatabase.instance;
      final pendingTasks = await db.getPendingSyncTasks();

      if (pendingTasks.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('[SyncService] Draining ${pendingTasks.length} pending local mutations to Firestore...');

      final firestore = FirebaseFirestore.instance;

      for (final task in pendingTasks) {
        final taskId = task['id'] as String;
        final collectionName = task['collection_name'] as String;
        final docId = task['document_id'] as String;
        final payload = jsonDecode(task['payload_json'] as String) as Map<String, dynamic>;

        try {
          if (collectionName == 'shops') {
            await firestore.collection('shops').doc(docId).set(payload, SetOptions(merge: true));
          } else if (collectionName == 'users') {
            await firestore.collection('users').doc(docId).set(payload, SetOptions(merge: true));
          } else {
            // Scope multi-tenant data under shops/{shopId}/{collection}
            final shopId = payload['shop_id'] as String? ?? '';
            if (shopId.isNotEmpty) {
              await firestore
                  .collection('shops')
                  .doc(shopId)
                  .collection(collectionName)
                  .doc(docId)
                  .set(payload, SetOptions(merge: true));
            } else {
              await firestore
                  .collection(collectionName)
                  .doc(docId)
                  .set(payload, SetOptions(merge: true));
            }
          }

          await db.markSyncTaskDone(taskId);
          debugPrint('[SyncService] Synced $collectionName/$docId to Firestore ✓');
        } catch (err) {
          debugPrint('[SyncService] Failed to sync task $taskId: $err');
          break; // Stop loop on network failure until next trigger
        }
      }
    } catch (e) {
      debugPrint('[SyncService] Sync loop error: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
