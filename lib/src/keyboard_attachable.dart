import 'dart:async';

import 'package:flutter/material.dart';
import 'package:keyboard_attachable/keyboard_attachable.dart';
import 'package:keyboard_attachable/src/animation/keyboard_animation_controller.dart';
import 'package:keyboard_attachable/src/animation/keyboard_animation_injector.dart';
import 'package:keyboard_attachable/src/data/keyboard_animation_data.dart';
import 'package:keyboard_attachable/src/visibility/default_keyboard_visibility_controller.dart';
import 'package:keyboard_attachable/src/visibility/keyboard_visibility_controller.dart';

/// Signature for builders used in custom transitions for KeyboardAttachable.
///
/// The function should return a widget which wraps the given [child].
/// It may also use the animation to inform its transition.
typedef KeyboardTransitionBuilder = Widget Function(
  Widget child,
  Animation<double> animation,
  double keyboardHeight,
);

/// A widget that adds space below its baseline when the soft keyboard is shown
/// and hidden with an animation that matches that of the platform keyboard.
///
/// This widget can be used to animate its child when the soft keyboard is shown
/// or hidden, so that the child widget appears to be attached to the keyboard.
///
/// Even if no child widget is passed to [KeyboardAttachable], it can still be
/// used to animate the shrinkage and expansion of the layout when the keyboard
/// is shown an hidden, respectively. In order for this to work, this widget
/// has to be attached to the bottom of the page, for example, by using a
/// [FooterLayout], and the [Scaffold.resizeToAvoidBottomInset] parameter of
/// the [Scaffold] above the page has to be set to false.
///
/// In addition to that, when there are [SafeArea]s involved the layout, it is
/// recommended to set their [SafeArea.maintainBottomViewPadding] property to
/// true in order for the animations to run smoothly.
class KeyboardAttachable extends StatefulWidget {
  /// Creates a widget that smoothly adds space below its child when the
  /// keyboard is shown or hidden.
  const KeyboardAttachable({
    super.key,
    this.child,
    this.transitionBuilder = KeyboardAttachable._defaultBuilder,
    this.backgroundColor = Colors.transparent,
  });

  /// The color that fills the space that is added when the keyboard appears.
  ///
  /// Defaults to [Colors.transparent].
  final Color backgroundColor;

  /// A function that wraps a new child with an animation that makes the
  /// keyboard appear when the animation runs in the forward direction and hide
  /// when the animation runs in the reverse direction.
  ///
  /// This is only called when the keyboard changes its status from hidden to
  /// shown.
  ///
  /// Defaults to [KeyboardAttachable._defaultBuilder], which simply returns
  /// the child that was passed to [KeyboardAttachable].
  ///
  /// The animation provided to the builder has the duration and curve needed
  /// to make the keyboard animation match the corresponding platform animation.
  /// The animation value will be 0 if the keyboard is dismissed, and 1 if the
  /// keyboard is fully shown.
  ///
  /// See also:
  ///
  /// * [KeyboardTransitionBuilder] for more information about how a transition
  /// builder should function.
  final KeyboardTransitionBuilder transitionBuilder;

  /// The widget to be placed above the space that this widget can insert.
  final Widget? child;

  @override
  _KeyboardAttachableState createState() => _KeyboardAttachableState();

  static Widget _defaultBuilder(
    Widget child,
    Animation<double> animation,
    double keyboardHeight,
  ) =>
      child;
}

class _KeyboardAttachableState extends State<KeyboardAttachable>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final KeyboardVisibilityController _keyboardVisibility;

  late final KeyboardAnimationController _controller;
  late final StreamSubscription<bool> _visibilitySubscription;

  late final GlobalKey _keyboardAttachableKey;
  late final ValueNotifier<KeyboardAnimationData>
      _keyboardAnimationDataNotifier;

  @override
  void initState() {
    super.initState();
    _keyboardAttachableKey = GlobalKey();
    _keyboardVisibility = const DefaultKeyboardVisibilityController();
    _controller = KeyboardAnimationInjector(this).getPlatformController();
    _keyboardAnimationDataNotifier = ValueNotifier(
      const KeyboardAnimationData(),
    );
    _visibilitySubscription = _keyboardVisibility.onChange.listen(_animate);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<KeyboardAnimationData>(
          valueListenable: _keyboardAnimationDataNotifier,
          builder: (_, keyboardAnimatinoData, __) {
            final offsetAnimation = CurvedAnimation(
              parent: _controller.animation,
              curve: Interval(keyboardAnimatinoData.animationBegin, 1),
            );
            final child = widget.child;
            return Column(
              key: _keyboardAttachableKey,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (child != null)
                  widget.transitionBuilder(
                    child,
                    offsetAnimation,
                    keyboardAnimatinoData.bottomInset,
                  ),
                SizeTransition(
                  sizeFactor: offsetAnimation,
                  child: Container(
                    height: keyboardAnimatinoData.bottomInset,
                    color: widget.backgroundColor,
                  ),
                ),
              ],
            );
          });

  @override
  void didChangeMetrics() {
    final mediaQuery = MediaQueryData.fromView(View.of(context));
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final keyboardAttachableBounds = _globalBounds(key: _keyboardAttachableKey);
    final bottomOffset = screenHeight - keyboardAttachableBounds.bottom;
    final bottomInset =
        (keyboardHeight - bottomOffset).clamp(0, keyboardHeight).toDouble();
    final isKeyboardDismissed = keyboardHeight == 0;
    final animationBegin = keyboardHeight != 0
        ? (1 - bottomInset / keyboardHeight).toDouble()
        : 0.0;
    if (bottomInset > 0) {
      _keyboardAnimationDataNotifier.value = KeyboardAnimationData(
        animationBegin: isKeyboardDismissed ? 0 : animationBegin,
        bottomInset: bottomInset,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _keyboardAnimationDataNotifier.dispose();
    _visibilitySubscription.cancel();
    super.dispose();
  }

  void _animate(bool isKeyboardVisible) =>
      isKeyboardVisible ? _controller.forward() : _controller.reverse();

  Rect _globalBounds({required GlobalKey key}) {
    final renderObject = key.currentContext?.findRenderObject();
    var translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject != null) {
      final offset = Offset(translation.x, translation.y);
      return renderObject.paintBounds.shift(offset);
    } else {
      return Rect.zero;
    }
  }
}