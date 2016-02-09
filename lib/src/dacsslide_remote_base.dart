// Copyright (c) 2016, Valentyn Shybanov. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library dacsslide_remote.base;

import 'package:angular/angular.dart';
import 'dart:html';
import 'dart:async';
import 'package:dacsslide/presentation.dart' as DCSSLide;

@Component(
    selector:'remote-controller',
    template: '<div class="controller" ng-show="RemoteServerUrl!=\'\'">'
                '<div ng-show="!connected">Connecting...</div>'
                '<div ng-show="connected">'
                  '<div ng-hide="controlled"><button ng-click="control()">Take Control</button></div>'
                  '<div ng-show="controlled"><button ng-click="releaseControl()">Release Control</button></div>'
                '</div>'
              "</div>",
    cssUrl: 'packages/dacsslide_remote/dacsslide_remote.css'

)
class RemoteController implements AttachAware {

  DCSSLide.PresentationService presentationSvc;
  DCSSLide.Presentation presentation;

  RemoteController(this.presentationSvc,this.presentation);

  @NgAttr('url') String RemoteServerUrl;

  bool controlled = false;
  bool connected = false;

  WebSocket ws;

  void initWebSocket([int retrySeconds = 2]) {
    var reconnectScheduled = false;

    print("Connecting to websocket at $RemoteServerUrl");
    ws = new WebSocket(RemoteServerUrl);

    void scheduleReconnect() {
      if (!reconnectScheduled) {
        new Timer(new Duration(milliseconds: 1000 * retrySeconds), () => initWebSocket(retrySeconds * 2));
      }
      reconnectScheduled = true;
    }

    ws.onOpen.listen((e) {
      print('Connected');
      connected = true;
      ws.send('get');
    });

    ws.onClose.listen((e) {
      print('Websocket closed, retrying in $retrySeconds seconds');
      connected = false;
      scheduleReconnect();
    });

    ws.onError.listen((e) {
      connected = false;
      print("Error connecting to ws");
      scheduleReconnect();
    });

    ws.onMessage.listen((MessageEvent e) {
      String message = e.data;
      if (message.startsWith('set')) {
        var slideStr = message.split(' ')[1];
        print("Settng to $slideStr");
        presentation.setSlide(int.parse(slideStr));
      } else
        print('Received message: ${e.data}');
    });
  }

  @override
  void attach() {
    if (RemoteServerUrl==null)
      RemoteServerUrl = _getUrlFromHash(window.location.hash);
      if (RemoteServerUrl=="") return;
      initWebSocket();
      presentationSvc.onSlide.stream.listen((slide) {
        if (connected && controlled) ws.send("set $slide");
      });

  }

  String _getUrlFromHash(String hash) {
    return hash.split('&').firstWhere((p) => p.startsWith('remote='),orElse: () => 'remote=').split('=')[1];
  }

  void control() {
    ws.send("set ${presentation.current}");
    controlled = true;
  }
  void releaseControl() {
    controlled = false;
  }

}

class RemoteControllerModule extends Module {
  RemoteControllerModule() {
    bind(RemoteController);
  }
}