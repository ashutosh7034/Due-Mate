import 'package:equatable/equatable.dart';

import 'enums.dart';

/// An entry in the in-app notification centre.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.taskId,
    this.readAt,
  });

  final String id;
  final String? taskId;
  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  bool get isUnread => readAt == null;

  bool get hasTask => taskId != null;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
    id: id,
    taskId: taskId,
    category: category,
    title: title,
    body: body,
    createdAt: createdAt,
    readAt: readAt ?? this.readAt,
  );

  @override
  List<Object?> get props => [
    id,
    taskId,
    category,
    title,
    body,
    createdAt,
    readAt,
  ];
}
