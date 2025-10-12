import 'package:mockito/annotations.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:my_madamis_app/features/settings/domain/repositories/settings_repository.dart';

// AuthRepository, SettingsRepository, ProfileRepositoryのモックを生成するよう指定
//flutter pub run build_runner build --delete-conflicting-outputs
@GenerateMocks([
  AuthRepository,
  SettingsRepository,
  ProfileRepository, 
])
void main() {}