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

  Future<void> addDevice({
    required String ip,
    required String room,
    required String pcNumber,
    required String owner,
  }) async {
    await _db.collection(FirestoreCollections.devices).doc(ip).set({
      'ip': ip,
      'room': room,
      'pc_number': pcNumber,
      'owner': owner,
    });
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
      'os_name': osName,
      'status': RequestStatus.newRequest,
      'timestamp': FieldValue.serverTimestamp(),
      'is_deleted': false,
    });
  }

  // НОВЫЙ МЕТОД: Обновление статуса заявки
  Future<void> updateTicketStatus(String ticketId, String newStatus) async {
    await _db.collection(FirestoreCollections.requests).doc(ticketId).update({
      'status': newStatus,
    });
  }

  // Метод для мягкого удаления (помечает как удаленную для админки)
  Future<void> softDeleteTicket(String ticketId) async {
    await _db.collection(FirestoreCollections.requests).doc(ticketId).update({
      'is_deleted': true,
    });
  }

  // Получение всех заявок (для админки - включая удаленные)
  Stream<QuerySnapshot> getAllTicketsStream() {
    return _db
        .collection(FirestoreCollections.requests)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Получение только активных заявок (не удаленных)
  Stream<QuerySnapshot> getActiveTicketsStream() {
    return _db
        .collection(FirestoreCollections.requests)
        .where('is_deleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Получение истории по IP (только активные, не удаленные)
  Stream<QuerySnapshot> getUserHistoryStream(String ip) {
    return _db
        .collection(FirestoreCollections.requests)
        .where('device_ip', isEqualTo: ip)
        .where('is_deleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Получение всей истории по IP (включая удаленные) - для отладки
  Stream<QuerySnapshot> getAllUserHistoryStream(String ip) {
    return _db
        .collection(FirestoreCollections.requests)
        .where('device_ip', isEqualTo: ip)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}