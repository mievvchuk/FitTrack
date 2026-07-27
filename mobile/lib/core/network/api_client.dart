import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../errors/app_exception.dart';

typedef TokenReader = Future<String?> Function();

class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenReader tokenReader,
    bool requireHttps = false,
  })  : assert(
          !requireHttps || baseUrl.startsWith('https://'),
          'Production API_BASE_URL must use HTTPS.',
        ),
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
            contentType: Headers.jsonContentType,
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenReader();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(() {
      return _dio.get(path, queryParameters: queryParameters);
    });
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(() {
      return _dio.post(path, data: data, queryParameters: queryParameters);
    });
  }

  Future<Response<dynamic>> put(String path, {Object? data}) {
    return _request(() => _dio.put(path, data: data));
  }

  Future<Response<dynamic>> patch(String path, {Object? data}) {
    return _request(() => _dio.patch(path, data: data));
  }

  Future<Response<dynamic>> delete(String path) {
    return _request(() => _dio.delete(path));
  }

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      final responseData = error.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['detail']?.toString()
          : null;

      throw AppException(
        message ?? error.message ?? 'Помилка мережевого запиту',
        code: error.response?.statusCode.toString(),
      );
    }
  }
}
