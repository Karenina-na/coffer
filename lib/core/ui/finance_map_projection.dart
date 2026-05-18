import 'dart:math' as math;

import 'package:flutter/material.dart';

class FinanceMapProjection {
  const FinanceMapProjection._();

  static const FinanceProjectionFrame frame = FinanceProjectionFrame(
    hemisphereLift: 0.12,
    hemisphereWidthLeft: 1.05,
    hemisphereWidthRight: 0.95,
    northSpan: 0.55,
    southCompressionExponent: 1.0,
    mapSideInset: 0.02,
    mapTopInset: 0.05,
    mapBottomInset: 0.05,
    displayScale: 1.0,
    displayOffsetY: 0.0,
    euroCenterX: 0.50,
    euroCenterY: 0.275,
    euroRadiusX: 0.14,
    euroRadiusY: 0.10,
    euroScaleX: 1.8,
    euroScaleY: 1.6,
  );

  static (double, double) _europeZone((double, double) p) {
    final dx = (p.$1 - frame.euroCenterX) / frame.euroRadiusX;
    final dy = (p.$2 - frame.euroCenterY) / frame.euroRadiusY;
    final d2 = dx * dx + dy * dy;
    if (d2 >= 1.0) return p;
    final w = math.pow(1 - d2, 2).toDouble();
    final tx = frame.euroCenterX + (p.$1 - frame.euroCenterX) * frame.euroScaleX;
    final ty = frame.euroCenterY + (p.$2 - frame.euroCenterY) * frame.euroScaleY;
    return (p.$1 + (tx - p.$1) * w, p.$2 + (ty - p.$2) * w);
  }

  static Offset projectPoint(Size size, (double, double) norm) {
    final w = _europeZone(norm);
    final nx = w.$1.clamp(0.0, 1.0), ny = w.$2.clamp(0.0, 1.0);
    final cx = nx * 2 - 1;

    final sx = math.sin(cx * math.pi / 2);
    final hw = sx < 0 ? frame.hemisphereWidthLeft : frame.hemisphereWidthRight;
    final uw = size.width * (1 - frame.mapSideInset * 2);
    final px = size.width * frame.mapSideInset + uw * (0.5 + sx * 0.5 * hw);

    final lat = _projLat(ny);
    final uh = size.height * (1 - frame.mapTopInset - frame.mapBottomInset);
    double py = size.height * frame.mapTopInset + uh * lat;
    py -= size.height * frame.hemisphereLift * cx.abs() * (1 - lat * 0.25);
    py = (py * frame.displayScale + size.height * frame.displayOffsetY)
        .clamp(0.0, size.height);

    return Offset(px, py);
  }

  static double projectDepth((double, double) norm) {
    final w = _europeZone(norm);
    final cx = w.$1.clamp(0.0, 1.0) * 2 - 1;
    final e = math.cos(cx.abs() * math.pi / 2).clamp(0.0, 1.0);
    return (e * (1 - _projLat(w.$2.clamp(0.0, 1.0)) * 0.55)).clamp(0.0, 1.0);
  }

  static (double, double) get cryptoHubCenter => (0.45, 0.78);
  static double cryptoHubRadius(Size size) => size.width * 0.04;

  static Offset projectCryptoShelf(Size size, int i, int n,
      {double maxValue = 1, double nodeValue = 1}) {
    final (cx, cy) = cryptoHubCenter;
    final a = i / n * math.pi * 2 - math.pi / 2;
    final r = cryptoHubRadius(size) * 0.25;
    return projectPoint(size, (
      cx + r / size.width * math.cos(a),
      cy + r / size.height * math.sin(a),
    ));
  }

  static double? cryptoShelfDividerY(Size size) => null;

  static List<Offset> projectGuide(Size size, double y, {int samples = 24}) =>
      List.generate(samples + 1, (i) => projectPoint(size, (i / samples, y)));

  static double _projLat(double ny) {
    final t = ny.clamp(0.0, 1.0);
    if (t <= 0.5) return math.pow(t / 0.5, 1.05).toDouble() * frame.northSpan;
    final st = (t - 0.5) / 0.5;
    return frame.northSpan +
        math.pow(st, frame.southCompressionExponent).toDouble() * (1 - frame.northSpan);
  }
}

class FinanceProjectionFrame {
  const FinanceProjectionFrame({
    required this.hemisphereLift,
    required this.hemisphereWidthLeft,
    required this.hemisphereWidthRight,
    required this.northSpan,
    required this.southCompressionExponent,
    required this.mapSideInset,
    required this.mapTopInset,
    required this.mapBottomInset,
    this.displayScale = 1.0,
    this.displayOffsetY = 0.0,
    this.euroCenterX = 0.0,
    this.euroCenterY = 0.0,
    this.euroRadiusX = 0.0,
    this.euroRadiusY = 0.0,
    this.euroScaleX = 1.0,
    this.euroScaleY = 1.0,
  });

  final double hemisphereLift;
  final double hemisphereWidthLeft, hemisphereWidthRight;
  final double northSpan, southCompressionExponent;
  final double mapSideInset, mapTopInset, mapBottomInset;
  final double displayScale, displayOffsetY;
  final double euroCenterX, euroCenterY;
  final double euroRadiusX, euroRadiusY;
  final double euroScaleX, euroScaleY;
}
