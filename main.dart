import 'dart:convert';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:replit_db/replit_db.dart';

void main() async {
  // Conectando ao banco de dados do Replit
  final db = await ReplitDBClient.connect();

  // Configurando os endpoints
  final app = shelf.Router()
    ..get('/user/infos', (shelf.Request request) async {
      final user = await _getUser(request.headers['authorization'], db);
      if (user == null) {
        return shelf.Response.notFound('Usuário não encontrado');
      }
      final responseJson = {
        'nome': user['nome'],
        'email': user['email'],
        'saldo': user['saldo'],
      };
      return shelf.Response.ok(jsonEncode(responseJson));
    })
    ..post('/login', (shelf.Request request) async {
      final requestBody = await request.readAsString();
      final bodyJson = jsonDecode(requestBody);
      final email = bodyJson['email'];
      final senha = bodyJson['senha'];
      final user = await _getUserByEmail(email, db);
      if (user == null || user['senha'] != senha) {
        return shelf.Response.forbidden('Credenciais inválidas');
      }
      final token = _generateToken(user['id']);
      final responseJson = {'token': token};
      return shelf.Response.ok(jsonEncode(responseJson));
    })
    ..post('/register', (shelf.Request request) async {
      final requestBody = await request.readAsString();
      final bodyJson = jsonDecode(requestBody);
      final email = bodyJson['email'];
      final user = await _getUserByEmail(email, db);
      if (user != null) {
        return shelf.Response.conflict('Email já cadastrado');
      }
      final newUser = {
        'id': _generateUserId(),
        'nome': bodyJson['nome'],
        'email': email,
        'senha': bodyJson['senha'],
        'saldo': 0,
      };
      await db.set(newUser['id'], jsonEncode(newUser));
      final token = _generateToken(newUser['id']);
      final responseJson = {'token': token};
      return shelf.Response.ok(jsonEncode(responseJson));
    });

  // Iniciando o servidor
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(app, '0.0.0.0', port);
  print('Servidor rodando na porta ${server.port}');
}

// Função para obter o usuário autenticado a partir do token
Future<Map<String, dynamic>?> _getUser(String? authorizationHeader, ReplitDBClient db) async {
  if (authorizationHeader == null) {
    return null;
  }
  final token = authorizationHeader.replaceAll('Bearer ', '');
  final id = _parseUserIdFromToken(token);
  if (id == null) {
    return null;
  }
  final userJson = await db.get(id);
  if (userJson == null) {
    return null;
  }
  final user = jsonDecode(userJson);
  return user;
}
// Função para obter o usuário pelo email
Future<Map<String, dynamic>?> _getUserByEmail(String email, ReplitDBClient db) async {
  final allUsers = await db.list();
  final user = allUsers.values
      .map((userJson) => jsonDecode(userJson))
      .firstWhere((user) => user['email'] == email, orElse: () => null);
  return user;
}

// Função para gerar um token de autenticação
String _generateToken(String userId) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final tokenData = '$userId|$timestamp';
  final bytes = utf8.encode(tokenData);
  final base64 = base64Url.encode(bytes);
  return base64;
}

// Função para extrair o ID do usuário a partir do token
String? _parseUserIdFromToken(String token) {
  try {
    final bytes = base64Url.decode(token);
    final tokenData = utf8.decode(bytes);
    final parts = tokenData.split('|');
    if (parts.length != 2) {
      return null;
    }
    return parts[0];
  } catch (e) {
    return null;
  }
}

// Função para gerar um ID único para o usuário
String _generateUserId() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = Random().nextInt(10000);
  final id = '$timestamp$random';
  return id;
}

