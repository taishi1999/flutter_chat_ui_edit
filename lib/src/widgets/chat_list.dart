import 'package:diffutil_dart/diffutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../models/bubble_rtl_alignment.dart';
import 'patched_sliver_animated_list.dart';
import 'state/inherited_chat_theme.dart';
import 'state/inherited_user.dart';
import 'typing_indicator.dart';

/// Animated list that handles automatic animations and pagination.
class ChatList extends StatefulWidget {
  /// Creates a chat list widget.
  const ChatList({
    super.key,
    this.bottomWidget,
    required this.bubbleRtlAlignment,
    this.isLastPage,
    required this.itemBuilder,
    required this.previewMessageBuilder,
    required this.items,
    required this.painter,
    required this.isPenPressed,
    //required this.loadPainter,
    required this.setScrollPosition,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.onEndReached,
    this.onEndReachedThreshold,
    required this.scrollController,
    this.scrollPhysics,
    this.typingIndicatorOptions,
    required this.useTopSafeAreaInset,
  });

  /// A custom widget at the bottom of the list.
  final Widget? bottomWidget;

  /// Used to set alignment of typing indicator.
  /// See [BubbleRtlAlignment].
  final BubbleRtlAlignment bubbleRtlAlignment;

  /// Used for pagination (infinite scroll) together with [onEndReached].
  /// When true, indicates that there are no more pages to load and
  /// pagination will not be triggered.
  final bool? isLastPage;

  final bool isPenPressed;

  /// Item builder.
  final Widget Function(Object, int? index) itemBuilder;

  final Widget Function() previewMessageBuilder;

  /// Items to build.
  final List<Object> items;

  final Container painter;
  final Function setScrollPosition;

  /// Used for pagination (infinite scroll). Called when user scrolls
  /// to the very end of the list (minus [onEndReachedThreshold]).
  final Future<void> Function()? onEndReached;

  /// A representation of how a [ScrollView] should dismiss the on-screen keyboard.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Used for pagination (infinite scroll) together with [onEndReached].
  /// Can be anything from 0 to 1, where 0 is immediate load of the next page
  /// as soon as scroll starts, and 1 is load of the next page only if scrolled
  /// to the very end of the list. Default value is 0.75, e.g. start loading
  /// next page when scrolled through about 3/4 of the available content.
  final double? onEndReachedThreshold;

  /// Scroll controller for the main [CustomScrollView]. Also used to auto scroll
  /// to specific messages.
  final ScrollController scrollController;

  /// Determines the physics of the scroll view.
  final ScrollPhysics? scrollPhysics;

  /// Used to build typing indicator according to options.
  /// See [TypingIndicatorOptions].
  final TypingIndicatorOptions? typingIndicatorOptions;

  /// Whether to use top safe area inset for the list.
  final bool useTopSafeAreaInset;

  @override
  State<ChatList> createState() => _ChatListState();
}

/// [ChatList] widget state.
class _ChatListState extends State<ChatList>
    with SingleTickerProviderStateMixin {
  // late final Animation<double> _animation = CurvedAnimation(
  //   curve: Curves.easeOutQuad,
  //   parent: _controller,
  // );
  //late final AnimationController _controller = AnimationController(vsync: this);

  bool _indicatorOnScrollStatus = false;
  bool _isNextPageLoading = false;
  final GlobalKey<PatchedSliverAnimatedListState> _listKey =
      GlobalKey<PatchedSliverAnimatedListState>();
  late List<Object> _oldData = List.from(widget.items);
  double _topOffset = 0.0;

  final GlobalKey _key = GlobalKey();
  final GlobalKey _emptyListKey = GlobalKey();
  double _height = 0;
  double screenHeight = 0;

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(() {
      setState(() {
        _topOffset = widget.scrollController.offset;
        widget.setScrollPosition(_topOffset);
        //print('topOffset: $_topOffset');
      });
    });

    //WidgetsBinding.instance.addPostFrameCallback((_) {
    // widget.scrollController.animateTo(
    //   MediaQuery.of(context).size.height,
    //   duration: Duration(milliseconds: 1000),
    //   curve: Curves.easeInOut,
    // );
    // widget.scrollController.jumpTo(
    //   MediaQuery.of(context).size.height,
    // );
    //});

    // WidgetsBinding.instance!.addPostFrameCallback((_) {
    //   final RenderBox renderBox =
    //       _emptyListKey.currentContext!.findRenderObject() as RenderBox;
    //   final size = renderBox.size;
    //   print('size: $size');
    // });
    didUpdateWidget(widget);
  }

  @override
  void didUpdateWidget(covariant ChatList oldWidget) {
    super.didUpdateWidget(oldWidget);

    _calculateDiffs(oldWidget.items);
  }

  @override
  void dispose() {
    //_controller.dispose();
    super.dispose();
  }

  final Map<int, GlobalKey> keyMap = {};

  GlobalKey generateKey(int index) {
    return GlobalKey(debugLabel: 'key_$index');
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        //onNotification: (notification) {
        // if (notification.metrics.pixels > 10.0 && !_indicatorOnScrollStatus) {
        //   print('nortitification1');
        //   setState(() {
        //     _indicatorOnScrollStatus = !_indicatorOnScrollStatus;
        //   });
        // } else if (notification.metrics.pixels == 0.0 &&
        //     _indicatorOnScrollStatus) {
        //   print('nortitification2');
        //   setState(() {
        //     _indicatorOnScrollStatus = !_indicatorOnScrollStatus;
        //   });
        // }

        // if (widget.onEndReached == null || widget.isLastPage == true) {
        //   return false;
        // }

        // if (notification.metrics.pixels >=
        //     (notification.metrics.maxScrollExtent *
        //         (widget.onEndReachedThreshold ?? 0.75))) {
        //   if (widget.items.isEmpty || _isNextPageLoading) return false;

        //   // _controller.duration = Duration.zero;
        //   //_controller.forward();

        //   setState(() {
        //     _isNextPageLoading = true;
        //   });

        //   widget.onEndReached!().whenComplete(() {
        //     // _controller.duration = const Duration(milliseconds: 300);
        //     //_controller.reverse();

        //     setState(() {
        //       _isNextPageLoading = false;
        //     });
        //   });
        // }

        // return false;
        //},
        child: Stack(
          //key: _key,
          children: [
            CustomScrollView(
              keyboardDismissBehavior: widget.keyboardDismissBehavior,
              physics: widget.scrollPhysics,
              controller: widget.scrollController,
              reverse: true,
              slivers: [
                // SliverToBoxAdapter(
                //   child: Stack(
                //     children: [
                //       Align(
                //         alignment: Alignment.topCenter,
                //         child: Padding(
                //           padding: const EdgeInsets.symmetric(horizontal: 16.0),
                //           child: ClipRRect(
                //             borderRadius: BorderRadius.circular(10), // 丸みの半径を設定
                //             child: Container(
                //               height: 2.0, // ボーダーの厚さ
                //               //width: MediaQuery.of(context).size.width *0.9, // ボーダーの横幅を70%に設定
                //               color: Colors.grey.shade200, // ボーダーの色
                //             ),
                //           ),
                //         ),
                //       ),
                //       Column(
                //         children: [
                //           widget.previewMessageBuilder(),
                //           Container(
                //             height: MediaQuery.of(context).size.height,
                //           ),
                //         ],
                //       ),
                //     ],
                //   ),
                // ),

                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) {
                      //final message = widget.items[index];
                      return _newMessageBuilder(
                        index,
                        AlwaysStoppedAnimation<double>(1),
                      );
                    },
                    childCount: widget.items.length,
                  ),
                  key: _listKey,
                ),
              ],
            ),
            Positioned(
              top: 0, // Container's position
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 200, // Container's height
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  _getVisibleItems();
                },
                child: Text('Button'),
              ),
            ),
            // Positioned(
            //   top: -500 + _topOffset,
            //   left: 20,
            //   height: 250,
            //   width: 250,
            //   child: Container(
            //     width: 150,
            //     height: 150,
            //     color: Colors.green[300],
            //     child: const Text(
            //       '重ねるウィジェット',
            //       style: TextStyle(color: Colors.white, fontSize: 20),
            //     ),
            //   ),
            // ),

            // ListView.builder(
            //   physics: widget.scrollPhysics,
            //   controller: widget.scrollController,
            //   reverse: true,
            //   padding: const EdgeInsets.only(bottom: 0),
            //   itemCount: widget.items.length,
            //   key: _listKey,
            //   itemBuilder: (_, index) {
            //     //final message = widget.items[index];
            //     return _newMessageBuilder(
            //       index,
            //       AlwaysStoppedAnimation<double>(1),
            //     );
            //   },
            //   findChildIndexCallback: (Key key) {
            //     if (key is ValueKey<Object>) {
            //       final newIndex = widget.items.indexWhere(
            //         (v) => _valueKeyForItem(v) == key,
            //       );
            //       if (newIndex != -1) {
            //         return newIndex;
            //       }
            //     }
            //     return null;
            //   },
            // ),

            // CustomScrollView(
            //   shrinkWrap: true,
            //   controller: _scrollController,
            //   //controller: widget.scrollController,
            //   keyboardDismissBehavior: widget.keyboardDismissBehavior,
            //   physics: widget.scrollPhysics,
            //   reverse: true,
            //   slivers: [
            //     // if (widget.bottomWidget != null)
            //     //   SliverToBoxAdapter(child: widget.bottomWidget),
            //     // SliverPadding(
            //     //   padding: const EdgeInsets.only(bottom: 4),
            //     //   sliver: SliverToBoxAdapter(
            //     //     child:
            //     //         widget.typingIndicatorOptions?.customTypingIndicator ??
            //     //             TypingIndicator(
            //     //               bubbleAlignment: widget.bubbleRtlAlignment,
            //     //               options: widget.typingIndicatorOptions!,
            //     //               showIndicator: (widget.typingIndicatorOptions!
            //     //                       .typingUsers.isNotEmpty &&
            //     //                   !_indicatorOnScrollStatus),
            //     //             ),
            //     //   ),
            //     // ),
            //     // SliverPadding(
            //     //   padding: const EdgeInsets.only(bottom: 4),
            //     //   sliver: SliverToBoxAdapter(
            //     //     child: widget.itemBuilder(_oldData[6], 5),
            //     //   ),
            //     // ),]

            //     SliverToBoxAdapter(
            //       child: Container(
            //         //height: 300,
            //         height: MediaQuery.of(context).size.height,
            //         color: Colors.blue,
            //         child: widget.isPenPressed ? widget.painter : null,
            //       ),
            //     ),
            //     // SliverToBoxAdapter(
            //     //   child: widget.previewMessageBuilder(),
            //     // ),
            //     SliverPadding(
            //       padding: const EdgeInsets.only(bottom: 4),
            //       sliver: PatchedSliverAnimatedList(
            //         findChildIndexCallback: (Key key) {
            //           if (key is ValueKey<Object>) {
            //             final newIndex = widget.items.indexWhere(
            //               (v) => _valueKeyForItem(v) == key,
            //             );
            //             if (newIndex != -1) {
            //               return newIndex;
            //             }
            //           }
            //           return null;
            //         },
            //         initialItemCount: widget.items.length,
            //         key: _listKey,
            //         itemBuilder: (_, index, animation) =>
            //             _newMessageBuilder(index, animation),
            //       ),
            //     ),
            //     // SliverPadding(
            //     //   padding: EdgeInsets.only(
            //     //     top: 16 +
            //     //         (widget.useTopSafeAreaInset
            //     //             ? MediaQuery.of(context).padding.top
            //     //             : 0),
            //     //   ),
            //     //   sliver: SliverToBoxAdapter(
            //     //     child: SizeTransition(
            //     //       axisAlignment: 1,
            //     //       sizeFactor: _animation,
            //     //       child: Center(
            //     //         child: Container(
            //     //           alignment: Alignment.center,
            //     //           height: 32,
            //     //           width: 32,
            //     //           child: SizedBox(
            //     //             height: 16,
            //     //             width: 16,
            //     //             child: _isNextPageLoading
            //     //                 ? CircularProgressIndicator(
            //     //                     backgroundColor: Colors.transparent,
            //     //                     strokeWidth: 1.5,
            //     //                     valueColor: AlwaysStoppedAnimation<Color>(
            //     //                       InheritedChatTheme.of(context)
            //     //                           .theme
            //     //                           .primaryColor,
            //     //                     ),
            //     //                   )
            //     //                 : null,
            //     //           ),
            //     //         ),
            //     //       ),
            //     //     ),
            //     //   ),
            //     // ),
            //   ],
            // ),

            //widget.loadPainter,
            //widget.painter,

            // Container(
            //   // height: 1000,
            //   child: Stack(
            //     fit: StackFit.passthrough,
            //     children: [
            //       widget.loadPainter,
            //       // widget.painter,
            //       // Positioned(
            //       //   top: 200,
            //       //   left: 20,
            //       //   height: 250,
            //       //   width: 250,
            //       // child: Container(
            //       //   width: 150,
            //       //   height: 150,
            //       //   color: Colors.green[300],
            //       //   child: const Text(
            //       //     '重ねるウィジェット',
            //       //     style: TextStyle(color: Colors.white, fontSize: 20),
            //       //   ),
            //       // ),
            //       // ),
            //     ],
            //   ),
            // ),
          ],
        ),
      );

  void _calculateDiffs(List<Object> oldList) async {
    final diffResult = calculateListDiff<Object>(
      oldList,
      widget.items,
      equalityChecker: (item1, item2) {
        if (item1 is Map<String, Object> && item2 is Map<String, Object>) {
          final message1 = item1['message']! as types.Message;
          final message2 = item2['message']! as types.Message;

          return message1.id == message2.id;
        } else {
          return item1 == item2;
        }
      },
    );

    for (final update in diffResult.getUpdates(batch: false)) {
      update.when(
        insert: (pos, count) {
          _listKey.currentState?.insertItem(pos);
        },
        remove: (pos, count) {
          final item = oldList[pos];
          _listKey.currentState?.removeItem(
            pos,
            (_, animation) => _removedMessageBuilder(item, animation),
          );
        },
        change: (pos, payload) {},
        move: (from, to) {},
      );
    }

    _scrollToBottomIfNeeded(oldList);

    _oldData = List.from(widget.items);
  }

  Widget _newMessageBuilder(int index, Animation<double> animation) {
    try {
      final item = _oldData[index];

      final key = keyMap.putIfAbsent(index, () => generateKey(index));

      return SizeTransition(
        key: key,
        //key: _valueKeyForItem(item),
        axisAlignment: -1,
        sizeFactor: animation.drive(CurveTween(curve: Curves.easeOutQuad)),
        child: widget.itemBuilder(item, index),
      );
    } catch (e) {
      return const SizedBox();
    }
  }

  void _getVisibleItems() {
    late bool visibleSwitch = false;
    for (var entry in keyMap.entries) {
      final key = entry.value;
      final index = entry.key;
      final keyContext = key.currentContext;
      if (keyContext == null) continue;

      // Get the RenderBox and check its visibility
      final box = keyContext.findRenderObject() as RenderBox;
      final pos = box.localToGlobal(Offset.zero).dy;
      final isVisible = 300 + 47 + 56 < pos && pos < 500 + 47 + 56;

      //MediaQuery.of(keyContext).size.height;

      //最後に範囲からはみ出た要素を取得するためにvisibleSwitchを使用
      if (isVisible) {
        visibleSwitch = true;
        print("$index, dy: ${box.localToGlobal(Offset.zero).dy}");
      } else {
        if (visibleSwitch) {
          print("Last visible item index: $index, dy: $pos");
          visibleSwitch = false;
        }
      }
    }
  }

  // void _getVisibleItems() {
  //   final visibleItems = <Object>[];

  //   for (final item in _oldData) {
  //     final key = _globalKeyForItem(item);
  //     //final key = _valueKeyForItem(item);
  //     if (key == null) {
  //       print('key = null');
  //       continue;
  //     }

  //     final context = key.currentContext;
  //     if (context == null) {
  //       print('context = null');
  //       continue;
  //     }

  //     final renderBox = context.findRenderObject() as RenderBox;
  //     final position = renderBox.localToGlobal(Offset.zero);
  //     final size = renderBox.size;
  //     print('renderBox: $renderBox');
  //     print('item: $item,');
  //     //print('size: ${size}, position: ${position}');

  //     if (position.dy < MediaQuery.of(context).size.height &&
  //         position.dy + size.height > 0) {
  //       visibleItems.add(item);
  //     }
  //   }

  //   print('Visible items: $visibleItems');
  // }

  Widget _removedMessageBuilder(Object item, Animation<double> animation) =>
      SizeTransition(
        key: _valueKeyForItem(item),
        axisAlignment: -1,
        sizeFactor: animation.drive(CurveTween(curve: Curves.easeInQuad)),
        child: FadeTransition(
          opacity: animation.drive(CurveTween(curve: Curves.easeInQuad)),
          child: widget.itemBuilder(item, null),
        ),
      );

  // Hacky solution to reconsider.
  void _scrollToBottomIfNeeded(List<Object> oldList) {
    try {
      // Take index 1 because there is always a spacer on index 0.
      final oldItem = oldList[1];
      final item = widget.items[1];

      if (oldItem is Map<String, Object> && item is Map<String, Object>) {
        final oldMessage = oldItem['message']! as types.Message;
        final message = item['message']! as types.Message;

        // Compare items to fire only on newly added messages.
        if (oldMessage.id != message.id) {
          // Run only for sent message.
          if (message.author.id == InheritedUser.of(context).user.id) {
            // Delay to give some time for Flutter to calculate new
            // size after new message was added
            Future.delayed(const Duration(milliseconds: 100), () {
              if (widget.scrollController.hasClients) {
                print('widget.scrollController.hasClients');
                widget.scrollController.animateTo(
                  MediaQuery.of(context).size.height,
                  //0,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeInQuad,
                );
              }
            });
          }
        }
      }
    } catch (e) {
      // Do nothing if there are no items.
    }
  }

  Key? _valueKeyForItem(Object item) =>
      _mapMessage(item, (message) => ValueKey(message.id));

  GlobalKey? _globalKeyForItem(Object item) =>
      _mapMessage(item, (message) => GlobalKey(debugLabel: message.id));

  T? _mapMessage<T>(Object maybeMessage, T Function(types.Message) f) {
    if (maybeMessage is Map<String, Object>) {
      print('Item is a Map');
      return f(maybeMessage['message'] as types.Message);
    }
    print('Item is not a Map<String, Object>. Returning null.');
    return null;
  }
}
