// ignore: depend_on_referenced_packages
import 'package:mockito/annotations.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';

// AuthRepositoryのモックを生成するよう指定
@GenerateMocks([AuthRepository])
void main() {}