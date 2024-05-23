import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'timeline.dart';
import 'timeline_utils.dart';


/// This class is used by the [TimelineRenderWidget] to render the ticks on the left side of the screen.
/// It has a single [paint()] method that's called within [TimelineRenderObject.paint()].
class Ticks {
  /// The following `const` variables are used to properly align, pad and layout the ticks
  /// on the left side of the Timeline.
  static const double margin = 20.0;
  static const double width = 40.0;
  static const double labelPadLeft = 5.0;
  static const double labelPadRight = 1.0;
  static const int ticksDistance = 16;
  static const int textsTickDistance = 64;
  static const double tickSize = 15.0;
  static const double smallTickSize = 5.0;

  /// Other than providing the [PaintingContext] to allow the ticks to paint themselves,
  /// other relevant sizing information is passed to this `paint()` method, as well as
  /// a reference to the [Timeline].
  void paint(PaintingContext context, Offset offset, double translation,
      double scale, double height, Timeline timeline) {
    final Canvas canvas = context.canvas;

    double bottom = height;
    double tickDistance = ticksDistance

        .toDouble();
    double textTickDistance = textsTickDistance.toDouble();

    /// The width of the left panel can expand and contract if the favorites-view is activated,
    /// by pressing the button on the top-right corner of the Timeline.
    /// ただしこのアプリにfavorites機能はない でも計算に使う
    double gutterWidth = timeline.gutterWidth;

    /// Calculate spacing based on current scale
    double scaledTickDistance = tickDistance * scale;
    if (scaledTickDistance > 2 * ticksDistance) {
      while (scaledTickDistance > 2 * ticksDistance && tickDistance >= 2.0) {
        scaledTickDistance /= 2.0;
        tickDistance /= 2.0;
        textTickDistance /= 2.0;
      }
    } else {
      while (scaledTickDistance < ticksDistance) {
        scaledTickDistance *= 2.0;
        tickDistance *= 2.0;
        textTickDistance *= 2.0;
      }
    }

    /// The number of ticks to draw.
    int numTicks = (height / scaledTickDistance).ceil() + 2;
    if (scaledTickDistance > textsTickDistance) {
      textTickDistance = tickDistance;
    }

    /// Figure out the position of the top left corner of the screen
    double tickOffset = 0.0;
    double startingTickMarkValue = 0.0;
    double y = ((translation - bottom) / scale);
    startingTickMarkValue = y - (y % tickDistance);
    tickOffset = -(y % tickDistance) * scale - scaledTickDistance;

    /// Move back by one tick.
    tickOffset -= scaledTickDistance;
    startingTickMarkValue -= tickDistance;

    double s =
    timeline.computeScale(timeline.renderStart, timeline.renderEnd);

    /// y-coordinate for the starting and ending element.
    double y1 = timeline.renderStart * s;
    double y2 = timeline.renderStart * s;


    /// Fill in top/bottom if necessary.
    if (y1 > offset.dy) {
      canvas.drawRect(
          Rect.fromLTWH(
              offset.dx, offset.dy, gutterWidth, y1 - offset.dy + 1.0),
          ui.Paint());
    }
    if (y2 < offset.dy + height) {
      canvas.drawRect(
          Rect.fromLTWH(
              offset.dx, y2 - 1, gutterWidth, (offset.dy + height) - y2),
          ui.Paint());
    }

    /// Draw the gutter.
    canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, gutterWidth, height),
        Paint()..color = const Color.fromRGBO(246, 246, 246, 0.95));
    //}

    ///文字の描画？
    Set<String> usedValues = <String>{};

    /// Draw all the ticks.
    for (int i = 0; i < numTicks; i++) {
      tickOffset += scaledTickDistance;

      int tt = startingTickMarkValue.round();
      tt = -tt;
      int o = tickOffset.floor();
      TickColors? colors = timeline.findTickColors(offset.dy + height - o);
      if (tt % textTickDistance == 0) {
        /// Every `textTickDistance`, draw a wider tick with the a label laid on top.
        canvas.drawRect(
            Rect.fromLTWH(offset.dx + gutterWidth - tickSize,
                offset.dy + height - o, tickSize, 1.0),
            Paint()..color = colors!.long);

        /// Drawing text to [canvas] is done by using the [ParagraphBuilder] directly.
        ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(
            textAlign: TextAlign.end,/* fontFamily: "Roboto", */fontSize: 10.0))
          ..pushStyle(ui.TextStyle(color: colors.text));

        int value = tt.round().abs();

        /// Format the label nicely depending on how long ago the tick is placed at.
        String label;
        if (value < 9000) {
          label = value.toStringAsFixed(0);
        } else {
          NumberFormat formatter = NumberFormat.compact();
          label = formatter.format(value);
          int? digits = formatter.minimumSignificantDigits;
          while (usedValues.contains(label) && digits! < 10) {
            formatter.minimumSignificantDigits = ++digits;
            label = formatter.format(value);
          }
        }
        usedValues.add(label);
        builder.addText(label);
        ui.Paragraph tickParagraph = builder.build();
        tickParagraph.layout(ui.ParagraphConstraints(
            width: gutterWidth - labelPadLeft - labelPadRight));
        canvas.drawParagraph(
            tickParagraph,
            Offset(offset.dx + labelPadLeft - labelPadRight,
                offset.dy + height - o - tickParagraph.height - 5));
      } else {
        /// If we're within two text-ticks, just draw a smaller line.
        canvas.drawRect(
            Rect.fromLTWH(offset.dx + gutterWidth - smallTickSize,
                offset.dy + height - o, smallTickSize, 1.0),
            Paint()..color = colors!.short);
      }
      startingTickMarkValue += tickDistance;
    }
  }
}