import 'package:flutter/material.dart';

/// A single source of truth for spacing, radii and elevation.
///
/// Using a 4pt base grid keeps layouts visually consistent without
/// introducing a design-token framework.
class Spacing {
  const Spacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Standard horizontal page padding.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: lg);

  /// Page padding that also leaves room for the bottom navigation bar.
  static const EdgeInsets pageWithBottom = EdgeInsets.fromLTRB(
    lg,
    lg,
    lg,
    xxxl,
  );
}

/// Corner radii. Deadline favours restrained rounding — 12–16dp, not pills.
class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double sheet = 24;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// Elevation is used sparingly: cards use a hairline border plus a *very*
/// soft shadow rather than heavy Material elevation.
class AppElevation {
  const AppElevation._();

  static const double none = 0;
  static const double card = 1;
  static const double raised = 3;

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
}
