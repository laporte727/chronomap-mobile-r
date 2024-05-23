import 'dart:ui';
import 'entry.dart';

class TickColors {

  late Color long;
  late Color short;
  late Color text;
  late double start;
  late double screenY;
}

class TapTarget {
  late TimelineEntry entry;
  late Rect rect;
  bool zoom = false;
}