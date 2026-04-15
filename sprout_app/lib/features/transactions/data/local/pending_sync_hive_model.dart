class PendingSyncHiveModel {
  PendingSyncHiveModel({
    required this.queueId,
    required this.operationTypeIndex,
    required this.payloadJson,
  });

  final String queueId;
  final int operationTypeIndex;
  final String payloadJson;
}
