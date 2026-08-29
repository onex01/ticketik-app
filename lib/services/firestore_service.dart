import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getDeviceInfoByIp(String ip) async {
    if (ip == 'IP_не_определен') return null;

    final query = await _db
        .collection(FirestoreCollections.devices)
        .where('ip', isEqualTo: ip)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data();
    }
    return null;
  }

  Future<void> submitRequest({
    required String deviceId,
    required String ip,
    required String description,
    required String room,
    required String pcNumber,
    required String owner,
    required String osName,
  }) async {
    await _db.collection(FirestoreCollections.requests).add({
      'device_id': deviceId,
      'device_ip': ip,
      'description': description,
      'room': room,
      'pc_number': pcNumber,
      'owner': owner,
      'osName': osName,
      'status': RequestStatus.newRequest,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // НОВЫЙ МЕТОД: Обновление статуса заявки
  Future<void> updateTicketStatus(String ticketId, String newStatus) async {
    await _db.collection(FirestoreCollections.requests).doc(ticketId).update({
      'status': newStatus,
    });
  }
}