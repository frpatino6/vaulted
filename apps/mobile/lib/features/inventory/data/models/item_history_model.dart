import 'package:intl/intl.dart';

class ItemHistoryModel {
  const ItemHistoryModel({
    required this.id,
    required this.action,
    required this.performedBy,
    required this.timestamp,
    this.fromPropertyId,
    this.toPropertyId,
    this.fromRoomId,
    this.toRoomId,
    this.notes,
  });

  final String id;
  final String action;
  final String performedBy;
  final DateTime timestamp;
  final String? fromPropertyId;
  final String? toPropertyId;
  final String? fromRoomId;
  final String? toRoomId;
  final String? notes;

  factory ItemHistoryModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    return ItemHistoryModel(
      id: rawId is String ? rawId : rawId?.toString() ?? '',
      action: json['action'] as String? ?? '',
      performedBy: json['performedBy'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      fromPropertyId: json['fromPropertyId'] as String?,
      toPropertyId: json['toPropertyId'] as String?,
      fromRoomId: json['fromRoomId'] as String?,
      toRoomId: json['toRoomId'] as String?,
      notes: json['notes'] as String?,
    );
  }

  String get formattedDate =>
      DateFormat.yMMMd().add_jm().format(timestamp.toLocal());

  String get actionLabel {
    final note =
        notes != null && notes!.isNotEmpty ? ' — $notes' : '';
    switch (action) {
      case 'moved':
        return 'Moved$note';
      case 'loaned':
        return 'Loaned$note';
      case 'returned':
        return 'Returned$note';
      case 'repaired':
        return 'Sent for repair$note';
      case 'valued':
        return 'Appraised$note';
      case 'status_changed':
        return 'Status changed$note';
      case 'maintenance_scheduled':
        return 'Maintenance scheduled$note';
      case 'maintenance_completed':
        return 'Maintenance completed$note';
      case 'maintenance_ai_suggested':
        return 'AI maintenance alert$note';
      default:
        final readable = action.isEmpty
            ? 'Unknown'
            : action[0].toUpperCase() +
                action.substring(1).replaceAll('_', ' ');
        return '$readable$note';
    }
  }
}
