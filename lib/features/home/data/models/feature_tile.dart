import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// A feature entry shown on the home hub.
class FeatureTile extends Equatable {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const FeatureTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  @override
  List<Object?> get props => [title, route];
}
