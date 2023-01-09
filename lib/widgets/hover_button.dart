// original file: https://github.com/bdlukaa/fluent_ui/blob/f61c8232d87e33e3b97236da9bd16ceb88a18b09/lib/src/controls/utils/hover_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef ButtonStateWidgetBuilder = Widget Function(
  BuildContext,
  Set<ButtonStates> state,
);

/// Base widget for any widget that requires input. It
/// provides a [builder] callback to build the child with
/// the current input state: none, hovering, pressing or
/// focused.
class HoverButton extends StatefulWidget {
  /// Creates a hover button.
  const HoverButton({
    Key? key,
    required this.builder,
    this.cursor,
    this.onPressed,
    this.onLongPress,
    this.focusNode,
    this.margin,
    this.semanticLabel,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onLongPressEnd,
    this.onLongPressStart,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onFocusChange,
    this.autofocus = false,
    this.actionsEnabled = true,
    this.customActions,
    this.shortcuts,
    this.focusEnabled = true,
  }) : super(key: key);

  /// {@template fluent_ui.controls.inputs.HoverButton.mouseCursor}
  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// The [mouseCursor] defaults to [MouseCursor.defer], deferring the choice of
  /// cursor to the next region behind it in hit-test order.
  /// {@endtemplate}
  final MouseCursor? cursor;
  final VoidCallback? onLongPress;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  final VoidCallback? onPressed;
  final VoidCallback? onTapUp;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapCancel;

  final GestureDragStartCallback? onHorizontalDragStart;
  final GestureDragUpdateCallback? onHorizontalDragUpdate;
  final GestureDragEndCallback? onHorizontalDragEnd;

  final ButtonStateWidgetBuilder builder;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// The margin created around this button. The margin is added
  /// around the [Semantics] widget, if any.
  final EdgeInsetsGeometry? margin;

  /// {@template fluent_ui.controls.inputs.HoverButton.semanticLabel}
  /// Semantic label for the input.
  ///
  /// Announced in accessibility modes (e.g TalkBack/VoiceOver).
  /// This label does not show in the UI.
  ///
  ///  * [SemanticsProperties.label], which is set to [semanticLabel] in the
  ///    underlying	 [Semantics] widget.
  ///
  /// If null, no [Semantics] widget is added to the tree
  /// {@endtemplate}
  final String? semanticLabel;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  final ValueChanged<bool>? onFocusChange;

  /// Whether actions are enabled
  ///
  /// Default actions:
  ///  * Execute [onPressed] with Enter
  ///
  /// See also:
  ///  * [customActions], which lets you execute custom actions
  final bool actionsEnabled;

  /// Custom actions that will be executed around the subtree of this widget.
  ///
  /// See also:
  ///
  ///  * [actionsEnabled], which controls if actions are enabled or not
  final Map<Type, Action<Intent>>? customActions;

  /// {@macro flutter.widgets.shortcuts.shortcuts}
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// Whether the focusing is enabled.
  ///
  /// If false, actions and shortcurts will not work, regardless of what is
  /// set on [actionsEnabled].
  final bool focusEnabled;

  @override
  _HoverButtonState createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  late FocusNode node;

  late Map<Type, Action<Intent>> _actionMap;
  late Map<Type, Action<Intent>> defaultActions;

  @override
  void initState() {
    super.initState();
    node = widget.focusNode ?? _createFocusNode();
    void handleActionTap() async {
      if (!enabled) return;
      setState(() => _pressing = true);
      widget.onPressed?.call();
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) setState(() => _pressing = false);
    }

    defaultActions = {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (ActivateIntent intent) => handleActionTap(),
      ),
      ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
        onInvoke: (ButtonActivateIntent intent) => handleActionTap(),
      ),
    };

    _actionMap = <Type, Action<Intent>>{
      ...defaultActions,
      if (widget.customActions != null) ...widget.customActions!,
    };
  }

  @override
  void didUpdateWidget(HoverButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      node = widget.focusNode ?? node;
    }

    if (widget.customActions != oldWidget.customActions) {
      _actionMap = <Type, Action<Intent>>{
        ...defaultActions,
        if (widget.customActions != null) ...widget.customActions!,
      };
    }
  }

  FocusNode _createFocusNode() {
    return FocusNode(debugLabel: '${widget.runtimeType}');
  }

  @override
  void dispose() {
    if (widget.focusNode == null) node.dispose();
    super.dispose();
  }

  bool _hovering = false;
  bool _pressing = false;
  bool _shouldShowFocus = false;

  bool get enabled =>
      widget.onPressed != null ||
      widget.onTapUp != null ||
      widget.onTapDown != null ||
      widget.onTapDown != null ||
      widget.onLongPress != null ||
      widget.onLongPressStart != null ||
      widget.onLongPressEnd != null;

  Set<ButtonStates> get states {
    if (!enabled) return {ButtonStates.disabled};
    return {
      if (_pressing) ButtonStates.pressing,
      if (_hovering) ButtonStates.hovering,
      if (_shouldShowFocus) ButtonStates.focused,
    };
  }

  @override
  Widget build(BuildContext context) {
    Widget w = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? widget.onPressed : null,
      onTapDown: (_) {
        if (!enabled) return;
        if (mounted) setState(() => _pressing = true);
        widget.onTapDown?.call();
      },
      onTapUp: (_) async {
        if (!enabled) return;
        widget.onTapUp?.call();
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() => _pressing = false);
      },
      onTapCancel: () {
        if (!enabled) return;
        widget.onTapCancel?.call();
        if (mounted) setState(() => _pressing = false);
      },
      onLongPress: enabled ? widget.onLongPress : null,
      onLongPressStart: (_) {
        if (!enabled) return;
        widget.onLongPressStart?.call();
        if (mounted) setState(() => _pressing = true);
      },
      onLongPressEnd: (_) {
        if (!enabled) return;
        widget.onLongPressEnd?.call();
        if (mounted) setState(() => _pressing = false);
      },
      onHorizontalDragStart: widget.onHorizontalDragStart,
      onHorizontalDragUpdate: widget.onHorizontalDragUpdate,
      onHorizontalDragEnd: widget.onHorizontalDragEnd,
      child: widget.builder(context, states),
    );
    if (widget.focusEnabled) {
      w = FocusableActionDetector(
        mouseCursor: widget.cursor ?? MouseCursor.defer,
        focusNode: node,
        autofocus: widget.autofocus,
        enabled: enabled,
        shortcuts: widget.shortcuts,
        actions: widget.actionsEnabled ? _actionMap : {},
        onFocusChange: widget.onFocusChange,
        onShowFocusHighlight: (v) {
          if (mounted) setState(() => _shouldShowFocus = v);
        },
        onShowHoverHighlight: (v) {
          if (mounted) setState(() => _hovering = v);
        },
        child: w,
      );
    } else {
      w = MouseRegion(
        cursor: widget.cursor ?? MouseCursor.defer,
        opaque: true,
        onEnter: (e) {
          if (mounted) setState(() => _hovering = true);
        },
        onExit: (e) {
          if (mounted) setState(() => _hovering = false);
        },
        child: w,
      );
    }
    w = MergeSemantics(
      child: Semantics(
        label: widget.semanticLabel,
        button: true,
        enabled: enabled,
        focusable: enabled && node.canRequestFocus,
        focused: node.hasFocus,
        child: w,
      ),
    );
    if (widget.margin != null) w = Padding(padding: widget.margin!, child: w);
    return w;
  }
}

enum ButtonStates { disabled, hovering, pressing, focused, none }

// typedef ButtonState<T> = T Function(Set<ButtonStates>);

/// Signature for the function that returns a value of type `T` based on a given
/// set of states.
typedef ButtonStateResolver<T> = T Function(Set<ButtonStates> states);

abstract class ButtonState<T> {
  T resolve(Set<ButtonStates> states);

  static ButtonState<T> all<T>(T value) => _AllButtonState(value);

  static ButtonState<T> resolveWith<T>(ButtonStateResolver<T> callback) {
    return _ButtonState(callback);
  }

  static ButtonState<T?>? lerp<T>(
    ButtonState<T?>? a,
    ButtonState<T?>? b,
    double t,
    T? Function(T?, T?, double) lerpFunction,
  ) {
    if (a == null && b == null) return null;
    return _LerpProperties<T>(a, b, t, lerpFunction);
  }
}

class _ButtonState<T> extends ButtonState<T> {
  _ButtonState(this._resolve);

  final ButtonStateResolver<T> _resolve;

  @override
  T resolve(Set<ButtonStates> states) => _resolve(states);
}

class _AllButtonState<T> extends ButtonState<T> {
  _AllButtonState(this._value);

  final T _value;

  @override
  T resolve(states) => _value;
}

class _LerpProperties<T> implements ButtonState<T?> {
  const _LerpProperties(this.a, this.b, this.t, this.lerpFunction);

  final ButtonState<T?>? a;
  final ButtonState<T?>? b;
  final double t;
  final T? Function(T?, T?, double) lerpFunction;

  @override
  T? resolve(Set<ButtonStates> states) {
    final T? resolvedA = a?.resolve(states);
    final T? resolvedB = b?.resolve(states);
    return lerpFunction(resolvedA, resolvedB, t);
  }
}

extension ButtonStatesExtension on Set<ButtonStates> {
  bool get isFocused => contains(ButtonStates.focused);
  bool get isDisabled => contains(ButtonStates.disabled);
  bool get isPressing => contains(ButtonStates.pressing);
  bool get isHovering => contains(ButtonStates.hovering);
  bool get isNone => isEmpty;
}