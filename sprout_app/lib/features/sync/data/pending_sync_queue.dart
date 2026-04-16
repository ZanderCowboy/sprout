import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:sprout/features/transactions/export.dart';
import '../domain/pending_sync_operation.dart';

class PendingSyncQueue {
  PendingSyncQueue(this._box);

  final Box<PendingSyncHiveModel> _box;

  /// Called after each successful [enqueue] (e.g. trigger remote flush).
  void Function()? onEnqueued;

  static const _uuid = Uuid();

  Future<void> enqueue(PendingSyncOperationType type, String payloadJson) async {
    final queueId =
        '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}';
    await _box.put(
      queueId,
      PendingSyncHiveModel(
        queueId: queueId,
        operationTypeIndex: type.index,
        payloadJson: payloadJson,
      ),
    );
    onEnqueued?.call();
  }

  List<PendingSyncHiveModel> orderedPending() {
    final keys = _box.keys.cast<String>().toList()..sort();
    return keys.map((k) => _box.get(k)!).toList();
  }

  Future<void> remove(String queueId) => _box.delete(queueId);

  int get length => _box.length;
}
