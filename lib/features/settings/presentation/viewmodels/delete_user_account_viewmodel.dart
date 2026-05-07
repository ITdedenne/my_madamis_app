// ファイルパス: lib/features/settings/presentation/viewmodels/delete_user_account_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/settings/domain/usecases/delete_user_account_usecase.dart';
import 'package:my_madamis_app/providers.dart';

enum DeleteAccountStatus { initial, loading, success, error }

class DeleteAccountState {
  final DeleteAccountStatus status;
  final String? errorMessage;

  DeleteAccountState({
    this.status = DeleteAccountStatus.initial,
    this.errorMessage,
  });

  DeleteAccountState copyWith({
    DeleteAccountStatus? status,
    String? errorMessage,
  }) {
    return DeleteAccountState(
      status: status ?? this.status,
      errorMessage: errorMessage, // nullを渡せばクリア
    );
  }
}

final deleteUserAccountUseCaseProvider = Provider<DeleteUserAccountUseCase>((ref) {
  return DeleteUserAccountUseCase(ref.watch(settingsRepositoryProvider));
});

final deleteAccountViewModelProvider =
    StateNotifierProvider<DeleteAccountViewModel, DeleteAccountState>((ref) {
  return DeleteAccountViewModel(ref);
});

class DeleteAccountViewModel extends StateNotifier<DeleteAccountState> {
  final Ref _ref;

  DeleteAccountViewModel(this._ref) : super(DeleteAccountState());

  Future<void> deleteAccount() async {
    state = state.copyWith(status: DeleteAccountStatus.loading, errorMessage: null);
    try {
      final useCase = _ref.read(deleteUserAccountUseCaseProvider);
      await useCase();
      
      state = state.copyWith(status: DeleteAccountStatus.success);
      
      // リポジトリ層でサインアウトしているが、念のためアプリの認証状態もリセットする
      _ref.read(authStateNotifierProvider.notifier).signOut();
      
    } catch (e) {
      state = state.copyWith(
        status: DeleteAccountStatus.error,
        errorMessage: '退会処理に失敗しました: $e',
      );
    }
  }
  
  void resetState() {
    state = DeleteAccountState();
  }
}