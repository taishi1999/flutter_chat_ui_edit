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
import 'package:vector_math/vector_math_64.dart' as vec;

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
  });

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

  final VoidCallback? onPenPressed;

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
  bool _isTextEditorVisible = false;
  bool _isPainterVisible = false;

  bool isScrollable = true;

  bool _isInputVisible = true;
  bool _finished = false;
  bool isTouching = false;

  Offset _offset = Offset.zero;
  Offset center = Offset(0, 0);
  double _scrollPosition = 0;
  List<Widget> widgetList = [];

  late String _screenText = '';
  GlobalKey containerKey = GlobalKey();

  /// Keep track of all the auto scroll indices by their respective message's id to allow animating to them.
  final Map<String, int> _autoScrollIndexById = {};
  late final AutoScrollController _scrollController;

  PainterController _controller = _newController();

  static PainterController _newController() {
    PainterController controller = new PainterController();
    //太さ
    controller.thickness = 5.0;
    controller.backgroundColor = Colors.transparent;
    return controller;
  }

  @override
  void initState() {
    super.initState();

    _scrollController = widget.scrollController ?? AutoScrollController();
    //bottomInsets = MediaQuery.of(context).viewInsets.bottom;
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

  /// Scroll to the unread header.
  void scrollToUnreadHeader() {
    final unreadHeaderIndex = _autoScrollIndexById[_unreadHeaderId];
    if (unreadHeaderIndex != null) {
      _scrollController.scrollToIndex(
        unreadHeaderIndex,
        duration: widget.scrollToUnreadOptions.scrollDuration,
      );
    }
  }

  /// Scroll to the message with the specified [id].
  void scrollToMessage(String id, {Duration? duration}) =>
      _scrollController.scrollToIndex(
        _autoScrollIndexById[id]!,
        duration: duration ?? scrollAnimationDuration,
      );

  void _onPanStart() {
    setState(() {
      _controller.isEmpty = false;
      isTouching = true;
    });
  }

  void _onPanEnd() {
    setState(() {
      isTouching = false;
    });
  }

  void _onTap() {
    final RenderBox containerRenderBox =
        containerKey.currentContext!.findRenderObject() as RenderBox;
    Size TextContainerSize = containerRenderBox.size;

    FocusManager.instance.primaryFocus?.unfocus();

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset center = box.size.center(Offset.zero);

    _offset = Offset(
      center.dx - TextContainerSize.width / 2,
      center.dy + _scrollPosition - TextContainerSize.height / 2,
    );
    print('_offset: $_offset, TextContainerSize: $TextContainerSize');
    addNewWidget(_offset, _screenText, TextContainerSize);

    setState(() {
      isScrollable = true;
      _isTextEditorVisible = false;

      _screenText = '';
    });
  }

  void addNewWidget(Offset centerPosition, String text, Size size) {
    if (text != '') {
      setState(() {
        widgetList.add(_buildMovableWidget(centerPosition, text, size));
      });
    }
  }

  void moveToLastIndex(int index) {
    setState(() {
      Widget selectWidget = widgetList.removeAt(index);
      widgetList.add(selectWidget);
    });
  }

  void _unfocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Widget _buildMovableWidget(Offset centerPosition, String text, Size size) {
    GlobalKey key = GlobalKey();
    Offset initPosition = centerPosition;
    Size initSize = size;
    return MovableWidget(
      key: key,
      initPos: initPosition,
      initSize: initSize,
      onMoved: (newPos) {
        int index = widgetList.indexWhere((element) => element.key == key);
        if (index != -1) {
          setState(() {
            widgetList[index] = MovableWidget(
              key: key, // Use the same key as before
              initPos: newPos,
              initSize: Size.zero,
              onMoved: (newPosition) {},
              onSelected: () {
                int index =
                    widgetList.indexWhere((element) => element.key == key);
                moveToLastIndex(index);
              },
              Enteredtext: text,
              onMoveStart: (bool) {
                setState(() {
                  isScrollable = bool;
                });
              },
            );
          });
        }
      },
      onSelected: () {
        int index = widgetList.indexWhere((element) => element.key == key);
        moveToLastIndex(index);
      },
      Enteredtext: text,
      onMoveStart: (bool) {
        setState(() {
          isScrollable = bool;
        });
      },
    );
  }

  Widget _buildStack() {
    return Stack(
      children: widgetList,
    );
  }

  bool _isChange = false;
  bool _showIndicator = false;
  int _emptySelectedBorder = 1;

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
                      Flexible(
                        child: widget.messages.isEmpty
                            ? SizedBox.expand(
                                child: _emptyStateBuilder(),
                              )
                            : Stack(
                                children: [
                                  GestureDetector(
                                    // onTap: () {
                                    // FocusManager.instance.primaryFocus
                                    //     ?.unfocus();
                                    //   widget.onBackgroundTap?.call();

                                    //   print('chat.dart: tap');
                                    // },
                                    // onDoubleTap: () {
                                    //   FocusManager.instance.primaryFocus
                                    //       ?.unfocus();
                                    //   setState(() {
                                    //     isScrollable = false;
                                    //     //_scrollPosition=ChatList().scrollController.offset;
                                    //   });
                                    //   print('doubletap');
                                    // },
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
                                        itemBuilder:
                                            (Object item, int? index) =>
                                                _messageBuilder(
                                          item,
                                          constraints,
                                          index,
                                        ),
                                        items: _chatMessages,
                                        widgetList: widgetList,
                                        isScrollable: isScrollable,
                                        //screenText: _screenText,
                                        onTap: _onTap,
                                        onDoubleTap: (scrollpositon) {
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                          setState(() {
                                            _scrollPosition = scrollpositon;
                                            isScrollable = false;
                                            _isTextEditorVisible = true;
                                            //_scrollPosition=ChatList().scrollController.offset;
                                          });
                                          print(
                                              'scrollpositon: $scrollpositon　だよーーーーん,isScrollable: $isScrollable');
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
                                            widget.useTopSafeAreaInset ??
                                                isMobile,
                                      ),
                                    ),
                                  ),

                                  // --- MovableWidgetを動かすようのコード ---
                                  // GestureDetector(
                                  //   onScaleStart: (details) {
                                  //     _initialFocalPoint = details.focalPoint;
                                  //     _initialScale = _scale;
                                  //     _initialRotate = _radians;
                                  //   },
                                  //   onScaleUpdate: (details) {
                                  //     double relativePlusRadian =
                                  //         (details.rotation + 2 * pi) %
                                  //             (2 * pi);
                                  //     double AbsolutePlusRadian =
                                  //         ((_initialRotate +
                                  //                     relativePlusRadian) +
                                  //                 2 * pi) %
                                  //             (2 * pi);
                                  //     double angle =
                                  //         vec.degrees(AbsolutePlusRadian);
                                  //     //if (isSelected) {
                                  //     setState(() {
                                  //       _sessionOffset = details.focalPoint -
                                  //           _initialFocalPoint;
                                  //       //_disableScroll = true;
                                  //       _scale = _initialScale * details.scale;
                                  //       _radians =
                                  //           _initialRotate + details.rotation;
                                  //       isSelected = true;

                                  //       if (angle <= threshold ||
                                  //           angle >= 360 - threshold) {
                                  //         _radians = 0;
                                  //       }
                                  //       // position = Offset(
                                  //       //   position.dx + details.delta.dx,
                                  //       //   position.dy + details.delta.dy,
                                  //       // );
                                  //     });

                                  //     //}
                                  //   },
                                  //   onScaleEnd: (details) {
                                  //     setState(() {
                                  //       position += _sessionOffset;
                                  //       _sessionOffset = Offset.zero;
                                  //     });
                                  //   },
                                  // ),
                                  // --- MovableWidgetを動かすようのコード ---

                                  Visibility(
                                    visible: _isTextEditorVisible,
                                    child: Center(
                                      child: Opacity(
                                        opacity: 0,
                                        child: Container(
                                          key: containerKey,
                                          color: Colors.transparent,

                                          //constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),

                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  width: 1,
                                                  color: Colors.green,
                                                ),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                child: Text(
                                                  _screenText,
                                                  style: TextStyle(
                                                    fontSize: 32,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  //Textfield
                                  Visibility(
                                    visible: _isTextEditorVisible,
                                    child: Stack(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            _onTap();
                                          },
                                        ),
                                        Center(
                                          child: Container(
                                            // decoration: BoxDecoration(
                                            //   border: Border.all(
                                            //     width: 1,
                                            //     color: Colors.black
                                            //         .withOpacity(0.2),
                                            //   ),
                                            // ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              child: Container(
                                                // decoration: BoxDecoration(
                                                //   border: Border.all(
                                                //     width: 1,
                                                //     color: Colors.black.withOpacity(0.2),
                                                //   ),
                                                // ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: IntrinsicWidth(
                                                    //stepWidth: double.parse('2'),
                                                    child: TextField(
                                                      keyboardType:
                                                          TextInputType
                                                              .multiline,
                                                      maxLines: null,
                                                      decoration:
                                                          InputDecoration(
                                                        enabledBorder:
                                                            InputBorder.none,
                                                        focusedBorder:
                                                            InputBorder.none,
                                                        //hintText: 'Enter text',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                      autofocus: true,
                                                      style: TextStyle(
                                                          fontSize: 32),
                                                      onChanged: (value) {
                                                        //print('bottomInsets: $bottomInsets');
                                                        setState(() {
                                                          _screenText = value;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      Visibility(
                        visible: !_isPainterVisible,
                        child: widget.customBottomWidget ??
                            Input(
                              isAttachmentUploading:
                                  widget.isAttachmentUploading,
                              onAttachmentPressed: widget.onAttachmentPressed,
                              onPenPressed: () {
                                //お絵描きPainter表示
                                _onPenPressed();
                                //mainのAppBar非表示
                                widget.onPenPressed?.call();
                              },
                              onSendPressed: widget.onSendPressed,
                              options: widget.inputOptions,
                            ),
                      ),
                    ],
                  ),
                ),

                // --- painter ---
                Visibility(
                  visible: _isPainterVisible,
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    extendBodyBehindAppBar: true,
                    body: Stack(
                      children: [
                        Center(
                          child:
                              new Painter(_controller, _onPanStart, _onPanEnd),
                        ),
                        StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          return RotatedBox(
                            quarterTurns: 3,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                height: 15,
                                width: 200,
                                //color: Colors.green,
                                child: Slider(
                                  value: _controller.thickness,
                                  onChanged: (double value) => setState(() {
                                    _controller.thickness = value;
                                  }),
                                  min: 2.0,
                                  max: 25.0,
                                  activeColor: Colors.black.withOpacity(0.4),
                                  inactiveColor: Colors.black.withOpacity(0.2),
                                  thumbColor: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }),
                        AnimatedOpacity(
                          opacity: isTouching ? 0.0 : 1.0,
                          duration: Duration(milliseconds: 150),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                              width: MediaQuery.of(context).size.width,
                              height: 64,
                              //color: Colors.blueGrey,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                //crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  TextButton(
                                    style: ButtonStyle(
                                      overlayColor:
                                          MaterialStateProperty.all<Color>(
                                        Colors.white.withOpacity(0.2),
                                      ),
                                      foregroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.white),
                                    ),
                                    onPressed: () {
                                      _controller.clear();
                                      _onPenPressed();
                                      widget.onPenPressed?.call();
                                    },
                                    child: Text(
                                      'キャンセル',
                                      style: TextStyle(
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
                                      IconButton(
                                        //enable: !_controller.isEmpty,
                                        icon: Icon(
                                          Icons.undo,
                                          color: _controller.isEmpty
                                              ? Colors.grey
                                              : Colors.white,
                                          shadows: [
                                            BoxShadow(
                                              color: Colors.black, //色
                                              blurRadius: 10, //ぼやけ具合
                                            ),
                                          ],
                                        ),
                                        tooltip: 'Undo',
                                        onPressed: _controller.isEmpty
                                            ? null
                                            : () {
                                                _controller.undo();
                                                setState(() {
                                                  _controller.isUndoPathEmpty =
                                                      false;
                                                });
                                                if (_controller.isEmpty) {
                                                  print('undoでnullになったよ');
                                                  setState(() {
                                                    _controller.isEmpty = true;
                                                  });
                                                }
                                              },
                                      ),
                                      IconButton(
                                        //enable: !_controller.isEmpty,
                                        icon: Icon(
                                          Icons.redo,
                                          color: _controller.isUndoPathEmpty
                                              ? Colors.grey
                                              : Colors.white,
                                          shadows: [
                                            BoxShadow(
                                              //color: Colors.black, //色
                                              blurRadius: 10, //ぼやけ具合
                                            ),
                                          ],
                                        ),
                                        tooltip: 'Redo',
                                        onPressed: _controller.isUndoPathEmpty
                                            ? null
                                            : () {
                                                _controller.redo();
                                                setState(() {
                                                  _controller.isEmpty = false;
                                                });
                                                if (_controller
                                                    .isUndoPathEmpty) {
                                                  print('redoでnullになったよ!');
                                                  setState(() {
                                                    _controller
                                                        .isUndoPathEmpty = true;
                                                  });
                                                }
                                              },
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    style: ButtonStyle(
                                      overlayColor:
                                          MaterialStateProperty.all<Color>(
                                        Colors.white.withOpacity(0.2),
                                      ),
                                      foregroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.white),
                                    ),
                                    onPressed: () {
                                      //
                                      _onPenPressed();
                                      _show();
                                      widget.onPenPressed?.call();
                                    },
                                    child: Text(
                                      '完了',
                                      style: TextStyle(
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
                        AnimatedOpacity(
                          opacity: isTouching ? 0.0 : 1.0,
                          duration: Duration(milliseconds: 150),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 64,
                              //color: Colors.blueGrey,
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  //crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    ..._colorList!.map((color) {
                                      final int index =
                                          _colorList!.indexOf(color);

                                      return AnimatedOnTapButton(
                                        onTap: () {
                                          _controller.drawColor =
                                              _colorList![index];
                                          setState(() {
                                            _emptySelectedBorder = index;
                                          });
                                          print(
                                              'showSelectedBorder: $_emptySelectedBorder');
                                          // if (controlProvider.isPainting) {
                                          //   paintingProvider.lineColor = index;
                                          // } else {
                                          //   editorProvider.textColor = index;
                                          // }
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8),
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
                                              border:
                                                  _emptySelectedBorder == index
                                                      ? returnBorder(index)
                                                      : Border.all(
                                                          color: Colors.white,
                                                          width: 2),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // --- painter ---

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
            margin: widget.theme.dateDividerMargin,
            child: Text(
              object.text,
              style: widget.theme.dateDividerTextStyle,
            ),
          );
    } else if (object is MessageSpacer) {
      return SizedBox(
        height: object.height,
      );
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
                ? min(constraints.maxWidth * 0.72, 440).floor()
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

      return AutoScrollTag(
        controller: _scrollController,
        index: index ?? -1,
        key: Key('scroll-${message.id}'),
        child: messageWidget,
      );
    }
  }

  Border? returnBorder(int i) {
    if (_emptySelectedBorder == 0) {
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
    setState(() {
      _isPainterVisible = !_isPainterVisible;
      //_isInputVisible = !_isInputVisible;
    });
    //widget.onPenPressed;
    print('_isPainterVisible: $_isPainterVisible');
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

class MovableWidget extends StatefulWidget {
  final Offset initPos;
  final Size initSize;
  final Function(Offset) onMoved;
  final Function onSelected;
  String Enteredtext = '';
  final Function(bool) onMoveStart;

  MovableWidget(
      {required Key key,
      required this.initPos,
      required this.initSize,
      required this.onMoved,
      required this.onSelected,
      required this.Enteredtext,
      required this.onMoveStart})
      : super(key: key);

  @override
  _MovableWidgetState createState() => _MovableWidgetState();
}

class _MovableWidgetState extends State<MovableWidget> {
  Offset position = Offset.zero;
  Size size = Size.zero;
  bool isSelected = true;
  String enteredtext = '';
  //Offset _offset = Offset.zero;
  //Offset _offset = Offset(100, 200);
  Offset _initialFocalPoint = Offset.zero;
  Offset _sessionOffset = Offset.zero;

  double _scale = 1.0;
  double _initialScale = 1.0;
  double _radians = 0.0;
  double _initialRotate = 0.0;

  double threshold = 10;

  double _top = 0;
  double _left = 0;

  bool is2fingers = false;

  Widget _toolCase(Widget child) {
    return Container(
      width: 24,
      height: 24,
      child: IconTheme(
        data: Theme.of(context).iconTheme.copyWith(
              color: Colors.white,
              size: 24 * 0.6,
            ),
        child: child,
      ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    position = widget.initPos;
    size = widget.initSize;
    enteredtext = widget.Enteredtext;
    position += Offset(size.width / 2, size.height / 2);
    _instances.add(this);

    // Reset isSelected for all other MovableWidgets
    //print('widget.key: $k');
    _MovableWidgetState.resetSelectionExcept(widget.key as Key);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: (position + _sessionOffset).dx - size.width / 2 * _scale + _left,
      top: (position + _sessionOffset).dy - size.height / 2 * _scale + _top,
      child: Transform.rotate(
        angle: _radians,
        child: Stack(
          children: [
            Container(
              width: size.width * _scale,
              height: size.height * _scale,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  //constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 1,
                      color: isSelected ? Colors.grey : Colors.transparent,
                    ),
                  ),
                  child: Listener(
                    onPointerDown: (event) {
                      if (!is2fingers) {
                        setState(() {
                          isSelected = true;
                          //isScrollable = false;
                        });

                        // Reset isSelected for all other MovableWidgets
                        var k = widget.key;
                        print('widget.key: $k');
                        widget.onSelected();
                        _MovableWidgetState.resetSelectionExcept(
                            widget.key as Key);

                        //scroll無効化
                        widget.onMoveStart(false);
                        print('onpointerdown');
                      } else {
                        print('pointerCount: ${event.pointer}');
                      }
                    },
                    onPointerMove: (details) {
                      if (!is2fingers) {
                        setState(() {
                          _top += details.delta.dy;
                          _left += details.delta.dx;
                          print('_top: $_top');
                        });
                      }
                    },
                    onPointerUp: (details) {
                      if (!is2fingers) {
                        //scroll無効化
                        widget.onMoveStart(true);
                      }
                      // setState(() {
                      //   _scrollable = true;
                      // });
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // onTapDown: (details) {
                      //   setState(() {
                      //     isSelected = true;
                      //   });
                      //   // Reset isSelected for all other MovableWidgets
                      //   var k = widget.key;
                      //   print('widget.key: $k');
                      //   widget.onSelected();
                      //   _MovableWidgetState.resetSelectionExcept(
                      //       widget.key as Key);
                      // },
                      onScaleStart: (details) {
                        if (details.pointerCount == 2) {
                          _initialFocalPoint = details.focalPoint;
                          _initialScale = _scale;
                          _initialRotate = _radians;
                          //widget.onMoveStart();
                          widget.onMoved(position);
                          widget.onSelected();
                          _MovableWidgetState.resetSelectionExcept(
                              widget.key as Key);

                          is2fingers = true;
                        }
                      },
                      onScaleUpdate: (details) {
                        if (details.pointerCount == 2) {
                          double relativePlusRadian =
                              (details.rotation + 2 * pi) % (2 * pi);
                          double AbsolutePlusRadian =
                              ((_initialRotate + relativePlusRadian) + 2 * pi) %
                                  (2 * pi);
                          double angle = vec.degrees(AbsolutePlusRadian);
                          //if (isSelected) {
                          setState(() {
                            _sessionOffset =
                                details.focalPoint - _initialFocalPoint;
                            //_disableScroll = true;
                            _scale = _initialScale * details.scale;
                            _radians = _initialRotate + details.rotation;
                            isSelected = true;

                            if (angle <= threshold ||
                                angle >= 360 - threshold) {
                              _radians = 0;
                            }
                            // position = Offset(
                            //   position.dx + details.delta.dx,
                            //   position.dy + details.delta.dy,
                            // );
                          });

                          //}
                        }
                      },
                      onScaleEnd: (details) {
                        setState(() {
                          position += _sessionOffset;
                          _sessionOffset = Offset.zero;

                          is2fingers = false;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(),
                          child: FittedBox(
                            child: Text(
                              enteredtext,
                            ),
                          ),
                          // child: FittedBox(
                          //   fit: BoxFit.fill,
                          //   child: Text(
                          //     enteredtext,
                          //   ),
                          // ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 1,
              left: 1,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  //onTap: () => widget.onDel?.call(),
                  child: isSelected
                      ? _toolCase(const Icon(Icons.clear))
                      : Container(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void resetSelectionExcept(Key key) {
    print('Key: $key');
    _MovableWidgetState.instances
        .where((movableWidget) => movableWidget.widget.key != key)
        .forEach((movableWidget) => movableWidget.deselect(key));
  }

  void deselect(Key key) {
    //print('選択されてないKey: $key');
    setState(() {
      isSelected = false;
    });
  }

  static Iterable<_MovableWidgetState> get instances => _instances;

  static final List<_MovableWidgetState> _instances = [];

  @override
  void dispose() {
    _instances.remove(this);
    super.dispose();
  }
}
