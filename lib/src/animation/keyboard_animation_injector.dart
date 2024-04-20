import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:keyboard_attachable/src/animation/keyboard_animation_controller.dart';
import 'package:keyboard_attachable/src/animation/platform_controllers/android_keyboard_animation_controller.dart';
import 'package:keyboard_attachable/src/animation/platform_controllers/ios_keyboard_animation_controller.dart';
import 'package:universal_platform/universal_platform.dart';

class KeyboardAnimationInjector {
  const KeyboardAnimationInjector(this._tickerProvider);

  final TickerProvider _tickerProvider;

  

  KeyboardAnimationController getPlatformController() {
    // bool isIos = UniversalPlatform.isIOS;
    if (UniversalPlatform.isAndroid) {
      return AndroidKeyboardAnimationController(vsync: _tickerProvider);
    } else {
      return IOSKeyboardAnimationController(vsync: _tickerProvider);
    }
  }
}
