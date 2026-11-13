import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../local/worker_database.dart';

class WorkerSyncService {
  static final WorkerSyncService instance = WorkerSyncService._();
  WorkerSyncService._();

  bool _isSyncing = false;

  Future<void> drainOutbox(String shopId) async {
    if (_isSyncing || shopId.isEmpty) return;
    if (Firebase.apps.isEmpty) return;
    _isSyncing = true;

    try {
      final db = WorkerDatabase.instance;
      final tasks = await db.getPendingSyncTasks();

      if (tasks.isEmpty) {
        _isSyncing = false;
        return;
      }

      final firestore = FirebaseFirestore.instance;

      for (final task in tasks) {
        final taskId = task['id'] as String;
        final collectionName = task['collection_name'] as String;
        final docId = task['document_id'] as String;
        final payload = jsonDecode(task['payload_json'] as String) as Map<String, dynamic>;

        try {
          await firestore
              .collection('shops')
              .doc(shopId)
              .collection(collectionName)
              .doc(docId)
              .set(payload, SetOptions(merge: true));

          await db.markSyncTaskDone(taskId);
        } catch (e) {
          debugPrint('[WorkerSyncService] Outbox sync error: $e');
          break;
        }
      }
    } catch (e) {
      debugPrint('[WorkerSyncService] Loop error: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
