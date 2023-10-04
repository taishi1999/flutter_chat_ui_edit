import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart' show PhotoViewComputedScale;
import 'package:scroll_to_index/scroll_to_index.dart';

import '../chat_l10n.dart';
import '../chat_theme.dart';
import '../models/bubble_rtl_alignment.dart';
import '../models/date_header.dart';
import '../models/emoji_enlargement_behavior.dart';
import '../models/message_spacer.dart';
import '../models/preview_image.dart';
import '../models/unread_header_data.dart';
import '../util.dart';
import 'chat_list.dart';
import 'image_gallery.dart';
import 'input/animated_triangle.dart';
import 'input/input.dart';
import 'message/message.dart';
import 'message/system_message.dart';
import 'message/text_message.dart';
import 'state/inherited_chat_theme.dart';
import 'state/inherited_l10n.dart';
import 'state/inherited_user.dart';
import 'typing_indicator.dart';
import 'unread_header.dart';

import 'input/painter.dart';
import 'input/app_colors.dart';
import 'input/animated_onTap_button.dart';
import 'package:decorated_icon/decorated_icon.dart';

import 'package:flutter_svg/flutter_svg.dart';

/// Entry widget, represents the complete chat. If you wrap it in [SafeArea] and
/// it should be full screen, set [SafeArea]'s `bottom` to `false`.
class Chat extends StatefulWidget {
  /// Creates a chat widget.
  const Chat({
    super.key,
    this.audioMessageBuilder,
    this.avatarBuilder,
    this.bubbleBuilder,
    this.bubbleRtlAlignment = BubbleRtlAlignment.right,
    this.customBottomWidget,
    this.customDateHeaderText,
    this.customMessageBuilder,
    this.customStatusBuilder,
    this.dateFormat,
    this.dateHeaderBuilder,
    this.dateHeaderThreshold = 900000,
    this.dateIsUtc = false,
    this.dateLocale,
    this.disableImageGallery,
    this.emojiEnlargementBehavior = EmojiEnlargementBehavior.multi,
    this.emptyState,
    this.fileMessageBuilder,
    this.groupMessagesThreshold = 60000,
    this.hideBackgroundOnEmojiMessages = true,
    this.imageGalleryOptions = const ImageGalleryOptions(
      maxScale: PhotoViewComputedScale.covered,
      minScale: PhotoViewComputedScale.contained,
    ),
    this.imageHeaders,
    this.imageMessageBuilder,
    this.inputOptions = const InputOptions(),
    this.isAttachmentUploading,
    this.isLastPage,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.l10n = const ChatL10nEn(),
    this.listBottomWidget,
    required this.messages,
    this.nameBuilder,
    this.onAttachmentPressed,
    this.onPenPressed,
    this.onAvatarTap,
    this.onBackgroundTap,
    this.onEndReached,
    this.onEndReachedThreshold,
    this.onMessageDoubleTap,
    this.onMessageLongPress,
    this.onMessageStatusLongPress,
    this.onMessageStatusTap,
    this.onMessageTap,
    this.onMessageVisibilityChanged,
    this.onPreviewDataFetched,
    required this.onSendPressed,
    this.scrollController,
    this.scrollPhysics,
    this.scrollToUnreadOptions = const ScrollToUnreadOptions(),
    this.showUserAvatars = false,
    this.showUserNames = false,
    this.systemMessageBuilder,
    this.textMessageBuilder,
    this.textMessageOptions = const TextMessageOptions(),
    this.theme = const DefaultChatTheme(),
    this.timeFormat,
    this.typingIndicatorOptions = const TypingIndicatorOptions(),
    this.usePreviewData = true,
    required this.user,
    this.userAgent,
    this.useTopSafeAreaInset,
    this.videoMessageBuilder,
    this.penIcon,
    this.imageIcon,
    this.undoIcon,
    this.sendIcon,
  });
  final SvgPicture? penIcon;
  final SvgPicture? imageIcon;
  final SvgPicture Function(bool)? undoIcon;
  final SvgPicture? sendIcon;

  /// See [Message.audioMessageBuilder].
  final Widget Function(types.AudioMessage, {required int messageWidth})?
      audioMessageBuilder;

  /// See [Message.avatarBuilder].
  final Widget Function(String userId)? avatarBuilder;

  /// See [Message.bubbleBuilder].
  final Widget Function(
    Widget child, {
    required types.Message message,
    required bool nextMessageInGroup,
  })? bubbleBuilder;

  /// See [Message.bubbleRtlAlignment].
  final BubbleRtlAlignment? bubbleRtlAlignment;

  /// Allows you to replace the default Input widget e.g. if you want to create
  /// a channel view. If you're looking for the bottom widget added to the chat
  /// list, see [listBottomWidget] instead.
  final Widget? customBottomWidget;

  /// If [dateFormat], [dateLocale] and/or [timeFormat] is not enough to
  /// customize date headers in your case, use this to return an arbitrary
  /// string based on a [DateTime] of a particular message. Can be helpful to
  /// return "Today" if [DateTime] is today. IMPORTANT: this will replace
  /// all default date headers, so you must handle all cases yourself, like
  /// for example today, yesterday and before. Or you can just return the same
  /// date header for any message.
  final String Function(DateTime)? customDateHeaderText;

  /// See [Message.customMessageBuilder].
  final Widget Function(types.CustomMessage, {required int messageWidth})?
      customMessageBuilder;

  /// See [Message.customStatusBuilder].
  final Widget Function(types.Message message, {required BuildContext context})?
      customStatusBuilder;

  /// Allows you to customize the date format. IMPORTANT: only for the date,
  /// do not return time here. See [timeFormat] to customize the time format.
  /// [dateLocale] will be ignored if you use this, so if you want a localized date
  /// make sure you initialize your [DateFormat] with a locale. See [customDateHeaderText]
  /// for more customization.
  final DateFormat? dateFormat;

  /// Custom date header builder gives ability to customize date header widget.
  final Widget Function(DateHeader)? dateHeaderBuilder;

  /// Time (in ms) between two messages when we will render a date header.
  /// Default value is 15 minutes, 900000 ms. When time between two messages
  /// is higher than this threshold, date header will be rendered. Also,
  /// not related to this value, date header will be rendered on every new day.
  final int dateHeaderThreshold;

  /// Use utc time to convert message milliseconds to date.
  final bool dateIsUtc;

  /// Locale will be passed to the `Intl` package. Make sure you initialized
  /// date formatting in your app before passing any locale here, otherwise
  /// an error will be thrown. Also see [customDateHeaderText], [dateFormat], [timeFormat].
  final String? dateLocale;

  /// Disable automatic image preview on tap.
  final bool? disableImageGallery;

  /// See [Message.emojiEnlargementBehavior].
  final EmojiEnlargementBehavior emojiEnlargementBehavior;

  /// Allows you to change what the user sees when there are no messages.
  /// `emptyChatPlaceholder` and `emptyChatPlaceholderTextStyle` are ignored
  /// in this case.
  final Widget? emptyState;

  /// See [Message.fileMessageBuilder].
  final Widget Function(types.FileMessage, {required int messageWidth})?
      fileMessageBuilder;

  /// Time (in ms) between two messages when we will visually group them.
  /// Default value is 1 minute, 60000 ms. When time between two messages
  /// is lower than this threshold, they will be visually grouped.
  final int groupMessagesThreshold;

  /// See [Message.hideBackgroundOnEmojiMessages].
  final bool hideBackgroundOnEmojiMessages;

  /// See [ImageGallery.options].
  final ImageGalleryOptions imageGalleryOptions;

  /// Headers passed to all network images used in the chat.
  final Map<String, String>? imageHeaders;

  /// See [Message.imageMessageBuilder].
  final Widget Function(types.ImageMessage, {required int messageWidth})?
      imageMessageBuilder;

  /// See [Input.options].
  final InputOptions inputOptions;

  /// See [Input.isAttachmentUploading].
  final bool? isAttachmentUploading;

  /// See [ChatList.isLastPage].
  final bool? isLastPage;

  /// See [ChatList.keyboardDismissBehavior].
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Localized copy. Extend [ChatL10n] class to create your own copy or use
  /// existing one, like the default [ChatL10nEn]. You can customize only
  /// certain properties, see more here [ChatL10nEn].
  final ChatL10n l10n;

  /// See [ChatList.bottomWidget]. For a custom chat input
  /// use [customBottomWidget] instead.
  final Widget? listBottomWidget;

  /// List of [types.Message] to render in the chat widget.
  final List<types.Message> messages;

  /// See [Message.nameBuilder].
  final Widget Function(String userId)? nameBuilder;

  /// See [Input.onAttachmentPressed].
  final VoidCallback? onAttachmentPressed;

  final void Function([Map<String, dynamic>])? onPenPressed;

  /// See [Message.onAvatarTap].
  final void Function(types.User)? onAvatarTap;

  /// Called when user taps on background.
  final VoidCallback? onBackgroundTap;

  /// See [ChatList.onEndReached].
  final Future<void> Function()? onEndReached;

  /// See [ChatList.onEndReachedThreshold].
  final double? onEndReachedThreshold;

  /// See [Message.onMessageDoubleTap].
  final void Function(BuildContext context, types.Message)? onMessageDoubleTap;

  /// See [Message.onMessageLongPress].
  final void Function(BuildContext context, types.Message)? onMessageLongPress;

  /// See [Message.onMessageStatusLongPress].
  final void Function(BuildContext context, types.Message)?
      onMessageStatusLongPress;

  /// See [Message.onMessageStatusTap].
  final void Function(BuildContext context, types.Message)? onMessageStatusTap;

  /// See [Message.onMessageTap].
  final void Function(BuildContext context, types.Message)? onMessageTap;

  /// See [Message.onMessageVisibilityChanged].
  final void Function(types.Message, bool visible)? onMessageVisibilityChanged;

  /// See [Message.onPreviewDataFetched].
  final void Function(types.TextMessage, types.PreviewData)?
      onPreviewDataFetched;

  /// See [Input.onSendPressed].
  final void Function(types.PartialText) onSendPressed;

  /// See [ChatList.scrollController].
  /// If provided, you cannot use the scroll to message functionality.
  final AutoScrollController? scrollController;

  /// See [ChatList.scrollPhysics].
  final ScrollPhysics? scrollPhysics;

  /// Controls if and how the chat should scroll to the newest unread message.
  final ScrollToUnreadOptions scrollToUnreadOptions;

  /// See [Message.showUserAvatars].
  final bool showUserAvatars;

  /// Show user names for received messages. Useful for a group chat. Will be
  /// shown only on text messages.
  final bool showUserNames;

  /// Builds a system message outside of any bubble.
  final Widget Function(types.SystemMessage)? systemMessageBuilder;

  /// See [Message.textMessageBuilder].
  final Widget Function(
    types.TextMessage, {
    required int messageWidth,
    required bool showName,
  })? textMessageBuilder;

  /// See [Message.textMessageOptions].
  final TextMessageOptions textMessageOptions;

  /// Chat theme. Extend [ChatTheme] class to create your own theme or use
  /// existing one, like the [DefaultChatTheme]. You can customize only certain
  /// properties, see more here [DefaultChatTheme].
  final ChatTheme theme;

  /// Allows you to customize the time format. IMPORTANT: only for the time,
  /// do not return date here. See [dateFormat] to customize the date format.
  /// [dateLocale] will be ignored if you use this, so if you want a localized time
  /// make sure you initialize your [DateFormat] with a locale. See [customDateHeaderText]
  /// for more customization.
  final DateFormat? timeFormat;

  /// Used to show typing users with indicator. See [TypingIndicatorOptions].
  final TypingIndicatorOptions typingIndicatorOptions;

  /// See [Message.usePreviewData].
  final bool usePreviewData;

  /// See [InheritedUser.user].
  final types.User user;

  /// See [Message.userAgent].
  final String? userAgent;

  /// See [ChatList.useTopSafeAreaInset].
  final bool? useTopSafeAreaInset;

  /// See [Message.videoMessageBuilder].
  final Widget Function(types.VideoMessage, {required int messageWidth})?
      videoMessageBuilder;

  @override
  State<Chat> createState() => ChatState();
}

/// [Chat] widget state.
class ChatState extends State<Chat> {
  /// Used to get the correct auto scroll index from [_autoScrollIndexById].
  static const String _unreadHeaderId = 'unread_header_id';

  List<Object> _chatMessages = [];
  List<PreviewImage> _gallery = [];
  PageController? _galleryPageController;
  bool _hadScrolledToUnreadOnOpen = false;
  bool _isImageViewVisible = false;
  bool _isPainterVisible = false;
  bool _isInputVisible = true;
  bool _finished = false;
  bool isTouching = false;

  double scrollposition = 0.0;
  double messageSize = 16;

  String inputText = ' ';
  late final InputOptions options;

  final GlobalKey previewKey = GlobalKey();

  /// Keep track of all the auto scroll indices by their respective message's id to allow animating to them.
  final Map<String, int> _autoScrollIndexById = {};
  late final AutoScrollController _scrollController;

  PainterController _controller = _newController();

  static PainterController _newController() {
    PainterController controller = new PainterController();
    //太さ
    controller.thickness = 16.0;
    controller.backgroundColor = Colors.transparent;
    return controller;
  }

  void setScrollPosition(double position) {
    setState(() {
      scrollposition = position;
    });
  }

  double setMessageSize(double sliderValue, double defaultValue, int max) {
    double size = 1;
    setState(() {
      if (sliderValue > defaultValue) {
        double value = (pow(1.1, sliderValue - defaultValue) - 1) /
                (pow(1.1, defaultValue) - 1) *
                max +
            defaultValue;
        size = value;
      } else {
        size = sliderValue;
      }
    });
    return size;
  }

  void jump() {
    _scrollController.animateTo(MediaQuery.of(context).size.height - 56,
        duration: const Duration(milliseconds: 100), curve: Curves.easeInQuad);
    // _scrollController.jumpTo(
    //   MediaQuery.of(context).size.height - 56,
    // );
  }

  void jump2() {
    // _scrollController.animateTo(MediaQuery.of(context).size.height - 56,
    //     duration: const Duration(milliseconds: 100), curve: Curves.easeInQuad);
    _scrollController.jumpTo(
      MediaQuery.of(context).size.height,
    );
  }

  @override
  void initState() {
    super.initState();

    _scrollController = widget.scrollController ??
        AutoScrollController(
            //initialScrollOffset: 300.0,
            );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (!_scrollController.hasClients) return;
        _scrollController.jumpTo(
          MediaQuery.of(context).size.height,
          //1000.0
        );
      });
      //jump2();
      // print('スクロールさせたいです');
      // _scrollController.animateTo(
      //   300.0,
      //   duration: Duration(milliseconds: 500),
      //   curve: Curves.easeInOut,
      // );
    });

    options = InputOptions(
      onTextChanged: (text) {
        setState(() {
          if (text == '') {
            inputText = ' ';
          } else {
            if (inputText == ' ') {
              jump();
            }

            inputText = text;
          }
        });

        print(text);
      },
      onTextFieldTap: () {},
    );
    didUpdateWidget(widget);
  }

  @override
  void didUpdateWidget(covariant Chat oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.messages.isNotEmpty) {
      final result = calculateChatMessages(
        widget.messages,
        widget.user,
        customDateHeaderText: widget.customDateHeaderText,
        dateFormat: widget.dateFormat,
        dateHeaderThreshold: widget.dateHeaderThreshold,
        dateIsUtc: widget.dateIsUtc,
        dateLocale: widget.dateLocale,
        groupMessagesThreshold: widget.groupMessagesThreshold,
        lastReadMessageId: widget.scrollToUnreadOptions.lastReadMessageId,
        showUserNames: widget.showUserNames,
        timeFormat: widget.timeFormat,
      );

      _chatMessages = result[0] as List<Object>;
      _gallery = result[1] as List<PreviewImage>;

      _refreshAutoScrollMapping();
      _maybeScrollToFirstUnread();
    }
  }

  @override
  void dispose() {
    _galleryPageController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Size returnSizeOfPreviewMessage() {
    final RenderBox renderBox =
        previewKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    print('previewSize: $size');
    return size;
  }

  /// Scroll to the unread header.
  void scrollToUnreadHeader() {
    final unreadHeaderIndex = _autoScrollIndexById[_unreadHeaderId];
    if (unreadHeaderIndex != null) {
      print('scrollToUnreadHeader');
      _scrollController.scrollToIndex(
        unreadHeaderIndex,
        duration: widget.scrollToUnreadOptions.scrollDuration,
      );
    }
  }

  /// Scroll to the message with the specified [id].
  void scrollToMessage(String id, {Duration? duration}) {
    print('scrollToMessage');
    _scrollController.scrollToIndex(
      _autoScrollIndexById[id]!,
      duration: duration ?? scrollAnimationDuration,
    );
  }

  void _onPanStart() {
    setState(() {
      _controller.isEmpty = false;
      isTouching = true;
//TODO:ここで制御？
    });
  }

  void _onPanEnd() {
    setState(() {
      isTouching = false;
//TODO:ここで制御？
      // _controller.clear();
    });
  }

  Container _displayPainter() => Container(
        child: Painter(
          painterController: _controller,
          onPanStart: _onPanStart,
          onPanEnd: _onPanEnd,
          // isLoadOnly: true,
        ),
      );

  bool _isChange = false;
  bool _showIndicator = false;
  int _paintSelectedBorder = 1;
  int _textSelectedBorder = 1;
  Color textColor = Colors.black;

  List<Color>? _colorList = AppColors.defaultColors;

  // ignore: member-ordering
  @override
  Widget build(BuildContext context) => InheritedUser(
        user: widget.user,
        child: InheritedChatTheme(
          theme: widget.theme,
          child: InheritedL10n(
            l10n: widget.l10n,
            child: Stack(
              children: [
                Container(
                  color: widget.theme.backgroundColor,
                  child: Column(
                    children: [
                      //チャットが空白の時に表示させる
                      // SizedBox.expand(
                      //   child: _emptyStateBuilder(),
                      // ),

                      //チャット
                      Flexible(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                widget.onBackgroundTap?.call();
                                //jump();
                              },
                              child: LayoutBuilder(
                                builder: (
                                  BuildContext context,
                                  BoxConstraints constraints,
                                ) =>
                                    ChatList(
                                  bottomWidget: widget.listBottomWidget,
                                  bubbleRtlAlignment:
                                      widget.bubbleRtlAlignment!,
                                  isLastPage: widget.isLastPage,
                                  itemBuilder: (Object item, int? index) =>
                                      _messageBuilder(
                                    item,
                                    constraints,
                                    index,
                                  ),
                                  previewMessageBuilder: () =>
                                      _previewMessageBuilder(constraints),
                                  items: _chatMessages,
                                  painter: _displayPainter(),
                                  isPenPressed: _isPainterVisible,
                                  //loadPainter: _displayLoadPainter(),
                                  setScrollPosition: (position) {
                                    setScrollPosition(position);
                                  },
                                  keyboardDismissBehavior:
                                      widget.keyboardDismissBehavior,
                                  onEndReached: widget.onEndReached,
                                  onEndReachedThreshold:
                                      widget.onEndReachedThreshold,
                                  scrollController: _scrollController,
                                  scrollPhysics: widget.scrollPhysics,
                                  typingIndicatorOptions:
                                      widget.typingIndicatorOptions,
                                  useTopSafeAreaInset:
                                      widget.useTopSafeAreaInset ?? isMobile,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 300, // Container's position
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height: 200, // Container's height
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ),

                            //お絵描き機能
                            Visibility(
                              visible: _isPainterVisible,
                              child: Container(
                                height: MediaQuery.of(context).size.height,
                                child: _displayPainter(),
                              ),
                            ),

                            // カラーピッカー
                            Visibility(
                              visible: inputText != ' ' && !_isPainterVisible,
                              child: colorPicker('text'),
                            ),
                          ],
                        ),
                      ),

                      //インプット
                      // Opacity(
                      //   opacity: _isPainterVisible ? 0.0 : 1,
                      Visibility(
                        visible: !_isPainterVisible,
                        child: Column(
                          children: [
                            widget.customBottomWidget ??
                                Input(
                                  penIcon: widget.penIcon,
                                  imageIcon: widget.imageIcon,
                                  sendIcon: widget.sendIcon,
                                  isAttachmentUploading:
                                      widget.isAttachmentUploading,
                                  onAttachmentPressed:
                                      widget.onAttachmentPressed,
                                  onPenPressed: () {
                                    //お絵描きPainter表示
                                    _onPenPressed();
                                    //mainのAppBar非表示
                                    widget.onPenPressed?.call();
                                  },
                                  onSendPressed: (types.PartialText message) {
                                    widget.onSendPressed(message);
                                    setState(() {
                                      inputText = ' ';
                                      messageSize = 16;
                                    });
                                  },
                                  options: options,
                                  messageSize: messageSize,
                                  textColor: textColor.value,
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Visibility(
                //   child: colorPicker(),
                // ),
                Visibility(
                  visible: inputText != ' ' && !_isPainterVisible,
                  child: AnimatedTriangle(
                    defaultValue: 16,
                    maxValue: 32,
                    changeValue: (double size) {
                      messageSize = setMessageSize(size, 16, 300);
                      returnSizeOfPreviewMessage();
                    },
                  ),
                ),

                Visibility(
                  visible: _isPainterVisible,
                  child: SafeArea(
                    child: Stack(
                      children: [
                        //キャンセル、完了、undo&redo
                        Center(
                          child: Column(
                            children: [
                              AnimatedOpacity(
                                //opacity: 1,
                                opacity: isTouching ? 0.0 : 1.0,
                                duration: Duration(milliseconds: 150),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    color: Colors.black.withOpacity(0.8),
                                    width: MediaQuery.of(context).size.width,
                                    height: 56,
                                    //color: Colors.blueGrey,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      //crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          style: ButtonStyle(
                                            overlayColor: MaterialStateProperty
                                                .all<Color>(
                                              Colors.white.withOpacity(0.2),
                                            ),
                                            foregroundColor:
                                                MaterialStateProperty.all<
                                                    Color>(
                                              Colors.white,
                                            ),
                                          ),
                                          onPressed: () {
                                            _controller.clear();
                                            _onPenPressed();
                                            widget.onPenPressed?.call();
                                            var position =
                                                _scrollController.offset;
                                            // _scrollController.jumpTo(
                                            //   position + 128,
                                            // );
                                          },
                                          child: Text(
                                            'キャンセル',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 10.0,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              //color: Colors.blue,
                                              width: 36,
                                              child: IconButton(
                                                //enable: !_controller.isEmpty,
                                                icon: widget.undoIcon != null
                                                    ? widget.undoIcon!(
                                                        _controller.isEmpty)
                                                    : Icon(
                                                        Icons.undo_rounded,
                                                        color:
                                                            _controller.isEmpty
                                                                ? Colors.grey
                                                                : Colors.white,
                                                      ),
                                                //  icon: widget.undoIcon != null
                                                //     ? Image(
                                                //         image: widget.undoIcon!,
                                                //         color:
                                                //             _controller.isEmpty
                                                //                 ? Colors.grey
                                                //                 : Colors.white,
                                                //       )
                                                //     : Container(),

                                                // icon: Icon(
                                                //   Icons.undo,
                                                //   color: _controller.isEmpty
                                                //       ? Colors.grey
                                                //       : Colors.white,
                                                //   shadows: [
                                                //     BoxShadow(
                                                //       color: Colors.black, //色
                                                //       blurRadius: 10, //ぼやけ具合
                                                //     ),
                                                //   ],
                                                // ),
                                                tooltip: 'Undo',
                                                onPressed: _controller.isEmpty
                                                    ? null
                                                    : () {
                                                        _controller.undo();
                                                        setState(() {
                                                          _controller
                                                                  .isUndoPathEmpty =
                                                              false;
                                                        });
                                                        if (_controller
                                                            .isEmpty) {
                                                          print(
                                                              'undoでnullになったよ');
                                                          setState(() {
                                                            _controller
                                                                .isEmpty = true;
                                                          });
                                                        }
                                                      },
                                              ),
                                            ),
                                            Container(
                                              //color: Colors.blue,
                                              width: 36,
                                              child: IconButton(
                                                //enable: !_controller.isEmpty,
                                                icon: Transform(
                                                  alignment: Alignment.center,
                                                  transform: Matrix4.identity()
                                                    ..scale(-1.0, 1.0),
                                                  child: widget.undoIcon != null
                                                      ? widget.undoIcon!(
                                                          _controller
                                                              .isUndoPathEmpty,
                                                        )
                                                      : Icon(
                                                          Icons.undo_rounded,
                                                          color: _controller
                                                                  .isUndoPathEmpty
                                                              ? Colors.grey
                                                              : Colors.white,
                                                        ),
                                                ),
                                                // icon: widget.undoIcon != null
                                                //     ? Image(
                                                //         image: widget.undoIcon!,
                                                //         color: _controller
                                                //                 .isUndoPathEmpty
                                                //             ? Colors.grey
                                                //             : Colors.white,
                                                //       )
                                                //     : Container(),

                                                // icon: Icon(
                                                //   Icons.redo,
                                                //   color:
                                                //       _controller.isUndoPathEmpty
                                                //           ? Colors.grey
                                                //           : Colors.white,
                                                //   shadows: [
                                                //     BoxShadow(
                                                //       //color: Colors.black, //色
                                                //       blurRadius: 10, //ぼやけ具合
                                                //     ),
                                                //   ],
                                                // ),
                                                tooltip: 'Redo',
                                                onPressed: _controller
                                                        .isUndoPathEmpty
                                                    ? null
                                                    : () {
                                                        _controller.redo();
                                                        setState(() {
                                                          _controller.isEmpty =
                                                              false;
                                                        });
                                                        if (_controller
                                                            .isUndoPathEmpty) {
                                                          print(
                                                              'redoでnullになったよ!');
                                                          setState(() {
                                                            _controller
                                                                    .isUndoPathEmpty =
                                                                true;
                                                          });
                                                        }
                                                      },
                                              ),
                                            ),
                                          ],
                                        ),
                                        TextButton(
                                          style: ButtonStyle(
                                              // overlayColor: MaterialStateProperty
                                              //     .all<Color>(
                                              //   Colors.white.withOpacity(1),
                                              // ),
                                              // foregroundColor:
                                              //     MaterialStateProperty.all<
                                              //         Color>(
                                              //   Colors.white,
                                              // ),
                                              ),
                                          onPressed: _controller.isEmpty
                                              ? null
                                              : () {
                                                  //ここでスクロールポジションを取得して、
                                                  _onPenPressed();
                                                  _show();
                                                  widget.onPenPressed?.call(
                                                    _controller.toMap(),
                                                  );

                                                  //_controller.finish();
                                                  _controller.clear();
                                                },
                                          child: Text(
                                            '完了',
                                            style: TextStyle(
                                              color: _controller.isEmpty
                                                  ? Colors.grey
                                                  : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 10.0,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Expanded(
                              //   child: Painter(
                              //     painterController: _controller,
                              //     onPanStart: _onPanStart,
                              //     onPanEnd: _onPanEnd,
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                        //太さ
                        AnimatedTriangle(
                          defaultValue: 6,
                          maxValue: 12,
                          changeValue: (double size) {
                            setState(() {
                              _controller.thickness =
                                  setMessageSize(size, 6, 100);
                            });
                          },
                        ),
                        //カラーピッカー
                        AnimatedOpacity(
                          opacity: isTouching ? 0.0 : 1.0,
                          duration: Duration(milliseconds: 150),
                          child: colorPicker('paint'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isImageViewVisible)
                  ImageGallery(
                    imageHeaders: widget.imageHeaders,
                    images: _gallery,
                    pageController: _galleryPageController!,
                    onClosePressed: _onCloseGalleryPressed,
                    options: widget.imageGalleryOptions,
                  ),
              ],
            ),
          ),
        ),
      );

  Widget colorPicker(String TextOrPaint) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 64,
        color: Colors.transparent,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          child: Row(
            //crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ..._colorList!.map((color) {
                final int index = _colorList!.indexOf(color);

                return AnimatedOnTapButton(
                  onTap: () {
                    if (TextOrPaint == 'paint') {
                      _controller.drawColor = _colorList![index];

                      setState(() {
                        _paintSelectedBorder = index;
                      });
                    } else {
                      setState(() {
                        textColor = _colorList![index];
                        _textSelectedBorder = index;
                      });
                    }
                    // if (controlProvider.isPainting) {
                    //   paintingProvider.lineColor = index;
                    // } else {
                    //   editorProvider.textColor = index;
                    // }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                    child: Container(
                      // shadows: [
                      //   BoxShadow(
                      //     color: Colors.black, //色
                      //     blurRadius: 10, //ぼやけ具合
                      //   ),
                      // ],
                      height: 24,
                      width: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black, //色
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: Offset(0, 0),
                          ),
                        ],
                        color: _colorList![index],
                        shape: BoxShape.circle,
                        border: TextOrPaint == 'paint'
                            ? _paintSelectedBorder == index
                                ? returnBorder(index)
                                : Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  )
                            : _textSelectedBorder == index
                                ? returnBorder(index)
                                : Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyStateBuilder() =>
      widget.emptyState ??
      Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(
          horizontal: 24,
        ),
        child: Text(
          widget.l10n.emptyChatPlaceholder,
          style: widget.theme.emptyChatPlaceholderTextStyle,
          textAlign: TextAlign.center,
        ),
      );

  /// Only scroll to first unread if there are messages and it is the first open.
  void _maybeScrollToFirstUnread() {
    if (widget.scrollToUnreadOptions.scrollOnOpen &&
        _chatMessages.isNotEmpty &&
        !_hadScrolledToUnreadOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await Future.delayed(widget.scrollToUnreadOptions.scrollDelay);
          scrollToUnreadHeader();
        }
      });
      _hadScrolledToUnreadOnOpen = true;
    }
  }

  /// We need the index for auto scrolling because it will scroll until it reaches an index higher or equal that what it is scrolling towards. Index will be null for removed messages. Can just set to -1 for auto scroll.
  Widget _messageBuilder(
    Object object,
    BoxConstraints constraints,
    int? index,
  ) {
    if (object is DateHeader) {
      return widget.dateHeaderBuilder?.call(object) ??
          Container(
            alignment: Alignment.center,
            //color: Colors.amber,
            padding: widget.theme.dateDividerMargin,
            child: Text(
              object.text,
              style: widget.theme.dateDividerTextStyle,
            ),
          );
    } else if (object is MessageSpacer) {
      return Container(
        color: Colors.blue,
        height: object.height,
      );
      // return SizedBox(
      //   height: object.height,
      // );
    } else if (object is UnreadHeaderData) {
      return AutoScrollTag(
        controller: _scrollController,
        index: index ?? -1,
        key: const Key('unread_header'),
        child: UnreadHeader(
          marginTop: object.marginTop,
        ),
      );
    } else {
      final map = object as Map<String, Object>;
      final message = map['message']! as types.Message;

      final Widget messageWidget;

      if (message is types.SystemMessage) {
        messageWidget = widget.systemMessageBuilder?.call(message) ??
            SystemMessage(message: message.text);
      } else {
        final messageWidth =
            widget.showUserAvatars && message.author.id != widget.user.id
                ? min(constraints.maxWidth * 0.78, 440).floor()
                : min(constraints.maxWidth * 0.78, 440).floor();

        messageWidget = Message(
          audioMessageBuilder: widget.audioMessageBuilder,
          avatarBuilder: widget.avatarBuilder,
          bubbleBuilder: widget.bubbleBuilder,
          bubbleRtlAlignment: widget.bubbleRtlAlignment,
          customMessageBuilder: widget.customMessageBuilder,
          customStatusBuilder: widget.customStatusBuilder,
          emojiEnlargementBehavior: widget.emojiEnlargementBehavior,
          fileMessageBuilder: widget.fileMessageBuilder,
          hideBackgroundOnEmojiMessages: widget.hideBackgroundOnEmojiMessages,
          imageHeaders: widget.imageHeaders,
          imageMessageBuilder: widget.imageMessageBuilder,
          message: message,
          messageWidth: messageWidth,
          nameBuilder: widget.nameBuilder,
          onAvatarTap: widget.onAvatarTap,
          onMessageDoubleTap: widget.onMessageDoubleTap,
          onMessageLongPress: widget.onMessageLongPress,
          onMessageStatusLongPress: widget.onMessageStatusLongPress,
          onMessageStatusTap: widget.onMessageStatusTap,
          onMessageTap: (context, tappedMessage) {
            if (tappedMessage is types.ImageMessage &&
                widget.disableImageGallery != true) {
              _onImagePressed(tappedMessage);
            }
            print('tappedMessage: $tappedMessage.type');
            widget.onMessageTap?.call(context, tappedMessage);
          },
          onMessageVisibilityChanged: widget.onMessageVisibilityChanged,
          onPreviewDataFetched: _onPreviewDataFetched,
          roundBorder: map['nextMessageInGroup'] == true,
          showAvatar: map['nextMessageInGroup'] == false,
          showName: map['showName'] == true,
          showStatus: map['showStatus'] == true,
          showUserAvatars: widget.showUserAvatars,
          textMessageBuilder: widget.textMessageBuilder,
          textMessageOptions: widget.textMessageOptions,
          usePreviewData: widget.usePreviewData,
          userAgent: widget.userAgent,
          videoMessageBuilder: widget.videoMessageBuilder,
        );
      }

      //ペイントなら
      if (message.metadata != null &&
          message.metadata![MessageMetadata.painter.name] != null) {
        // //新しくリストを作り追加
        // List<dynamic> _painter2 = [];
        // _painter2.add(message.metadata![MessageMetadata.painter.name]);
        // metadata から PaintController を取得
        final loadPaintController = _newController()
            .fromMetaData(message.metadata![MessageMetadata.painter.name]);

        //print(message.metadata);
        return AutoScrollTag(
          controller: _scrollController,
          index: index ?? -1,
          key: Key('scroll-${message.id}'),
          child: Container(
            // height: MediaQuery.of(context).size.height,
            // metadataから取得した高さをセット 場所はここで良い？.
            height: loadPaintController.heightFromMapData,
            child: RepaintBoundary(
              // <-- 描画が重いのでRepaintBoundaryで囲んで見ましたが、効果なし
              child: Painter(
                // painterController: _loadPaintController.fromList(_painter2),
                painterController: loadPaintController,
                isLoadOnly: true,
              ),
            ),
          ),
        );
      }
      return AutoScrollTag(
        controller: _scrollController,
        index: index ?? -1,
        key: Key('scroll-${message.id}'),
        child: messageWidget,
      );
    }
  }

  Widget _previewMessageBuilder(
    BoxConstraints constraints,
  ) {
    final Widget previewMessageWidget;
    final messageWidth = min(constraints.maxWidth * 0.8, 440).floor();
    //print('widget.user.id: ${widget.user.id}');
    final _user = types.User(
      firstName: "Preview",
      id: widget.user.id,
      //imageUrl: "https://i.pravatar.cc/300?u=e52552f4-835d-4dbe-ba77-b076e659774d",
      //lastName: "White",
    );
    Map<String, dynamic>? textStyle = {
      'fontsize': messageSize,
      'color': textColor.value,
    };
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: widget.user.id,
      text: inputText,
      metadata: textStyle,
    );
    //print('ユーザーid: ${widget.user.id}');
    previewMessageWidget = Message(
      audioMessageBuilder: widget.audioMessageBuilder,
      avatarBuilder: widget.avatarBuilder,
      bubbleBuilder: widget.bubbleBuilder,
      bubbleRtlAlignment: widget.bubbleRtlAlignment,
      customMessageBuilder: widget.customMessageBuilder,
      customStatusBuilder: widget.customStatusBuilder,
      emojiEnlargementBehavior: EmojiEnlargementBehavior.never,
      fileMessageBuilder: widget.fileMessageBuilder,
      hideBackgroundOnEmojiMessages: widget.hideBackgroundOnEmojiMessages,
      imageHeaders: widget.imageHeaders,
      imageMessageBuilder: widget.imageMessageBuilder,
      message: textMessage,
      messageWidth: messageWidth,
      nameBuilder: widget.nameBuilder,
      onAvatarTap: widget.onAvatarTap,
      onMessageDoubleTap: widget.onMessageDoubleTap,
      onMessageLongPress: widget.onMessageLongPress,
      onMessageStatusLongPress: widget.onMessageStatusLongPress,
      onMessageStatusTap: widget.onMessageStatusTap,
      onMessageTap: (context, tappedMessage) {
        //previewなので何もしない
        // if (tappedMessage is types.ImageMessage &&
        //     widget.disableImageGallery != true) {
        //   _onImagePressed(tappedMessage);
        // }
        // print('tappedMessage: $tappedMessage.type');
        // widget.onMessageTap?.call(context, tappedMessage);
      },
      onMessageVisibilityChanged: widget.onMessageVisibilityChanged,
      onPreviewDataFetched: _onPreviewDataFetched,
      roundBorder: true,
      showAvatar: true,
      showName: true,
      showStatus: false,
      showUserAvatars: widget.showUserAvatars,
      textMessageBuilder: widget.textMessageBuilder,
      textMessageOptions: widget.textMessageOptions,
      //falseに設定しないとExceptionsが発生する
      usePreviewData: false,
      userAgent: widget.userAgent,
      videoMessageBuilder: widget.videoMessageBuilder,
    );

    return inputText != ' '
        ? Padding(
            key: previewKey,
            padding: const EdgeInsets.only(bottom: 12.0),
            child: previewMessageWidget,
          )
        : Container();
  }

  void calculateValue(double sliderValue) {}

  Border? returnBorder(int i) {
    if (i == 0) {
      return Border.all(color: Colors.grey, width: 5);
    } else {
      return Border.all(color: Colors.white, width: 5);
    }
  }

  void _onCloseGalleryPressed() {
    setState(() {
      _isImageViewVisible = false;
    });
    _galleryPageController?.dispose();
    _galleryPageController = null;
  }

  void _onImagePressed(types.ImageMessage message) {
    final initialPage = _gallery.indexWhere(
      (element) => element.id == message.id && element.uri == message.uri,
    );
    _galleryPageController = PageController(initialPage: initialPage);
    setState(() {
      _isImageViewVisible = true;
    });
  }

  void _onPenPressed() {
    print('_onPenPressed');
    // setState(() {
    //   _chatMessages.add(Container(
    //     color: Colors.pink,
    //     height: MediaQuery.of(context).size.height,
    //     // child: Painter(
    //     //   painterController: _paintController,
    //     //   isLoadOnly: false,
    //     // ),
    //   ));
    // });

    //ペンボタンタップ時にスクロール
    // var position = _scrollController.offset;
    // //print('position: $position');
    // if (position >= MediaQuery.of(context).size.height) {
    //   var s = MediaQuery.of(context).padding.top;
    //   print('MediaQuery.of(context).padding.top: $s');
    //   _scrollController.animateTo(
    //     56 + 0 + 24 + 0,
    //     duration: const Duration(milliseconds: 300),
    //     curve: Curves.easeInQuad,
    //   );
    // } else {
    //   _scrollController.jumpTo(
    //     position - 64,
    //   );
    // }

    // _scrollController.animateTo(
    //   128,
    //   duration: const Duration(milliseconds: 300),
    //   curve: Curves.easeInQuad,
    // );
    //_scrollController.jumpTo(_scrollController.position.minScrollExtent);
    setState(() {
      _isPainterVisible = !_isPainterVisible;
      //_isInputVisible = !_isInputVisible;
    });
    //widget.onPenPressed;
  }

  void _show() {
    setState(() {
      _finished = true;
    });
  }

  void _onPreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    widget.onPreviewDataFetched?.call(message, previewData);
  }

  /// Updates the [_autoScrollIndexById] mapping with the latest messages.
  void _refreshAutoScrollMapping() {
    _autoScrollIndexById.clear();
    var i = 0;
    for (final object in _chatMessages) {
      if (object is UnreadHeaderData) {
        _autoScrollIndexById[_unreadHeaderId] = i;
      } else if (object is Map<String, Object>) {
        final message = object['message']! as types.Message;
        _autoScrollIndexById[message.id] = i;
      }
      i++;
    }
  }
}

class RPSCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint0 = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0;

    Path path0 = Path();
    path0.moveTo(size.width * 0.0980139, size.height * 0.0651296);
    path0.lineTo(size.width * 0.9040833, size.height * 0.0646574);
    path0.lineTo(size.width * 0.5000139, size.height * 0.9537037);
    path0.lineTo(size.width * 0.0980139, size.height * 0.0651296);
    path0.close();

    canvas.drawPath(path0, paint0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
