import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokens = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokens.read();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final data = error.response?.data;
        final isLoginAttempt = error.requestOptions.path.endsWith('/login');
        if (status == 401 && !isLoginAttempt) {
          await tokens.clear(reason: SessionNotice.expired);
        } else if (status == 403 && data is Map && data['code'] == 'account_inactive') {
          await tokens.clear(reason: SessionNotice.deactivated);
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;

  /// Machine-readable reason sent by the API, e.g. `plan_limit`.
  final String? code;
  final Map<String, String> fieldErrors;

  bool get isPlanLimit => code == 'plan_limit';

  /// No response from the server at all (offline, DNS, timeout).
  bool get isNetwork => statusCode == null && code == 'network';

  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final response = error.response;
      final data = response?.data;
      if (data is Map) {
        final errors = <String, String>{};
        final raw = data['errors'];
        if (raw is Map) {
          raw.forEach((key, value) {
            if (value is List && value.isNotEmpty) errors[key.toString()] = value.first.toString();
          });
        }
        final message = errors.isNotEmpty
            ? errors.values.first
            : (data['message']?.toString() ?? 'Something went wrong.');
        return ApiException(
          message,
          statusCode: response?.statusCode,
          code: data['code']?.toString(),
          fieldErrors: errors,
        );
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return ApiException('Cannot reach the server. Check your connection.', code: 'network');
      }
      return ApiException(error.message ?? 'Request failed.', statusCode: response?.statusCode);
    }
    return ApiException(error.toString());
  }

  @override
  String toString() => message;
}

/// Runs a request and converts any failure into an [ApiException].
Future<T> guardApi<T>(Future<T> Function() request) async {
  try {
    return await request();
  } catch (e) {
    throw ApiException.from(e);
  }
}
