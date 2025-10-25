// ファイルパス: lib/features/settings/presentation/viewmodels/update_password_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/settings/domain/usecases/update_password_usecase.dart';
import 'package:my_madamis_app/providers.dart';

enum UpdatePasswordStatus { initial, loading, success, error }

class UpdatePasswordState {
  final UpdatePasswordStatus status;
  final String? errorMessage;

  UpdatePasswordState({this.status = UpdatePasswordStatus.initial, this.errorMessage});

  UpdatePasswordState copyWith({UpdatePasswordStatus? status, String? errorMessage}) {
    return UpdatePasswordState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final updatePasswordViewModelProvider =
    StateNotifierProvider<UpdatePasswordViewModel, UpdatePasswordState>((ref) {
  final useCase = UpdatePasswordUseCase(ref.watch(settingsRepositoryProvider));
  return UpdatePasswordViewModel(useCase);
});

class UpdatePasswordViewModel extends StateNotifier<UpdatePasswordState> {
  final UpdatePasswordUseCase _useCase;
  UpdatePasswordViewModel(this._useCase) : super(UpdatePasswordState());

  Future<void> updatePassword({required String oldPassword, required String newPassword}) async {
    state = state.copyWith(status: UpdatePasswordStatus.loading);
    try {
      await _useCase(oldPassword: oldPassword, newPassword: newPassword);
      state = state.copyWith(status: UpdatePasswordStatus.success);
    } catch (e) {
      state = state.copyWith(status: UpdatePasswordStatus.error, errorMessage: e.toString());
    }
  }
}