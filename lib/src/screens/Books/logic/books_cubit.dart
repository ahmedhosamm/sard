import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sard/src/screens/Books/data/dio_client.dart';
import 'package:sard/src/screens/Books/book_model.dart';
import 'books_state.dart';

class BooksCubit extends Cubit<BooksState> {
  BooksCubit() : super(BooksInitial());

  Future<void> fetchBooks() async {
    try {
      emit(BooksLoading());

      // استخدام endpoint للطلبات حيث تخزن معلومات الكتب
      final response = await DioClient.dio.get('/orders/');

      if (response.statusCode == 200) {
        // تحقق من نوع البيانات وتعامل معها بشكل مناسب
        dynamic responseData = response.data;
        List<dynamic> booksJson = [];

        if (responseData is Map<String, dynamic> && responseData['data'] is List) {
          booksJson = responseData['data'] as List<dynamic>;
        } else if (responseData is List) {
          booksJson = responseData;
        }

        final books = booksJson
            .where((json) => json is Map<String, dynamic> && json['book'] != null)
            .map((json) => Book.fromJson(json['book'] as Map<String, dynamic>))
            .toList();
        emit(BooksLoaded(books));
      } else {
        emit(const BooksError('فشل تحميل الكتب'));
      }
    } catch (e) {
      emit(BooksError('حدث خطأ: ${e.toString()}'));
    }
  }
}