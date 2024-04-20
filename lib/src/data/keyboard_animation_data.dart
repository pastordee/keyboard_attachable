import 'package:flutter/material.dart';

@immutable
class KeyboardAnimationData {
  const KeyboardAnimationData({
    this.bottomInset = 0,
    this.animationBegin = 0,
  });

  final double bottomInset;
  final double animationBegin;

  KeyboardAnimationData copyWith({
    double? bottomInset,
    double? animationBegin,
  }) =>
      KeyboardAnimationData(
        bottomInset: bottomInset ?? this.bottomInset,
        animationBegin: animationBegin ?? this.animationBegin,
      );
}