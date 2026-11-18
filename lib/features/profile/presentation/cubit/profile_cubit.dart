import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/user_profile.dart';

class ProfileState extends Equatable {
  final bool loading;
  final bool saving;

  /// Why the last load failed. Cleared by the next successful load or save.
  final String? error;

  /// Null until loaded for the first time on this phone.
  final UserProfile? profile;

  const ProfileState({
    this.loading = false,
    this.saving = false,
    this.error,
    this.profile,
  });

  bool get isFemale => profile?.isFemale ?? false;

  ProfileState copyWith({
    bool? loading,
    bool? saving,
    String? error,
    UserProfile? profile,
  }) =>
      ProfileState(
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        error: error,
        profile: profile ?? this.profile,
      );

  @override
  List<Object?> get props => [loading, saving, error, profile];
}

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository repository;

  /// Starts from the copy kept on the phone so the screen does not wait for
  /// the server.
  ProfileCubit(this.repository)
      : super(ProfileState(profile: repository.cached));

  Future<void> load() async {
    if (state.loading) return;
    emit(state.copyWith(loading: true));
    final result = await repository.getProfile();
    if (isClosed) return;
    result.fold(
      (f) => emit(state.copyWith(loading: false, error: f.message)),
      // A save that finished meanwhile is newer than this answer.
      (p) => emit(state.copyWith(
          loading: false, profile: state.saving ? state.profile : p)),
    );
  }

  /// Returns an error message, or null on success.
  Future<String?> save(UserProfile profile) async {
    if (state.saving) return 'Still saving, please wait.';
    emit(state.copyWith(saving: true, error: state.error));
    final result = await repository.saveProfile(profile);
    if (isClosed) return null;
    return result.fold(
      (f) {
        emit(state.copyWith(saving: false, error: state.error));
        return f.message;
      },
      (saved) {
        emit(state.copyWith(saving: false, loading: false, profile: saved));
        return null;
      },
    );
  }
}
