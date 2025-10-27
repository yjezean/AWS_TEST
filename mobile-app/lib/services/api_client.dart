import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'token_storage.dart';

class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  ApiClient({Dio? dio, TokenStorage? tokenStorage})
      : _dio = dio ??
            Dio(BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: ApiConfig.timeout,
                receiveTimeout: ApiConfig.timeout)),
        _tokenStorage = tokenStorage ?? TokenStorage() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        handler.next(e);
      },
    ));
  }

  Future<Response<T>> get<T>(String path,
          {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);
  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post(path, data: data);
  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put(path, data: data);
  Future<Response<T>> delete<T>(String path, {dynamic data}) =>
      _dio.delete(path, data: data);
}
