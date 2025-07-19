import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

class IOSKeyboardFix {
  static bool _isInitialized = false;
  static bool _isProcessing = false; // Prevent recursion

  static void initialize() {
    if (!kIsWeb || _isInitialized) return;

    _isInitialized = true;

    // Add simple iOS viewport fix
    _addViewportFixes();
    _addSimpleKeyboardFix();
  }

  static void _addViewportFixes() {
    try {
      // Add/update viewport meta tag
      var viewport = html.document.querySelector('meta[name="viewport"]');
      if (viewport != null) {
        viewport.setAttribute('content',
            'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover');
      }

      // Add CSS for iOS input fix
      final style = html.document.createElement('style');
      style.text = '''
        /* iOS Input Fixes */
        input, textarea, select {
          font-size: 16px !important;
          -webkit-appearance: none;
          border-radius: 0;
          transform: translateZ(0);
        }
        
        input:focus, textarea:focus {
          font-size: 16px !important;
          zoom: 1;
          outline: none;
        }
        
        /* Prevent zoom on input focus */
        @media screen and (-webkit-min-device-pixel-ratio: 0) {
          input, textarea, select {
            font-size: 16px !important;
          }
        }
        
        /* iOS PWA fixes */
        body {
          -webkit-touch-callout: none;
          -webkit-user-select: none;
          -webkit-tap-highlight-color: transparent;
        }
        
        /* Keyboard handling */
        .keyboard-open {
          height: auto !important;
          min-height: auto !important;
        }
      ''';
      html.document.head?.append(style);

      print('✅ iOS viewport and CSS fixes applied');
    } catch (e) {
      print('❌ Error applying viewport fixes: $e');
    }
  }

  static void _addSimpleKeyboardFix() {
    try {
      // Simple focus event listener - NO RECURSION
      html.document.addEventListener('focusin', (event) {
        if (_isProcessing) return; // Prevent recursion

        final target = event.target;
        if (target is html.InputElement || target is html.TextAreaElement) {
          _isProcessing = true;

          // Simple delay to ensure keyboard appears
          Future.delayed(const Duration(milliseconds: 100), () {
            _isProcessing = false;
          });

          // Add keyboard-open class to body
          html.document.body?.classes.add('keyboard-open');
        }
      });

      html.document.addEventListener('focusout', (event) {
        // Remove keyboard-open class
        html.document.body?.classes.remove('keyboard-open');
      });

      // Simple window resize handler
      html.window.addEventListener('resize', (event) {
        if (_isProcessing) return;

        final height = html.window.innerHeight;
        final width = html.window.innerWidth;

        if (height != null && width != null) {
          final isKeyboardOpen = height < (width * 0.75);

          if (isKeyboardOpen) {
            html.document.body?.classes.add('keyboard-open');
          } else {
            html.document.body?.classes.remove('keyboard-open');
          }
        }
      });

      print('✅ Simple iOS keyboard fix applied');
    } catch (e) {
      print('❌ Error applying keyboard fix: $e');
    }
  }

  // Simplified helper method - NO RECURSION
  static void fixInputField(String elementId) {
    if (!kIsWeb || _isProcessing) return;

    try {
      final element = html.document.getElementById(elementId);
      if (element != null) {
        // Just add a simple CSS class
        element.classes.add('ios-input-fix');

        // Simple focus handler
        element.addEventListener('touchstart', (event) {
          if (element is html.InputElement && !_isProcessing) {
            _isProcessing = true;
            element.focus();
            Future.delayed(const Duration(milliseconds: 50), () {
              _isProcessing = false;
            });
          }
        });
      }
    } catch (e) {
      print('❌ Error fixing input field: $e');
    }
  }
}

// SAFE Custom TextField widget - NO RECURSION
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
    super.key,
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
  });

  @override
  State<IOSFixedTextField> createState() => _IOSFixedTextFieldState();
}

class _IOSFixedTextFieldState extends State<IOSFixedTextField> {
  late FocusNode _focusNode;
  bool _isTriggering = false; // Prevent recursion

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    if (kIsWeb) {
      _focusNode.addListener(() {
        if (_focusNode.hasFocus && !_isTriggering) {
          _triggerIOSKeyboard();
        }
      });
    }
  }

  void _triggerIOSKeyboard() {
    if (!kIsWeb || _isTriggering) return;

    _isTriggering = true;

    // Simple keyboard trigger - NO RECURSION
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && _focusNode.hasFocus && !_isTriggering) {
        try {
          SystemChannels.textInput.invokeMethod('TextInput.show');
        } catch (e) {
          print('Keyboard trigger error: $e');
        }
      }
      _isTriggering = false;
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
