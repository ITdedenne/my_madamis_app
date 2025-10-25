// ファイルパス: lib/features/settings/presentation/viewmodels/update_email_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/settings/domain/usecases/update_email_usecase.dart';
import 'package:my_madamis_app/providers.dart';

enum UpdateEmailStatus { initial, loading, requiresConfirmation, error }

class UpdateEmailState {
  final UpdateEmailStatus status;
  final String? errorMessage;

  UpdateEmailState({this.status = UpdateEmailStatus.initial, this.errorMessage});

  UpdateEmailState copyWith({UpdateEmailStatus? status, String? errorMessage}) {
    return UpdateEmailState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final updateEmailViewModelProvider =
    StateNotifierProvider<UpdateEmailViewModel, UpdateEmailState>((ref) {
  final useCase = UpdateEmailUseCase(ref.watch(settingsRepositoryProvider));
  return UpdateEmailViewModel(useCase);
});

class UpdateEmailViewModel extends StateNotifier<UpdateEmailState> {
  final UpdateEmailUseCase _useCase;
  UpdateEmailViewModel(this._useCase) : super(UpdateEmailState());

  Future<void> updateEmail(String newEmail) async {
    state = state.copyWith(status: UpdateEmailStatus.loading);
    try {
      await _useCase(newEmail);
      state = state.copyWith(status: UpdateEmailStatus.requiresConfirmation);
    } catch (e) {
      state = state.copyWith(status: UpdateEmailStatus.error, errorMessage: e.toString());
    }
  }
}