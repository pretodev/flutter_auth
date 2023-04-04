import 'dart:io';

Future main() async {
  print(String.fromEnvironment("REPLIT_DB_URL"));

  var server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('Listening on ${server.address}:${server.port}');

  await for (HttpRequest request in server) {
    request.response.write('Hello, World!');
    await request.response.close();
  }
}
