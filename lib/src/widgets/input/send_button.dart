import 'package:flutter/material.dart';

import '../state/inherited_chat_theme.dart';
import '../state/inherited_l10n.dart';

import 'package:flutter_svg/flutter_svg.dart';

/// A class that represents send button widget.
class SendButton extends StatelessWidget {
  /// Creates send button widget.
  const SendButton(
      {super.key,
      required this.onPressed,
      this.padding = EdgeInsets.zero,
      this.sendIcon});

  /// Callback for send button tap event.
  final VoidCallback onPressed;

  /// Padding around the button.
  final EdgeInsets padding;

  final SvgPicture? sendIcon;

  @override
  Widget build(BuildContext context) => Container(
        margin: InheritedChatTheme.of(context).theme.sendButtonMargin ??
            const EdgeInsetsDirectional.fromSTEB(0, 0, 16, 0),
        child: IconButton(
          constraints: const BoxConstraints(
            minHeight: 32,
            minWidth: 32,
          ),
          //icon: InheritedChatTheme.of(context).theme.sendButtonIcon ??
          icon: sendIcon ?? Container(),

          // Image.asset(
          //   'assets/icon-send.png',
          //   color: InheritedChatTheme.of(context).theme.inputTextColor,
          //   package: 'flutter_chat_ui',
          // ),
          onPressed: onPressed,
          padding: padding,
          splashRadius: 24,
          tooltip: InheritedL10n.of(context).l10n.sendButtonAccessibilityLabel,
        ),
      );
}
