import 'package:flutter/material.dart';

import '../state/inherited_chat_theme.dart';
import '../state/inherited_l10n.dart';

import 'package:flutter_svg/flutter_svg.dart';

/// A class that represents attachment button widget.
class AttachmentButton extends StatelessWidget {
  /// Creates attachment button widget.
  const AttachmentButton({
    super.key,
    this.isLoading = false,
    this.onPressed,
    this.padding = EdgeInsets.zero,
    this.imageIcon,
  });

  /// Show a loading indicator instead of the button.
  final bool isLoading;

  /// Callback for attachment button tap event.
  final VoidCallback? onPressed;

  /// Padding around the button.
  final EdgeInsets padding;

  final SvgPicture? imageIcon;

  @override
  Widget build(BuildContext context) => Container(
        //color: Colors.amber,
        margin: InheritedChatTheme.of(context).theme.attachmentButtonMargin ??
            const EdgeInsetsDirectional.fromSTEB(
              8,
              0,
              0,
              0,
            ),
        child: IconButton(
          constraints: const BoxConstraints(
            minHeight: 24,
            minWidth: 24,
          ),
          icon
              // icon: isLoading
              //     ? SizedBox(
              //         height: 20,
              //         width: 20,
              //         child: CircularProgressIndicator(
              //           backgroundColor: Colors.transparent,
              //           strokeWidth: 1.5,
              //           valueColor: AlwaysStoppedAnimation<Color>(
              //             InheritedChatTheme.of(context).theme.inputTextColor,
              //           ),
              //         ),
              //       )
              //: InheritedChatTheme.of(context).theme.attachmentButtonIcon ??
              : imageIcon ??
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Colors.white,
                  ),

          // Image.asset(
          //   'assets/icon-attachment.png',
          //   color: InheritedChatTheme.of(context).theme.inputTextColor,
          //   package: 'flutter_chat_ui',
          // ),
          onPressed: isLoading ? null : onPressed,
          //padding: padding,
          splashRadius: 24,
          tooltip:
              InheritedL10n.of(context).l10n.attachmentButtonAccessibilityLabel,
        ),
      );
}
