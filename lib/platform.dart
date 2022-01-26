import 'package:flutter/services.dart';

typedef _Listener = void Function(MethodCall call);

const platformMethodChannel = MethodChannel('ws.diye/repeater');

final List<_Listener> _listeners = [];

registerPlatformListener(_Listener x) {
  _listeners.add(x);
}

setupPlatformMethodChannel() {
  platformMethodChannel.setMethodCallHandler((call) async {
    for (var element in _listeners) {
      element(call);
    }
  });
}
