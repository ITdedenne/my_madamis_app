import 'package:mockito/annotations.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/features/settings/domain/repositories/settings_repository.dart';

// AuthRepositoryとSettingsRepositoryのモックを生成するよう指定
@GenerateMocks([
  AuthRepository,
  SettingsRepository, // <-- これを追加
])
void main() {}