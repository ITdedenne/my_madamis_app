// ファイルパス: lib/features/settings/presentation/viewmodels/confirm_update_email_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/settings/domain/usecases/confirm_update_email_usecase.dart';
import 'package:my_madamis_app/providers.dart';

enum ConfirmUpdateEmailStatus { initial, loading, success, error }

class ConfirmUpdateEmailState {
  final ConfirmUpdateEmailStatus status;
  final String? errorMessage;

  ConfirmUpdateEmailState({this.status = ConfirmUpdateEmailStatus.initial, this.errorMessage});

  ConfirmUpdateEmailState copyWith({ConfirmUpdateEmailStatus? status, String? errorMessage}) {
    return ConfirmUpdateEmailState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final confirmUpdateEmailViewModelProvider =
    StateNotifierProvider<ConfirmUpdateEmailViewModel, ConfirmUpdateEmailState>((ref) {
  final useCase = ConfirmUpdateEmailUseCase(ref.watch(settingsRepositoryProvider));
  return ConfirmUpdateEmailViewModel(useCase);
});

class ConfirmUpdateEmailViewModel extends StateNotifier<ConfirmUpdateEmailState> {
  final ConfirmUpdateEmailUseCase _useCase;
  ConfirmUpdateEmailViewModel(this._useCase) : super(ConfirmUpdateEmailState());

  Future<void> confirmUpdateEmail(String code) async {
    state = state.copyWith(status: ConfirmUpdateEmailStatus.loading);
    try {
      await _useCase(code);
      state = state.copyWith(status: ConfirmUpdateEmailStatus.success);
    } catch (e) {
      state = state.copyWith(status: ConfirmUpdateEmailStatus.error, errorMessage: e.toString());
    }
  }
}