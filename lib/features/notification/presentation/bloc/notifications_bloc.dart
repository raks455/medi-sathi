import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/notification_usecases.dart';

// ---- events ----

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

/// Loads (or refreshes) the newest notifications and the unread count.
class NotificationsRequested extends NotificationsEvent {
  const NotificationsRequested();
}

/// Loads the next, older page.
class NotificationsMoreRequested extends NotificationsEvent {
  const NotificationsMoreRequested();
}

class NotificationMarkedRead extends NotificationsEvent {
  final String id;
  const NotificationMarkedRead(this.id);
  @override
  List<Object?> get props => [id];
}

class NotificationsAllMarkedRead extends NotificationsEvent {
  const NotificationsAllMarkedRead();
}

// ---- state ----

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<AppNotification> items;

  /// Shown as the badge on the dashboard bell.
  final int unreadCount;
  final bool hasMore;
  final bool loadingMore;

  /// Error text when [status] is failure.
  final String? message;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.unreadCount = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.message,
  });

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    int? unreadCount,
    bool? hasMore,
    bool? loadingMore,
    String? message,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, unreadCount, hasMore, loadingMore, message];
}

// ---- bloc ----

/// The in-app notification list and its unread count.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  static const _pageSize = 30;

  final GetNotifications getNotifications;
  final MarkNotificationRead markNotificationRead;
  final MarkAllNotificationsRead markAllNotificationsRead;

  NotificationsBloc({
    required this.getNotifications,
    required this.markNotificationRead,
    required this.markAllNotificationsRead,
  }) : super(const NotificationsState()) {
    on<NotificationsRequested>(_onRequested);
    on<NotificationsMoreRequested>(_onMoreRequested);
    on<NotificationMarkedRead>(_onMarkedRead);
    on<NotificationsAllMarkedRead>(_onAllMarkedRead);
  }

  Future<void> _onRequested(
      NotificationsRequested e, Emitter<NotificationsState> emit) async {
    emit(state.copyWith(status: NotificationsStatus.loading));
    final result =
        await getNotifications(const NotificationsParams(limit: _pageSize));
    emit(result.fold(
      (f) => state.copyWith(
          status: NotificationsStatus.failure, message: f.message),
      (page) => state.copyWith(
        status: NotificationsStatus.success,
        items: page.items,
        unreadCount: page.unreadCount,
        hasMore: page.hasMore,
      ),
    ));
  }

  Future<void> _onMoreRequested(
      NotificationsMoreRequested e, Emitter<NotificationsState> emit) async {
    if (state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    final result = await getNotifications(
        NotificationsParams(limit: _pageSize, offset: state.items.length));
    emit(result.fold(
      // Keep what is shown; the user can scroll again to retry.
      (f) => state.copyWith(loadingMore: false),
      (page) {
        // A notification that arrived meanwhile shifts the pages by one,
        // so skip anything already in the list.
        final known = state.items.map((n) => n.id).toSet();
        return state.copyWith(
          loadingMore: false,
          items: [
            ...state.items,
            ...page.items.where((n) => !known.contains(n.id)),
          ],
          unreadCount: page.unreadCount,
          hasMore: page.hasMore,
        );
      },
    ));
  }

  Future<void> _onMarkedRead(
      NotificationMarkedRead e, Emitter<NotificationsState> emit) async {
    final index = state.items.indexWhere((n) => n.id == e.id);
    if (index < 0 || state.items[index].isRead) return;
    // Shown as read straight away; a failed request only means it shows as
    // unread again after the next refresh.
    emit(state.copyWith(
      items: [
        for (final n in state.items) n.id == e.id ? n.asRead() : n,
      ],
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    ));
    await markNotificationRead(e.id);
  }

  Future<void> _onAllMarkedRead(
      NotificationsAllMarkedRead e, Emitter<NotificationsState> emit) async {
    if (state.unreadCount == 0) return;
    final before = state;
    emit(state.copyWith(
      items: [for (final n in state.items) n.asRead()],
      unreadCount: 0,
    ));
    final result = await markAllNotificationsRead(const NoParams());
    // Put the unread marks back if the server did not accept it.
    if (result.isLeft()) {
      emit(state.copyWith(items: before.items, unreadCount: before.unreadCount));
    }
  }
}
