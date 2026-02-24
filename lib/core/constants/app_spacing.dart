import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const double cardPadding = 16;
  static const double pagePadding = 20;
  static const double sectionGap = 24;

  static const double cardRadius = 16;
  static const double cardRadiusLg = 20;
  static const double buttonRadius = 14;
  static const double chipRadius = 999;
  static const double inputRadius = 12;

  static const double maxContentWidth = 600;

  static const EdgeInsets pageInsets = EdgeInsets.symmetric(horizontal: pagePadding);
  static const EdgeInsets cardInsets = EdgeInsets.all(cardPadding);
  static const EdgeInsets listInsets = EdgeInsets.fromLTRB(pagePadding, 12, pagePadding, 24);
}
