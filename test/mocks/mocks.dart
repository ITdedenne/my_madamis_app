// ignore: depend_on_referenced_packages
import 'package:mockito/annotations.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';

// AuthRepositoryのモックを生成するよう指定
//Mockをいじったら以下のコマンドを入力する。
//flutter pub run build_runner build --delete-conflicting-outputs
@GenerateMocks([AuthRepository])
void main() {}