import 'dart:math' as math;

import 'package:flutter/material.dart';

class FinanceMapProjection {
  const FinanceMapProjection._();

  static const FinanceDistortionModel defaultModel = FinanceDistortionModel(
    frame: FinanceProjectionFrame(
      hemisphereWidth: 0.94,
      hemisphereLift: 0.07,
      northBiasExponent: 1.06,
      southCompressionExponent: 0.82,
      northSpan: 0.78,
      mapSideInset: 0.02,
      mapTopInset: 0.11,
      mapBottomInset: 0.06,
    ),
    zones: [
      FinanceFocusZone.northAtlanticCompression(
        center: (0.64, 0.23),
        radius: (0.17, 0.11),
        scale: (0.54, 0.88),
      ),
      FinanceFocusZone.canadaNorthCompression(
        center: (0.335, 0.205),
        radius: (0.042, 0.030),
        scale: (0.46, 0.52),
      ),
      FinanceFocusZone.europeBasin(
        center: (0.535, 0.275),
        radius: (0.16, 0.11),
        scale: (1.34, 1.05),
      ),
      FinanceFocusZone.northAmericaCorridor(
        center: (0.275, 0.295),
        radius: (0.12, 0.10),
        scale: (1.14, 1.04),
      ),
      FinanceFocusZone.eastAsiaBasin(
        center: (0.765, 0.315),
        radius: (0.11, 0.10),
        scale: (1.17, 1.05),
      ),
      FinanceFocusZone.southeastAsiaSupport(
        center: (0.74, 0.46),
        radius: (0.09, 0.08),
        scale: (1.11, 1.04),
      ),
    ],
  );

  static FinanceProjectionFrame get frame => defaultModel.frame;
  static List<FinanceFocusZone> get zones => defaultModel.zones;

  static (double, double) warpCoords((double, double) norm) {
    var point = (norm.$1.clamp(0.0, 1.0), norm.$2.clamp(0.0, 1.0));

    for (final zone in zones) {
      point = zone.apply(point);
    }

    return (point.$1.clamp(0.0, 1.0), point.$2.clamp(0.0, 1.0));
  }

  static double projectDepth((double, double) norm) {
    final warped = warpCoords(norm);
    final nx = warped.$1;
    final projectedLatitude = _projectLatitude(warped.$2);
    final centeredX = nx * 2 - 1;
    final edgeDepth = math.cos(centeredX.abs() * math.pi / 2).clamp(0.0, 1.0);
    final latitudeDepth = (1 - projectedLatitude * 0.60).clamp(0.0, 1.0);
    return (edgeDepth * latitudeDepth).clamp(0.0, 1.0);
  }

  static Offset projectPoint(Size size, (double, double) norm) {
    final warped = warpCoords(norm);
    final nx = warped.$1;
    final centeredX = nx * 2 - 1;

    final curvedX = math.sin(centeredX * math.pi / 2);
    final usableWidth = size.width * (1 - frame.mapSideInset * 2);
    final projectedX = size.width * frame.mapSideInset +
        usableWidth * (0.5 + curvedX * 0.5 * frame.hemisphereWidth);

    final projectedLatitude = _projectLatitude(warped.$2);
    final usableHeight =
        size.height * (1 - frame.mapTopInset - frame.mapBottomInset);
    final baseY = size.height * frame.mapTopInset + usableHeight * projectedLatitude;

    final hemisphereDepth = math.cos(centeredX.abs() * math.pi / 2);
    final latitudeLift = 1 - projectedLatitude * 0.35;
    final projectedY = (baseY -
            size.height * frame.hemisphereLift * hemisphereDepth * latitudeLift)
        .clamp(0.0, size.height);

    return Offset(projectedX, projectedY);
  }

  static List<Offset> projectGuide(Size size, double yNorm, {int samples = 24}) {
    return List.generate(samples + 1, (index) {
      final nx = index / samples;
      return projectPoint(size, (nx, yNorm));
    });
  }

  static double _projectLatitude(double ny) {
    final clamped = ny.clamp(0.0, 1.0);
    if (clamped <= 0.5) {
      final northT = clamped / 0.5;
      return math.pow(northT, frame.northBiasExponent).toDouble() * frame.northSpan;
    }

    final southT = (clamped - 0.5) / 0.5;
    final southSpan = 1 - frame.northSpan;
    return frame.northSpan +
        math.pow(southT, frame.southCompressionExponent).toDouble() * southSpan;
  }
}

class FinanceDistortionModel {
  const FinanceDistortionModel({
    required this.frame,
    required this.zones,
  });

  final FinanceProjectionFrame frame;
  final List<FinanceFocusZone> zones;
}

class FinanceProjectionFrame {
  const FinanceProjectionFrame({
    required this.hemisphereWidth,
    required this.hemisphereLift,
    required this.northBiasExponent,
    required this.southCompressionExponent,
    required this.northSpan,
    required this.mapSideInset,
    required this.mapTopInset,
    required this.mapBottomInset,
  });

  final double hemisphereWidth;
  final double hemisphereLift;
  final double northBiasExponent;
  final double southCompressionExponent;
  final double northSpan;
  final double mapSideInset;
  final double mapTopInset;
  final double mapBottomInset;
}

class FinanceFocusZone {
  const FinanceFocusZone({
    required this.name,
    required this.center,
    required this.radius,
    required this.scale,
  });

  const FinanceFocusZone.northAtlanticCompression({
    required (double, double) center,
    required (double, double) radius,
    required (double, double) scale,
  }) : this(
          name: 'northAtlanticCompression',
          center: center,
          radius: radius,
          scale: scale,
        );

  const FinanceFocusZone.canadaNorthCompression({
    required (double, double) center,
    required (double, double) radius,
    required (double, double) scale,
  }) : this(
          name: 'canadaNorthCompression',
          center: center,
          radius: radius,
          scale: scale,
        );

  const FinanceFocusZone.europeBasin({
    required (double, double) center,
    required (double, double) radius,
    required (double, double) scale,
  }) : this(
          name: 'europeBasin',
          center: center,
          radius: radius,
          scale: scale,
        );

  const FinanceFocusZone.northAmericaCorridor({
    required (double, double) center,
    required (double, double) radius,
    required (double, double) scale,
  }) : this(
          name: 'northAmericaCorridor',
          center: center,
          radius: radius,
          scale: scale,
        );

  const FinanceFocusZone.eastAsiaBasin({
    required (double, double) center,
    required (double, double) radius,
    required (double, double) scale,
  }) : this(
          name: 'eastAsiaBasin',
          center: center,
          radius: radius,
          scale: scale,
        );

  const FinanceFocusZone.southeastAsiaSupport({
    required (double, double) center,
    required (double, double) radius,
    required (double, double) scale,
  }) : this(
          name: 'southeastAsiaSupport',
          center: center,
          radius: radius,
          scale: scale,
        );

  final String name;
  final (double, double) center;
  final (double, double) radius;
  final (double, double) scale;

  (double, double) apply((double, double) point) {
    final dx = (point.$1 - center.$1) / radius.$1;
    final dy = (point.$2 - center.$2) / radius.$2;
    final distanceSq = dx * dx + dy * dy;
    if (distanceSq >= 1) return point;

    final influence = math.pow(1 - distanceSq, 2).toDouble();
    final targetX = center.$1 + (point.$1 - center.$1) * scale.$1;
    final targetY = center.$2 + (point.$2 - center.$2) * scale.$2;
    return (
      point.$1 + (targetX - point.$1) * influence,
      point.$2 + (targetY - point.$2) * influence,
    );
  }
}
