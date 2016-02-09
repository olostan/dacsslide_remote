import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

void main() {
  var current = 0;
  var sockets = new List();

  var handler = webSocketHandler((webSocket) async {
    sockets.add(webSocket);
    var controller = false;
    await for (String message in webSocket) {
      if (message=='get') {
        webSocket.add("set $current");
      } else if (message.startsWith('set')) {
        print("Recieved command '$message'");
        current = int.parse(message.split(' ')[1]);
        sockets.forEach((ws) { if (ws!=webSocket) ws.add("set $current");});
      } else
        webSocket.add("echo $message");
    }
    sockets.remove(webSocket);
  });

  shelf_io.serve(handler, 'localhost', 8080).then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });
}