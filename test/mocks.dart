// ファイルパス: test/mocks.dart

import 'package:mockito/annotations.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:my_madamis_app/features/settings/domain/repositories/settings_repository.dart';

// ↓↓↓ この部分を修正 ↓↓↓
@GenerateMocks([
  AuthRepository,
  ProfileRepository,
  SettingsRepository,
])
void main() {}