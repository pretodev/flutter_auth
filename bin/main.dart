import 'dart:io';

import 'replit.dart';

Future main() async {
  final name = await ReplitDBClient.get('name');
  print(name);
  var server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('Listening on ${server.address}:${server.port}');

  await for (HttpRequest request in server) {
    request.response.write('Hello, World!');
    await request.response.close();
  }
}
