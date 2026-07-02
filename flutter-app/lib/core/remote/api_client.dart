import 'dart:async';
import 'dart:developer';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:ai_trading_copilot/core/end_points.dart';
import 'package:ai_trading_copilot/services/pref_keys.dart';
import 'package:ai_trading_copilot/services/shared_pref_services.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────────────────────

class ApiConfig {
  const ApiConfig._();

  static const Duration connectTimeout = Duration(minutes: 2);
  static const Duration receiveTimeout = Duration(minutes: 2);
}

// ─────────────────────────────────────────────────────────────
// Exception
// ─────────────────────────────────────────────────────────────

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException e) {
    return ApiException(
      e.response?.data?['message']?.toString() ??
          e.message ??
          'Something went wrong',
      statusCode: e.response?.statusCode,
    );
  }

  @override
  String toString() {
    return 'ApiException($statusCode): $message';
  }
}

// ─────────────────────────────────────────────────────────────
// Token Refresh Guard
// ─────────────────────────────────────────────────────────────

class _TokenRefreshGuard {
  Completer<String>? _pending;

  Future<String> refresh() async {
    if (_pending != null) {
      return _pending!.future;
    }

    _pending = Completer<String>();

    try {
      final token = await _doRefresh();
      _pending!.complete(token);
      return token;
    } catch (e) {
      _pending!.completeError(e);
      rethrow;
    } finally {
      _pending = null;
    }
  }

  Future<String> _doRefresh() async {
    String? refreshToken = SharedPreferenceService.getValue<String>(PrefKeys.refreshToken);
    if (refreshToken == null || refreshToken.isEmpty) {
      refreshToken = html.window.localStorage['coinastra_refresh'];
    }
    refreshToken ??= '';

    final dio = Dio(
      BaseOptions(
        baseUrl: EndPoints.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
      ),
    );

    final response = await dio.post(
      EndPoints.generateNewToken,
      data: {
        'refreshToken': refreshToken,
      },
    );

    final data = response.data['data'];

    final accessToken =
        data['access']?['token']?.toString() ?? '';

    final newRefreshToken =
        data['refresh']?['token']?.toString() ?? '';

    if (accessToken.isEmpty) {
      throw const ApiException('Failed to refresh token');
    }

    await SharedPreferenceService.setValue(
      PrefKeys.accessToken,
      accessToken,
    );

    if (newRefreshToken.isNotEmpty) {
      await SharedPreferenceService.setValue(
        PrefKeys.refreshToken,
        newRefreshToken,
      );
    }

    return accessToken;
  }
}

// ─────────────────────────────────────────────────────────────
// Auth Interceptor
// ─────────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({
    required this.dio,
    required this.guard,
  });

  final Dio dio;
  final _TokenRefreshGuard guard;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Prefer SharedPreferences (in-memory cache), but fall back to the
    // raw localStorage key written by Next.js — avoids a race condition on
    // first page navigation before the async SharedPreferences sync completes.
    String? token = SharedPreferenceService.getValue<String>(PrefKeys.accessToken);
    if (token == null || token.isEmpty) {
      token = html.window.localStorage['coinastra_access'];
    }

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] =
          'Bearer $token';
    }

    // VERY IMPORTANT FOR NGROK
    options.headers['ngrok-skip-browser-warning'] =
        'true';

    log('');
    log('━━━━━━━━━━━━━━━━━━━');
    log('API REQUEST');
    log('${options.method} ${options.uri}');
    log('Headers: ${options.headers}');
    log('Query: ${options.queryParameters}');
    log('━━━━━━━━━━━━━━━━━━━');

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    // Token expired
    if (statusCode == 401 || statusCode == 403) {
      try {
        final newToken = await guard.refresh();

        final requestOptions = err.requestOptions;

        requestOptions.headers['Authorization'] =
            'Bearer $newToken';

        final response = await dio.fetch(
          requestOptions,
        );

        return handler.resolve(response);
      } catch (_) {
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}

// ─────────────────────────────────────────────────────────────
// API CLIENT
// ─────────────────────────────────────────────────────────────

class ApiClient {
  ApiClient._() {
    dio.interceptors.add(
      _AuthInterceptor(
        dio: dio,
        guard: _guard,
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
      ),
    );
  }

  static final ApiClient instance =
      ApiClient._();

  final _guard = _TokenRefreshGuard();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: EndPoints.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // ───────────────── GET ─────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParams,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ───────────────── POST ─────────────────

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParams,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ───────────────── PATCH ─────────────────

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      return await dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParams,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ───────────────── DELETE ─────────────────

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParams,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ───────────────── Typed helpers ─────────────────
  // Unwraps the standard { success, data: T } envelope and deserialises to a model.

  Future<T> fetchModel<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParams,
  }) async {
    final res = await get<Map<String, dynamic>>(path, queryParams: queryParams);
    final raw = res.data ?? {};
    final inner = raw['data'];
    final payload = inner is Map<String, dynamic> ? inner : raw;
    return fromJson(payload);
  }

  Future<List<T>> fetchList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParams,
  }) async {
    final res = await get<Map<String, dynamic>>(path, queryParams: queryParams);
    final raw = res.data ?? {};
    final list = raw['data'] as List? ?? [];
    return list.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}

// ─────────────────────────────────────────────────────────────
// Multipart Client
// ─────────────────────────────────────────────────────────────

class MultiPartClient extends http.BaseClient {
  MultiPartClient();

  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(
    http.BaseRequest request,
  ) {
    request.headers['Accept'] =
        'application/json';

    log(
      '[MULTIPART] ${request.method} ${request.url}',
    );

    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}