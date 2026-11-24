import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_storage.dart';

/// Base URL of the Laravel API. 10.0.2.2 is the laptop's localhost as seen
/// from the Android emulator. For a real phone, pass the laptop's Wi-Fi IP:
/// flutter run --dart-define=API_URL=http://192.168.1.20:8000/api
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8000/api',
);

const networkErrorMessage =
    "Couldn't reach the server. Is the backend running?";

class ApiError {
  const ApiError({
    required this.message,
    this.errors = const {},
    this.isNetworkError = false,
  });

  final String message;

  /// First validation message per field, e.g. {'email': 'The email has already been taken.'}
  final Map<String, String> errors;

  /// True when the request never got an answer (backend down, wrong IP, timeout).
  final bool isNetworkError;
}

sealed class ApiResult {
  const ApiResult();
}

class ApiSuccess extends ApiResult {
  const ApiSuccess(this.data);

  /// Decoded JSON body, or null for 204 No Content.
  final dynamic data;
}

class ApiFailure extends ApiResult {
  const ApiFailure(this.error);

  final ApiError error;
}

class Api {
  /// Called after a 401 on a logged-in request, once storage is cleared.
  /// main.dart uses it to go back to the login screen.
  static void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 15);

  static Future<ApiResult> get(String path) => _request('GET', path);

  static Future<ApiResult> post(String path, [Object? body]) =>
      _request('POST', path, body);

  static Future<ApiResult> put(String path, [Object? body]) =>
      _request('PUT', path, body);

  static Future<ApiResult> delete(String path) => _request('DELETE', path);

  static Future<ApiResult> _request(
    String method,
    String path, [
    Object? body,
  ]) async {
    final token = await AuthStorage.getToken();
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final request = http.Request(method, Uri.parse('$apiUrl$path'))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    final http.Response res;
    try {
      res = await http.Response.fromStream(
        await request.send().timeout(_timeout),
      );
    } on Exception {
      // SocketException, ClientException, TimeoutException...
      return const ApiFailure(
        ApiError(message: networkErrorMessage, isNetworkError: true),
      );
    }

    // A 401 with a token means the session expired. Without a token
    // (e.g. a wrong password on login) it's a normal error to show.
    if (res.statusCode == 401 && token != null) {
      await AuthStorage.clear();
      onUnauthorized?.call();
    }

    dynamic data;
    if (res.statusCode != 204 && res.body.isNotEmpty) {
      try {
        data = jsonDecode(res.body);
      } on FormatException {
        data = null;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return ApiSuccess(data);
    }

    final errors = <String, String>{};
    String message = 'Something went wrong. Try again.';
    if (data is Map<String, dynamic>) {
      if (data['message'] is String) message = data['message'] as String;
      final rawErrors = data['errors'];
      if (rawErrors is Map<String, dynamic>) {
        rawErrors.forEach((field, messages) {
          if (messages is List && messages.isNotEmpty) {
            errors[field] = '${messages.first}';
          }
        });
      }
    }
    return ApiFailure(ApiError(message: message, errors: errors));
  }
}
