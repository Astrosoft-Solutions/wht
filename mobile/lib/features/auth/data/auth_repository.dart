import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import 'user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(dioProvider)));

class AuthResult {
  const AuthResult(this.token, this.user);
  final String token;
  final AppUser user;
}

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthResult> login({required String login, required String password}) => guardApi(() async {
        final res = await _dio.post('/login', data: {'login': login, 'password': password});
        return _result(res.data);
      });

  Future<AuthResult> register({
    required String name,
    required String email,
    String? mobile,
    required String password,
    String coachType = 'coach',
  }) =>
      guardApi(() async {
        final res = await _dio.post('/register', data: {
          'name': name,
          'email': email,
          if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
          'password': password,
          'password_confirmation': password,
          'coach_type': coachType,
        });
        return _result(res.data);
      });

  Future<String> changePassword({String? currentPassword, required String newPassword}) => guardApi(() async {
        final res = await _dio.put('/me/password', data: {
          'current_password': ?currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        });
        return res.data['message'] as String;
      });

  Future<AppUser> uploadAvatar(XFile file) => guardApi(() async {
        final bytes = await file.readAsBytes();
        final form = FormData.fromMap({
          'avatar': MultipartFile.fromBytes(bytes, filename: file.name.isEmpty ? 'avatar.jpg' : file.name),
        });
        final res = await _dio.post('/me/avatar', data: form);
        return AppUser.fromJson(res.data['data'] as Map<String, dynamic>);
      });

  Future<AppUser> deleteAvatar() => guardApi(() async {
        final res = await _dio.delete('/me/avatar');
        return AppUser.fromJson(res.data['data'] as Map<String, dynamic>);
      });

  /// Accounts with a password confirm with it; Google-only accounts confirm by typing DELETE.
  Future<void> deleteAccount({String? password}) => guardApi(
        () => _dio.delete('/me', data: password != null ? {'password': password} : {'confirm': 'DELETE'}),
      );

  Future<AuthResult> loginWithGoogle(String idToken) => guardApi(() async {
        final res = await _dio.post('/auth/google', data: {'id_token': idToken});
        return _result(res.data);
      });

  Future<String> forgotPassword(String email) => guardApi(() async {
        final res = await _dio.post('/forgot-password', data: {'email': email});
        return res.data['message'] as String;
      });

  Future<AppUser> me() => guardApi(() async {
        final res = await _dio.get('/me');
        return AppUser.fromJson(res.data['data'] as Map<String, dynamic>);
      });

  Future<AppUser> updateProfile({required String name, String? mobile}) => guardApi(() async {
        final res = await _dio.put('/me', data: {'name': name, 'mobile': mobile});
        return AppUser.fromJson(res.data['data'] as Map<String, dynamic>);
      });

  Future<void> logout() => guardApi(() => _dio.post('/logout'));

  AuthResult _result(dynamic data) => AuthResult(
        data['token'] as String,
        AppUser.fromJson(data['user'] as Map<String, dynamic>),
      );
}
