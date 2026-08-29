import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String id;
  final String deviceId;
  final String deviceIp;
  final String description;
  final String room;
  final String pcNumber;
  final String owner;
  final String osName;
  final String status;
  final DateTime? timestamp;
  final bool isDeleted;

  TicketModel({
    required this.id,
    required this.deviceId,
    required this.deviceIp,
    required this.description,
    required this.room,
    required this.pcNumber,
    required this.owner,
    required this.osName,
    required this.status,
    this.timestamp,
    this.isDeleted = false,
  });

  factory TicketModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TicketModel(
      id: doc.id,
      deviceId: data['device_id'] ?? '',
      deviceIp: data['device_ip'] ?? '',
      description: data['description'] ?? '',
      room: data['room'] ?? 'Неизвестно',
      pcNumber: data['pc_number'] ?? 'Не указан',
      owner: data['owner'] ?? 'Аноним',
      osName: data['os_name'] ?? 'Неизвестно',
      status: data['status'] ?? 'new',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      isDeleted: data['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'device_id': deviceId,
      'device_ip': deviceIp,
      'description': description,
      'room': room,
      'pc_number': pcNumber,
      'owner': owner,
      'os_name': osName,
      'status': status,
      'is_deleted': isDeleted,
    };
  }
}