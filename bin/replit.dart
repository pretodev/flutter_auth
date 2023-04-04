import 'package:dio/dio.dart';

class ReplitDBClient {
  final _dio = Dio(BaseOptions(
    baseUrl: String.fromEnvironment('REPLIT_DB_URL'),
  ));

  // Retorna o valor armazenado pela chave especificada
  Future<String?> get(String key) async {
    try {
      final response = await _dio.get('/$key');
      return response.data['value'];
    } on DioError catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  // Armazena o valor fornecido pela chave especificada
  Future<void> set(String key, String value) async {
    await _dio.post('/', data: {'key': key, 'value': value});
  }

  // Exclui o valor armazenado pela chave especificada
  Future<void> delete(String key) async {
    await _dio.delete('/$key');
  }
}
