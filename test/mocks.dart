// ファイルパス: test/mocks.dart

import 'package:amplify_flutter/amplify_flutter.dart'; // 追加
import 'package:mockito/annotations.dart';
import 'package:my_madamis_app/features/auth/data/auth_repository.dart';

// ResetPasswordResult をリストに追加
@GenerateMocks([AuthRepository, ResetPasswordResult])
void main() {}