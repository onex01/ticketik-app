class DeviceModel {
  final String ip;
  final String room;
  final String pcNumber;
  final String owner;

  DeviceModel({
    required this.ip,
    required this.room,
    required this.pcNumber,
    required this.owner,
  });

  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    return DeviceModel(
      ip: map['ip'] ?? '',
      room: map['room'] ?? 'Неизвестно',
      pcNumber: map['pc_number'] ?? 'Не указан',
      owner: map['owner'] ?? 'Аноним',
    );
  }
}