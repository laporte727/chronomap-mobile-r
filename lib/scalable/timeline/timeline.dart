import 'dart:async';
import 'dart:math';
import 'package:acorn_client/acorn_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'entry.dart';
import 'timeline_utils.dart';

typedef PaintCallback = Function();

class Timeline {
  /// Some aptly named constants for properly aligning the Timeline view.
  static const double lineWidth = 2.0;
  static const double lineSpacing = 10.0;
  static const double depthOffset = lineSpacing + lineWidth;
  static const double edgePadding = 8.0;
  static const double moveSpeed = 10.0;
  static const double moveSpeedInteracting = 40.0;
  static const double deceleration = 3.0;
  static const double gutterLeft = 45.0;//Space to the left of the scale
  static const double edgeRadius = 4.0;
  static const double minChildLength = 50.0;
  static const double bubblesHeight = 30.0;
  static const double bubblePadding = 5.0;
  static const double bubbleTextHeight = 15.0;
  static const double parallax = 100.0;
  static const double initialViewportPadding = 100.0;
  static const double travelViewportPaddingTop = 400.0;
  static const double viewportPaddingTop = 120.0;
  static const double viewportPaddingBottom = 100.0;
  static const int steadyMilliseconds = 500;

  /// The current platform is initialized at boot, to properly initialize
  /// [ScrollPhysics] based on the platform we're on.
  final TargetPlatform _platform;

  double _start = 0.0;
  double _end = 0.0;
  double _renderStart = 0.0;
  double _renderEnd = 0.0;
  double _lastFrameTime = 0.0;
  double _height = 0.0;
  double _firstOnScreenEntryY = 0.0;
  double _lastEntryY = 0.0;
  double _lastOnScreenEntryY = 0.0;
  double _offsetDepth = 0.0;
  double _renderOffsetDepth = 0.0;
  double _labelX = 0.0;
  double _renderLabelX = 0.0;
  double _prevEntryOpacity = 0.0;
  double _timelineToPrevEntry = 0.0;
  double _nextEntryOpacity = 0.0;
  double _timelineToNextEntry = 0.0;
  double _simulationTime = 0.0;
  double _timeMin = 0.0;
  double _timeMax = 0.0;
  final double _gutterWidth = gutterLeft;

  bool _isFrameScheduled = false;
  bool _isInteracting = false;
  bool _isScaling = false;
  bool _isActive = false;
  bool _isSteady = false;


  /// Depending on the current [Platform], different values are initialized
  /// so that they behave properly on iOS&Android.
  ScrollPhysics? _scrollPhysics;

  /// [_scrollPhysics] needs a [ScrollMetrics] value to function.
  ScrollMetrics? _scrollMetrics;
  Simulation? _scrollSimulation;

  EdgeInsets padding = EdgeInsets.zero;
  EdgeInsets devicePadding = EdgeInsets.zero;

  Timer? _steadyTimer;

  ///前の事象次の事象
  /// These references allow to maintain a reference to the next and previous elements
  /// of the Timeline, depending on which elements are currently in focus.
  /// When there's enough space on the top/bottom, the Timeline will render a round button
  /// with an arrow to link to the next/previous element.
  TimelineEntry? _nextEntry;
  TimelineEntry? _renderNextEntry;
  TimelineEntry? _prevEntry;
  TimelineEntry? _renderPrevEntry;

  late List<TickColors> _tickColors;

  /// All the [TimelineEntry]s that are loaded from disk at boot (in [loadFromBundle()]).
  List<TimelineEntry> _entries = [];

  /// Callback set by [TimelineRenderWidget] when adding a reference to this object.
  /// It'll trigger [RenderBox.markNeedsPaint()].
  PaintCallback? onNeedPaint;

  Timeline(this._platform) {
    setViewport(start: 1536.0, end: 3072.0);
  }

  double get renderOffsetDepth => _renderOffsetDepth;
  double get renderLabelX => _renderLabelX;
  double get start => _start;
  double get end => _end;
  double get renderStart => _renderStart;
  double get renderEnd => _renderEnd;
  double get gutterWidth => _gutterWidth;
  double get nextEntryOpacity => _nextEntryOpacity;
  double get prevEntryOpacity => _prevEntryOpacity;
  bool get isInteracting => _isInteracting;
  bool get isActive => _isActive;

  TimelineEntry? get nextEntry => _renderNextEntry;
  TimelineEntry? get prevEntry => _renderPrevEntry;
  List<TimelineEntry> get entries => _entries;
  List<TickColors> get tickColors => _tickColors;

  /// When a scale operation is detected, this setter is called:
  /// e.g. [_TimelineWidgetState.scaleStart()].
  set isInteracting(bool value) {
    if (value != _isInteracting) {
      _isInteracting = value;
      _updateSteady();
    }
  }

  /// Used to detect if the current scaling operation is still happening
  /// during the current frame in [advance()].
  set isScaling(bool value) {
    if (value != _isScaling) {
      _isScaling = value;
      _updateSteady();
    }
  }

  /// Toggle/stop rendering whenever the Timeline is visible or hidden.
  set isActive(bool isIt) {
    if (isIt != _isActive) {
      _isActive = isIt;
      if (_isActive) {
        _startRendering();
      }
    }
  }

  /// Check that the viewport is steady - i.e. no taps, pans, scales or other gestures are being detected.
  void _updateSteady() {
    bool isIt = !_isInteracting && !_isScaling;

    /// If a timer is currently active, dispose it.
    if (_steadyTimer != null) {
      _steadyTimer!.cancel();
      _steadyTimer = null;
    }

    if (isIt) {
      /// If another timer is still needed, recreate it.
      _steadyTimer = Timer(const Duration(milliseconds: steadyMilliseconds), () {
        _steadyTimer = null;
        _isSteady = true;
        _startRendering();
      });
    } else {
      /// Otherwise update the current state and schedule a new frame.
      _isSteady = false;
      _startRendering();
    }
  }

  /// Schedule a new frame.
  void _startRendering() {
    if (!_isFrameScheduled) {
      _isFrameScheduled = true;
      _lastFrameTime = 0.0;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
    }
  }

  double screenPaddingInTime(double padding, double start, double end) {
    return padding / computeScale(start, end);
  }

  /// Compute the viewport scale from the start/end times.
  double computeScale(double start, double end) {
    return _height == 0.0 ? 1.0 : _height / (end - start);
  }

  /// and populate all the [TimelineEntry]s.
  List<Principal> _principal = [];

  List<Principal> get listPrincipal => _principal;

  Future<List<TimelineEntry>> gatherEntries(principal) async {

    _principal = principal;

    List<TimelineEntry> allEntries = [];
    _tickColors = [];

    for (var principal in _principal){

      /// Sanity check.
      /// Create the current entry and fill in the current date if it's
      /// an `material`, or look for the `start` property if it's a `Position` instead.
      /// Some entries will have a `start` element, but not an `end` specified.
      TimelineEntry timelineEntry = TimelineEntry();
      timelineEntry.type = TimelineEntryType.incident;
      dynamic year = principal.point;
      timelineEntry.start = year is int ? year.toDouble() : year;

      TickColors tickColors = TickColors()
        ..long = Colors.black
        ..short = Colors.black
        ..text = Colors.grey
      //..start = timelineEntry.start
        ..screenY = 0.0;

      _tickColors.add(tickColors);

      timelineEntry.end = timelineEntry.start; //消したら怒られた


      /// The label is a brief description for the current entry.
      /// labelの表示
      timelineEntry.name = "${principal.annee} ${principal.affair} ${principal.precise}";

      /// Add this entry to the list.
      allEntries.add(timelineEntry);
    }

    _timeMin = double.maxFinite;
    _timeMax = -double.maxFinite;

    /// List for "root" entries, i.e. entries with no parents.
    _entries = [];

    /// Build up hierarchy (Position are grouped into "Spanning Position" and Events are placed into the Position they belong to).
    /// 消したら表示されない。
    for (TimelineEntry entry in allEntries) {
      if (entry.start < _timeMin) {
        _timeMin = entry.start;
      }
      if (entry.end > _timeMax) {
        _timeMax = entry.end;
      }

      TimelineEntry? parent;
      double minTimeline = double.maxFinite;
      for (TimelineEntry checkEntry in allEntries) {
        if (checkEntry.type == TimelineEntryType.era) {
          double timeline = entry.start - checkEntry.start;
          double timelineEnd = entry.start - checkEntry.end;
          if (timeline > 0 && timelineEnd < 0 && timeline < minTimeline) {
            minTimeline = timeline;
            parent = checkEntry;
          }
        }
      }
      if (parent != null) {
        entry.parent = parent;
        parent.children != [];
        parent.children.add(entry);
      } else {
        /// no parent, so this is a root entry.
        _entries.add(entry);
      }
    }
    return allEntries;
  }

  /// Make sure that while scrolling we're within the correct timeline bounds.
  clampScroll() {
    _scrollMetrics = null;
    _scrollPhysics = null;
    _scrollSimulation = null;

    /// Get measurements values for the current viewport.
    double scale = computeScale(_start, _end);
    double padTop = (devicePadding.top + viewportPaddingTop) / scale;
    double padBottom = (devicePadding.bottom + viewportPaddingBottom) / scale;
    bool fixStart = _start < _timeMin - padTop;
    bool fixEnd = _end > _timeMax + padBottom;

    /// As the scale changes we need to re-solve the right padding
    /// Don't think there's an analytical single solution for this
    /// so we do it in steps approaching the correct answer.
    for (int i = 0; i < 20; i++) {
      double scale = computeScale(_start, _end);
      double padTop = (devicePadding.top + viewportPaddingTop) / scale;
      double padBottom = (devicePadding.bottom + viewportPaddingBottom) / scale;
      if (fixStart) {
        _start = _timeMin - padTop;
      }
      if (fixEnd) {
        _end = _timeMax + padBottom;
      }
    }
    if (_end < _start) {
      _end = _start + _height / scale;
    }

    /// Be sure to reschedule a new frame.
    if (!_isFrameScheduled) {
      _isFrameScheduled = true;
      _lastFrameTime = 0.0;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
    }
  }

  /// This method bounds the current viewport depending on the current start and end positions.
  void setViewport(
      {double start = double.maxFinite,
        bool pad = false,
        double end = double.maxFinite,
        double height = double.maxFinite,
        double velocity = double.maxFinite,
        bool animate = false}) {
    /// Calculate the current height.
    if (height != double.maxFinite) {
      if (_height == 0.0 && _entries.isNotEmpty) {
        double scale = height / (_end - _start);
        _start = _start - padding.top / scale;
        _end = _end + padding.bottom / scale;
      }
      _height = height;
    }

    /// If a value for start&end has been provided, evaluate the top/bottom position
    /// for the current viewport accordingly.
    /// Otherwise build the values separately.
    if (start != double.maxFinite && end != double.maxFinite) {
      _start = start;
      _end = end;
      if (pad && _height != 0.0) {
        double scale = _height / (_end - _start);
        _start = _start - padding.top / scale;
        _end = _end + padding.bottom / scale;
      }
    } else {
      if (start != double.maxFinite) {
        double scale = height / (_end - _start);
        _start = pad ? start - padding.top / scale : start;
      }
      if (end != double.maxFinite) {
        double scale = height / (_end - _start);
        _end = pad ? end + padding.bottom / scale : end;
      }
    }

    /// If a velocity value has been passed, use the [ScrollPhysics] to create
    /// a simulation and perform scrolling natively to the current platform.
    if (velocity != double.maxFinite) {
      double scale = computeScale(_start, _end);
      double padTop =
          (devicePadding.top + viewportPaddingTop) / computeScale(_start, _end);
      double padBottom = (devicePadding.bottom + viewportPaddingBottom) /
          computeScale(_start, _end);
      double rangeMin = (_timeMin - padTop) * scale;
      double rangeMax = (_timeMax + padBottom) * scale - _height;
      if (rangeMax < rangeMin) {
        rangeMax = rangeMin;
      }

      _simulationTime = 0.0;
      if (_platform == TargetPlatform.iOS) {
        _scrollPhysics = const BouncingScrollPhysics();
      } else {
        _scrollPhysics = const ClampingScrollPhysics();
      }
      _scrollMetrics = FixedScrollMetrics(
          minScrollExtent: double.negativeInfinity,
          maxScrollExtent: double.infinity,
          pixels: 0.0,
          viewportDimension: _height,
          axisDirection: AxisDirection.down, devicePixelRatio: 0.0);

      _scrollSimulation =
          _scrollPhysics?.createBallisticSimulation(_scrollMetrics!, velocity);
    }
    if (!animate) {
      _renderStart = start;
      _renderEnd = end;
      advance(0.0, false);
      if (onNeedPaint != null) {
        onNeedPaint!();
      }
    } else if (!_isFrameScheduled) {
      _isFrameScheduled = true;
      _lastFrameTime = 0.0;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
    }
  }

  /// Make sure that all the visible assets are being rendered and advanced
  /// according to the current state of the Timeline.
  void beginFrame(Duration timeStamp) {
    _isFrameScheduled = false;
    final double t =
        timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
    if (_lastFrameTime == 0.0) {
      _lastFrameTime = t;
      _isFrameScheduled = true;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
      return;
    }

    double elapsed = t - _lastFrameTime;
    _lastFrameTime = t;

    if (!advance(elapsed, true) && !_isFrameScheduled) {
      _isFrameScheduled = true;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
    }

    if (onNeedPaint != null) {
      onNeedPaint!();
    }
  }

  TickColors? findTickColors(double screen) {
    for (TickColors color in _tickColors.reversed) {
      if (screen >= color.screenY) {
        return color;
      }
    }

    return screen < _tickColors.first.screenY
        ? _tickColors.first
        : _tickColors.last;
  }

  bool advance(double elapsed, bool animate) {
    if (_height <= 0) {
      /// Done rendering. Need to wait for height.
      return true;
    }

    /// The current scale based on the rendering area.
    double scale = _height / (_renderEnd - _renderStart);

    bool doneRendering = true;
    bool stillScaling = true;

    /// If the Timeline is performing a scroll operation adjust the viewport
    /// based on the elapsed time.
    if (_scrollSimulation != null) {
      doneRendering = false;
      _simulationTime += elapsed;
      double scale = _height / (_end - _start);
      double velocity = _scrollSimulation!.dx(_simulationTime);

      double displace = velocity * elapsed / scale;

      _start -= displace;
      _end -= displace;

      /// If scrolling has terminated, clean up the resources.
      if (_scrollSimulation!.isDone(_simulationTime)) {
        _scrollMetrics = null;
        _scrollPhysics = null;
        _scrollSimulation = null;
      }
    }

    /// Animate movement.
    double speed =
    min(1.0, elapsed * (_isInteracting ? moveSpeedInteracting : moveSpeed));
    double ds = _start - _renderStart;
    double de = _end - _renderEnd;

    /// If the current view is animating, adjust the [_renderStart]/[_renderEnd] based on the interaction speed.
    if (!animate || ((ds * scale).abs() < 1.0 && (de * scale).abs() < 1.0)) {
      stillScaling = false;
      _renderStart = _start;
      _renderEnd = _end;
    } else {
      doneRendering = false;
      _renderStart += ds * speed;
      _renderEnd += de * speed;
    }
    isScaling = stillScaling;

    /// Update scale after changing render range.
    scale = _height / (_renderEnd - _renderStart);

    /// Check all the visible entries and use the helper function [advanceItems()]
    /// to align their state with the elapsed time.
    /// Set all the initial values to defaults so that everything's consistent.
    _lastEntryY = -double.maxFinite;
    _lastOnScreenEntryY = 0.0;
    _firstOnScreenEntryY = double.maxFinite;
    _labelX = 0.0;
    _offsetDepth = 0.0;
    _nextEntry = null;
    _prevEntry = null;
    /// Advance the items hierarchy one level at a time.
    if (_advanceItems(
        _entries, _gutterWidth + lineSpacing, scale, elapsed, animate, 0)) {
      doneRendering = false;
    }

    if (_nextEntryOpacity == 0.0) {
      _renderNextEntry = _nextEntry;
    }

    /// Determine next entry's opacity and interpolate, if needed, towards that value.
    /// 重なって消える機能？
    double targetNextEntryOpacity = _lastOnScreenEntryY > _height / 1.7 ||
        !_isSteady ||
        _timelineToNextEntry < 0.01 ||
        _nextEntry != _renderNextEntry
        ? 0.0
        : 1.0;
    double dt = targetNextEntryOpacity - _nextEntryOpacity;

    if (!animate || dt.abs() < 0.01) {
      _nextEntryOpacity = targetNextEntryOpacity;
    } else {
      doneRendering = false;
      _nextEntryOpacity += dt * min(1.0, elapsed * 10.0);
    }

    if (_prevEntryOpacity == 0.0) {
      _renderPrevEntry = _prevEntry;
    }

    /// Determine previous entry's opacity and interpolate, if needed, towards that value.
    double targetPrevEntryOpacity = _firstOnScreenEntryY < _height / 2.0 ||
        !_isSteady ||
        _timelineToPrevEntry < 0.01 ||
        _prevEntry != _renderPrevEntry
        ? 0.0
        : 1.0;
    dt = targetPrevEntryOpacity - _prevEntryOpacity;

    if (!animate || dt.abs() < 0.01) {
      _prevEntryOpacity = targetPrevEntryOpacity;
    } else {
      doneRendering = false;
      _prevEntryOpacity += dt * min(1.0, elapsed * 10.0);
    }

    /// Interpolate the horizontal position of the label.
    double dl = _labelX - _renderLabelX;
    if (!animate || dl.abs() < 1.0) {
      _renderLabelX = _labelX;
    } else {
      doneRendering = false;
      _renderLabelX += dl * min(1.0, elapsed * 6.0);
    }

    if (_isSteady) {
      double dd = _offsetDepth - renderOffsetDepth;
      if (!animate || dd.abs() * depthOffset < 1.0) {
        _renderOffsetDepth = _offsetDepth;
      } else {
        /// Needs a second run.
        doneRendering = false;
        _renderOffsetDepth += dd * min(1.0, elapsed * 12.0);
      }
    }

    return doneRendering;
  }

  ///吹き出しサイズ
  double bubbleHeight(TimelineEntry entry) {
    return bubblePadding * 4.0 + bubbleTextHeight;
  }

  /// Advance entry [assets] with the current [elapsed] time.
  bool _advanceItems(List<TimelineEntry> items, double x, double scale,
      double elapsed, bool animate, int depth) {
    bool stillAnimating = false;
    double lastEnd = -double.maxFinite;
    for (int i = 0; i < items.length; i++) {
      TimelineEntry item = items[i];

      double start = item.start - _renderStart;
      double end =
      item.type == TimelineEntryType.era ? item.end - _renderStart : start;

      /// Vertical position for this element.
      double y = start * scale;

      ///+pad;
      if (i > 0 && y - lastEnd < edgePadding) {
        y = lastEnd + edgePadding;
      }

      /// Adjust based on current scale value.
      double endY = end * scale;

      ///-pad;
      /// Update the reference to the last found element.
      lastEnd = endY;

      item.length = endY - y;

      /// Calculate the best location for the bubble/label.
      double targetLabelY = y;
      double itemBubbleHeight = bubbleHeight(item);
      double fadeAnimationStart = itemBubbleHeight + bubblePadding / 2.0;
      if (targetLabelY - _lastEntryY < fadeAnimationStart

          /// The best location for our label is occluded, lets see if we can bump it forward...
          &&
          item.type == TimelineEntryType.era &&
          _lastEntryY + fadeAnimationStart < endY) {
        targetLabelY = _lastEntryY + fadeAnimationStart + 0.5;
      }

      /// Determine if the label is in view.
      double targetLabelOpacity =
      targetLabelY - _lastEntryY < fadeAnimationStart ? 0.0 : 1.0;

      /// Debounce labels becoming visible.
      if (targetLabelOpacity > 0.0 && item.targetLabelOpacity != 1.0) {
        item.delayLabel = 0.5;
      }
      item.targetLabelOpacity = targetLabelOpacity;
      if (item.delayLabel > 0.0) {
        targetLabelOpacity = 0.0;
        item.delayLabel -= elapsed;
        stillAnimating = true;
      }

      double dt = targetLabelOpacity - item.labelOpacity;
      if (!animate || dt.abs() < 0.01) {
        item.labelOpacity = targetLabelOpacity;
      } else {
        stillAnimating = true;
        item.labelOpacity += dt * min(1.0, elapsed * 25.0);
      }

      /// Assign current vertical position.
      item.y = y;
      item.endY = endY;

      double targetLegOpacity = item.length > edgeRadius ? 1.0 : 0.0;
      double dtl = targetLegOpacity - item.legOpacity;
      if (!animate || dtl.abs() < 0.01) {
        item.legOpacity = targetLegOpacity;
      } else {
        stillAnimating = true;
        item.legOpacity += dtl * min(1.0, elapsed * 20.0);
      }

      double targetItemOpacity = item.parent != null
          ? item.parent!.length < minChildLength ||
          (item.parent != null && item.parent!.endY < y)
          ? 0.0
          : y > item.parent!.y
          ? 1.0
          : 0.0
          : 1.0;
      dtl = targetItemOpacity - item.opacity;
      if (!animate || dtl.abs() < 0.01) {
        item.opacity = targetItemOpacity;
      } else {
        stillAnimating = true;
        item.opacity += dtl * min(1.0, elapsed * 20.0);
      }

      /// Animate the label position.
      double targetLabelVelocity = targetLabelY - item.labelY;
      double dvy = targetLabelVelocity - item.labelVelocity;
      if (dvy.abs() > _height) {
        item.labelY = targetLabelY;
        item.labelVelocity = 0.0;
      } else {
        item.labelVelocity += dvy * elapsed * 18.0;
        item.labelY += item.labelVelocity * elapsed * 20.0;
      }

      /// Check the final position has been reached, otherwise raise a flag.
      if (animate &&
          (item.labelVelocity.abs() > 0.01 ||
              targetLabelVelocity.abs() > 0.01)) {
        stillAnimating = true;
      }

      if (item.targetLabelOpacity > 0.0) {
        _lastEntryY = targetLabelY;
        if (_lastEntryY < _height && _lastEntryY > devicePadding.top) {
          _lastOnScreenEntryY = _lastEntryY;
          if (_firstOnScreenEntryY == double.maxFinite) {
            _firstOnScreenEntryY = _lastEntryY;
          }
        }
      }

      if (item.type == TimelineEntryType.era &&
          y < 0 &&
          endY > _height &&
          depth > _offsetDepth) {
        _offsetDepth = depth.toDouble();
      }

      /// Check if the bubble is out of view and set the y position to the
      /// target one directly.
      if (y > _height + itemBubbleHeight) {
        item.labelY = y;
        if (_nextEntry == null) {
          _nextEntry = item;
          _timelineToNextEntry = (y - _height) / _height;
        }
      } else if (endY < devicePadding.top) {
        _prevEntry = item;
        _timelineToPrevEntry = ((y - _height) / _height).abs();
      } else if (endY < -itemBubbleHeight) {
        item.labelY = y;
      }

      double lx = x + lineSpacing + lineSpacing;
      if (lx > _labelX) {
        _labelX = lx;
      }

      if (item.isVisible) {
        /// Advance the rest of the hierarchy.
        if (_advanceItems(item.children, x + lineSpacing + lineWidth, scale,
            elapsed, animate, depth + 1)) {
          stillAnimating = true;
        }
      }
    }
    return stillAnimating;
  }
}