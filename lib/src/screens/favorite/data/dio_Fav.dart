import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/error_translator.dart';

class DioFav {
  final Dio dio;
  static DioFav? _instance;

  factory DioFav([Dio? customDio]) {
    _instance ??= DioFav._internal(
      customDio ?? Dio()..options.baseUrl = 'https://api.mohamed-ramadan.me/api',
    );
    return _instance!;
  }

  DioFav._internal(this.dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: 'يرجى تسجيل الدخول مرة أخرى',
              ),
            );
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<List<dynamic>> getFavorites(String token) async {
    try {
      final response = await dio.get('/favorite');
      
      if (response.data == null) {
        throw Exception('لا يوجد بيانات');
      }

      final List<dynamic> favorites = response.data['favorites'] ?? [];
      final List<dynamic> books = favorites.map((e) => e['book']).toList();
      return books;
    } catch (e) {
      throw Exception(ErrorTranslator.handleDioError(e));
    }
  }

  Future<void> addToFavorite(String token, String bookId) async {
    try {
      await dio.post(
        '/favorite',
        data: {"bookId": bookId},
      );
    } catch (e) {
      throw Exception(ErrorTranslator.handleDioError(e));
    }
  }

  Future<void> removeFromFavorite(String token, String bookId) async {
    try {
      await dio.delete(
        '/favorite',
        data: {"bookId": bookId},
      );
    } catch (e) {
      throw Exception(ErrorTranslator.handleDioError(e));
    }
  }
}
