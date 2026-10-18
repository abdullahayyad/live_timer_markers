import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// How a timer marker looks: colors, text and the shape of the badge.
///
/// The default is an orange pill with white bold text and a small pointer at
/// the bottom that points at the marker's position.
@immutable
class TimerMarkerStyle {
  /// Creates a timer marker style.
  const TimerMarkerStyle({
    this.backgroundColor = const Color(0xFFFF980B),
    this.textColor = const Color(0xFFFFFFFF),
    this.fontSize = 14,
    this.fontWeight = FontWeight.w700,
    this.fontFamily,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.borderRadius = 999,
    this.borderColor,
    this.borderWidth = 0,
    this.pointerSize = const Size(12, 7),
    this.shadowColor = const Color(0x40000000),
    this.shadowBlur = 3,
  })  : assert(fontSize > 0),
        assert(borderRadius >= 0),
        assert(borderWidth >= 0),
        assert(shadowBlur >= 0);

  /// The fill color of the badge.
  final Color backgroundColor;

  /// The color of the timer text.
  final Color textColor;

  /// The size of the timer text, in logical pixels.
  final double fontSize;

  /// The weight of the timer text.
  final FontWeight fontWeight;

  /// The font of the timer text. Uses the platform font when null.
  final String? fontFamily;

  /// The space between the text and the edge of the badge.
  final EdgeInsets padding;

  /// The corner radius of the badge. Large values give a pill shape.
  final double borderRadius;

  /// The color of the outline around the badge. No outline when null.
  final Color? borderColor;

  /// The width of the outline around the badge.
  final double borderWidth;

  /// The width and height of the pointer under the badge.
  ///
  /// Use [Size.zero] for a badge without a pointer.
  final Size pointerSize;

  /// The color of the shadow under the badge.
  final Color shadowColor;

  /// How soft the shadow is. Set it to 0 to turn the shadow off.
  final double shadowBlur;

  /// Returns a copy of this style with the given fields replaced.
  TimerMarkerStyle copyWith({
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
    FontWeight? fontWeight,
    String? fontFamily,
    EdgeInsets? padding,
    double? borderRadius,
    Color? borderColor,
    double? borderWidth,
    Size? pointerSize,
    Color? shadowColor,
    double? shadowBlur,
  }) {
    return TimerMarkerStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontFamily: fontFamily ?? this.fontFamily,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      pointerSize: pointerSize ?? this.pointerSize,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TimerMarkerStyle &&
        other.backgroundColor == backgroundColor &&
        other.textColor == textColor &&
        other.fontSize == fontSize &&
        other.fontWeight == fontWeight &&
        other.fontFamily == fontFamily &&
        other.padding == padding &&
        other.borderRadius == borderRadius &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.pointerSize == pointerSize &&
        other.shadowColor == shadowColor &&
        other.shadowBlur == shadowBlur;
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        textColor,
        fontSize,
        fontWeight,
        fontFamily,
        padding,
        borderRadius,
        borderColor,
        borderWidth,
        pointerSize,
        shadowColor,
        shadowBlur,
      );
}
