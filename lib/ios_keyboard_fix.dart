import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

class IOSKeyboardFix {
  static bool _isInitialized = false;

  static void initialize() {
    if (!kIsWeb || _isInitialized) return;

    _isInitialized = true;

    // Force iOS PWA keyboard fixes
    _addIOSKeyboardListeners();
    _addViewportFixes();
    _addInputFocusFixes();
  }

  static void _addIOSKeyboardListeners() {
    // Add meta tag for iOS keyboard
    final meta = html.document.createElement('meta');
    meta.setAttribute('name', 'format-detection');
    meta.setAttribute('content', 'telephone=no');
    html.document.head?.append(meta);

    // Force iOS to show keyboard
    html.document.addEventListener('focusin', (event) {
      final target = event.target;
      if (target is html.InputElement || target is html.TextAreaElement) {
        _forceIOSKeyboard(target);
      }
    });
  }

  static void _forceIOSKeyboard(dynamic input) {
    // Create temporary input to force keyboard
    final tempInput = html.InputElement();
    tempInput.style.position = 'absolute';
    tempInput.style.top = '-1000px';
    tempInput.style.left = '-1000px';
    tempInput.style.opacity = '0';
    tempInput.style.height = '0';
    tempInput.style.fontSize = '16px'; // Prevent zoom

    html.document.body?.append(tempInput);

    // Focus sequence to force keyboard
    tempInput.focus();

    Future.delayed(const Duration(milliseconds: 50), () {
      if (input.runtimeType.toString().contains('Input') ||
          input.runtimeType.toString().contains('TextArea')) {
        input.focus();
      }
      tempInput.remove();
    });
  }

  static void _addViewportFixes() {
    // Add viewport meta for iOS
    var viewport = html.document.querySelector('meta[name="viewport"]');
    if (viewport != null) {
      viewport.setAttribute('content',
          'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover');
    }

    // Prevent zoom on input focus
    final style = html.document.createElement('style');
    style.text = '''
      input, textarea, select {
        font-size: 16px !important;
        transform: translateZ(0);
        -webkit-appearance: none;
        border-radius: 0;
      }
      
      input:focus, textarea:focus {
        font-size: 16px !important;
        zoom: 1;
      }
      
      .ios-input-fix {
        -webkit-user-select: text !important;
        -webkit-touch-callout: default !important;
      }
    ''';
    html.document.head?.append(style);
  }

  static void _addInputFocusFixes() {
    // Listen for keyboard events
    html.window.addEventListener('resize', (event) {
      final height = html.window.innerHeight;
      final width = html.window.innerWidth;

      // If height significantly reduced, keyboard is probably open
      if (height != null && width != null) {
        final isKeyboardOpen = height < (width * 0.75);
        _handleKeyboardState(isKeyboardOpen);
      }
    });
  }

  static void _handleKeyboardState(bool isOpen) {
    if (isOpen) {
      // Keyboard is open - adjust viewport
      html.document.body?.style.height = 'auto';
      html.document.documentElement?.style.height = 'auto';
    } else {
      // Keyboard is closed - restore viewport
      html.document.body?.style.height = '100vh';
      html.document.documentElement?.style.height = '100vh';
    }
  }

  // Helper method to fix input field
  static void fixInputField(String elementId) {
    if (!kIsWeb) return;

    final element = html.document.getElementById(elementId);
    if (element != null) {
      element.classes.add('ios-input-fix');

      // Add touch events for iOS
      element.addEventListener('touchstart', (event) {
        event.preventDefault();
        if (element is html.InputElement) {
          element.focus();
        }
      });
    }
  }
}

// Custom TextField widget with iOS fixes
class IOSFixedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextStyle? style;
  final InputDecoration? decoration;
  final bool autofocus;
  final int? maxLines;
  final TextCapitalization textCapitalization;

  const IOSFixedTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.style,
    this.decoration,
    this.autofocus = false,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  @override
  State<IOSFixedTextField> createState() => _IOSFixedTextFieldState();
}

class _IOSFixedTextFieldState extends State<IOSFixedTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    if (kIsWeb) {
      _focusNode.addListener(() {
        if (_focusNode.hasFocus) {
          _triggerIOSKeyboard();
        }
      });
    }
  }

  void _triggerIOSKeyboard() {
    if (!kIsWeb) return;

    // Force iOS to show keyboard
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _focusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: widget.style,
      autofocus: widget.autofocus,
      maxLines: widget.maxLines,
      textCapitalization: widget.textCapitalization,
      decoration: widget.decoration ??
          InputDecoration(
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
          ),
    );
  }
}
