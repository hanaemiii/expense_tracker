import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di/dependencies.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../domain/entities/user_profile.dart';

class ProfileState {
  const ProfileState({
    this.profile,
    this.ready = false,
    this.busy = false,
    this.error,
    this.notice,
    this.noticeIsError = false,
    this.noticeId = 0,
    this.pendingImagePath,
  });

  final UserProfile? profile;
  final bool ready;
  final bool busy;
  final String? error;
  final String? notice;
  final bool noticeIsError;
  final int noticeId;
  final String? pendingImagePath;

  String? get imagePath => pendingImagePath ?? profile?.profileImagePath;

  ProfileState copyWith({
    UserProfile? profile,
    bool? ready,
    bool? busy,
    String? error,
    bool clearError = false,
    String? notice,
    bool? noticeIsError,
    int? noticeId,
    String? pendingImagePath,
    bool clearPendingImage = false,
  }) => ProfileState(
    profile: profile ?? this.profile,
    ready: ready ?? this.ready,
    busy: busy ?? this.busy,
    error: clearError ? null : error ?? this.error,
    notice: notice ?? this.notice,
    noticeIsError: noticeIsError ?? this.noticeIsError,
    noticeId: noticeId ?? this.noticeId,
    pendingImagePath: clearPendingImage
        ? null
        : pendingImagePath ?? this.pendingImagePath,
  );
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this.dependencies) : super(const ProfileState()) {
    reload();
  }

  final AppDependencies dependencies;
  StreamSubscription<UserProfile>? _subscription;

  Future<void> reload() async {
    await _subscription?.cancel();
    if (isClosed) return;
    emit(state.copyWith(ready: false, clearError: true));
    _subscription = dependencies.profiles.watch().listen(
      (profile) {
        if (!isClosed) emit(state.copyWith(profile: profile, ready: true));
      },
      onError: (Object error) {
        if (!isClosed) emit(state.copyWith(error: friendlyError(error)));
      },
    );
  }

  void _notice(String message, {bool error = false}) {
    if (isClosed) return;
    emit(
      state.copyWith(
        notice: message,
        noticeIsError: error,
        noticeId: state.noticeId + 1,
      ),
    );
  }

  Future<void> choosePicture() async {
    if (state.busy || !state.ready) return;
    emit(state.copyWith(busy: true));
    try {
      final path = await dependencies.receipts.pickFromGallery();
      if (!isClosed && path != null) {
        emit(state.copyWith(pendingImagePath: path));
      }
    } catch (error) {
      _notice(friendlyError(error), error: true);
    } finally {
      if (!isClosed) emit(state.copyWith(busy: false));
    }
  }

  Future<bool> save({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final current = state.profile;
    if (state.busy || current == null) return false;
    emit(state.copyWith(busy: true));
    try {
      final saved = await dependencies.profiles.save(
        current.copyWith(
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          email: email.trim(),
          profileImagePath: state.imagePath,
        ),
      );
      if (!isClosed) {
        emit(
          state.copyWith(profile: saved, clearPendingImage: true, busy: false),
        );
        _notice('Profile updated');
      }
      return true;
    } catch (error) {
      _notice(friendlyError(error), error: true);
      return false;
    } finally {
      if (!isClosed && state.busy) emit(state.copyWith(busy: false));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
