import 'package:flutter/material.dart';

import '../menu/menu_data.dart';
import 'entry.dart';
import 'timeline.dart';
import 'render_widget.dart';
import 'timeline_utils.dart';


typedef ShowMenuCallback = Function();
typedef SelectItemCallback = Function(TimelineEntry item);

/// This is the Stateful Widget associated with the Timeline object.
/// It is built from a [focusItem], that is the event the [Timeline] should
/// focus on when it's created.
class TimelineWidget extends StatefulWidget {
  final MenuItemData focusItem;
  final Timeline timeline;
  const TimelineWidget(this.focusItem, this.timeline, {super.key});

  @override
  TimelineWidgetState createState() => TimelineWidgetState();
}

class TimelineWidgetState extends State<TimelineWidget> {
  static const String defaultPositionName = "Timeline";
  static const double topOverlap = 56.0;

  /// These variables are used to calculate the correct viewport for the Timeline
  /// when performing a scaling operation as in [_scaleStart], [_scaleUpdate], [_scaleEnd].
  late Offset _lastFocalPoint;
  double _scaleStartYearStart = -100.0;
  double _scaleStartYearEnd = 100.0;

  /// When touching a bubble on the [Timeline] keep track of which
  /// element has been touched in order to move to the [article_widget].
  TapTarget? _touchedBubble;

  /// Syntactic-sugar-getter.
  Timeline get timeline => widget.timeline;

  /// The following three functions define are the callbacks used by the
  /// [GestureDetector] widget when rendering this widget.
  /// First gather the information regarding the starting point of the scaling operation.
  /// Then perform the update based on the incoming [ScaleUpdateDetails] data,
  /// and pass the relevant information down to the [Timeline], so that it can display
  /// all the relevant information properly.
  void _scaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _scaleStartYearStart = timeline.start;
    _scaleStartYearEnd = timeline.end;
    timeline.isInteracting = true;
    timeline.setViewport(velocity: 0.0, animate: true);
  }

  void _scaleUpdate(ScaleUpdateDetails details) {
    double changeScale = details.scale;
    double scale =
        (_scaleStartYearEnd - _scaleStartYearStart) / context.size!.height;

    double focus = _scaleStartYearStart + details.focalPoint.dy * scale;
    double focalDiff =
        (_scaleStartYearStart + _lastFocalPoint.dy * scale) - focus;
    timeline.setViewport(
        start: focus + (_scaleStartYearStart - focus) / changeScale + focalDiff,
        end: focus + (_scaleStartYearEnd - focus) / changeScale + focalDiff,
        height: context.size!.height,
        animate: true);
  }

  void _scaleEnd(ScaleEndDetails details) {
    timeline.isInteracting = false;
    timeline.setViewport(
        velocity: details.velocity.pixelsPerSecond.dy, animate: true);
  }

  /// The following two callbacks are passed down to the [TimelineRenderWidget] so
  /// that it can pass the information back to this widget.
  onTouchBubble(TapTarget bubble) {
    _touchedBubble = bubble;
  }

  onTouchEntry(TimelineEntry entry) {
  }

  void _tapDown(TapDownDetails details) {
    timeline.setViewport(velocity: 0.0, animate: true);
  }

  /// If the [TimelineRenderWidget] has set the [_touchedBubble] to the currently
  /// touched bubble on the Timeline, upon removing the finger from the screen,
  /// the app will check if the touch operation consists of a zooming operation.
  ///
  /// If it is, adjust the layout accordingly.
  /// Otherwise trigger a [Navigator.push()] for the tapped bubble. This moves
  /// the app into the [ArticleWidget].
  void _tapUp(TapUpDetails details) {
    EdgeInsets devicePadding = MediaQuery.of(context).padding;
    if (_touchedBubble != null) {
      if (_touchedBubble!.zoom) {
        MenuItemData target = MenuItemData.fromEntry(_touchedBubble!.entry);

        timeline.padding = EdgeInsets.only(
            top: topOverlap +
                devicePadding.top +
                target.padTop +
                Timeline.parallax,
            bottom: target.padBottom);
        timeline.setViewport(
            start: target.start, end: target.end, animate: true, pad: true);
      }
    }
  }

  /// When performing a long-press operation, the viewport will be adjusted so that
  /// the visible start and end times will be updated according to the [TimelineEntry]
  /// information. The long-pressed bubble will float to the top of the viewport,
  /// and the viewport will be scaled appropriately.
  void _longPress() {
    EdgeInsets devicePadding = MediaQuery.of(context).padding;
    if (_touchedBubble != null) {
      MenuItemData target = MenuItemData.fromEntry(_touchedBubble!.entry);

      timeline.padding = EdgeInsets.only(
          top: topOverlap +
              devicePadding.top +
              target.padTop +
              Timeline.parallax,
          bottom: target.padBottom);
      timeline.setViewport(
          start: target.start, end: target.end, animate: true, pad: true);
    }
  }

  @override
  initState() {
    super.initState();
    widget.timeline.isActive = true;
  }

  /// Update the current view and change the Timeline header, color and background color,
  @override
  void didUpdateWidget(covariant TimelineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  /// This is a [StatefulWidget] life-cycle method. It's being overridden here
  /// so that we can properly update the [Timeline] widget.
  @override
  deactivate() {
    super.deactivate();
  }

  /// This widget is wrapped in a [Scaffold] to have the classic Material Design visual layout structure.
  /// Then the body of the app is made of a [GestureDetector] to properly handle all the user-input events.
  /// This widget then lays down a [Stack]:
  ///   - [TimelineRenderWidget] renders the actual contents of the Timeline such as the currently visible
  ///   bubbles with their corresponding [FlareWidget]s, the left bar with the ticks, etc.
  ///   - [BackdropFilter] that wraps the top header bar, with the back button, the favorites button, and its coloring.
  @override
  Widget build(BuildContext context) {
    EdgeInsets devicePadding = MediaQuery.of(context).padding;

    return Scaffold(
      body: GestureDetector(
          onLongPress: _longPress,
          onTapDown: _tapDown,
          onScaleStart: _scaleStart,
          onScaleUpdate: _scaleUpdate,
          onScaleEnd: _scaleEnd,
          onTapUp: _tapUp,
          child: Stack(children: <Widget>[
            TimelineRenderWidget(
                timeline: timeline,
                topOverlap: topOverlap + devicePadding.top,
                focusItem: widget.focusItem,
                touchBubble: onTouchBubble,
                touchEntry: onTouchEntry
            ),

            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: devicePadding.top,
                    color: const Color(0x99E9E9E9),
                  ),
                  Container(
                      color: const Color(0x99E9E9E9),
                      height: 56.0,
                      width: double.infinity,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            IconButton(
                              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                              //color: _headerTextColor ?? Colors.black.withOpacity(0.5),
                              alignment: Alignment.centerLeft,
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                widget.timeline.isActive = false;
                                Navigator.of(context).pop();
                              },
                            ),
                            const Text(
                              "SCALABLE VIEW",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 20.0,
                              ),
                            ),
                          ]))
                ])
          ])),
    );
  }
}