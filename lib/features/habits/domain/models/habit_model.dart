import 'package:flutter/material.dart';

enum HabitStatus { pendente, concluido, compensado }

enum HabitPriority { baixa, media, alta }

class PlanBOption {
  final String title;
  final String subtitle;

  PlanBOption({
    required this.title,
    required this.subtitle,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
    };
  }

  factory PlanBOption.fromMap(Map<String, dynamic> map) {
    return PlanBOption(
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
    );
  }
}

class HabitModel {
  final String id;
  final String title;
  final String category;
  final String? frequency;
  final String? time;
  final int? durationMinutes;
  final HabitPriority? priority;
  final IconData? icon;
  final Color? iconBgColor;
  final HabitStatus status;
  final List<PlanBOption> planBOptions;

  HabitModel({
    required this.id,
    required this.title,
    required this.category,
    this.frequency,
    this.time,
    this.durationMinutes,
    this.priority,
    this.icon,
    this.iconBgColor,
    this.status = HabitStatus.pendente,
    this.planBOptions = const [],
  });

  Map<String, dynamic> toMap(String userId) {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'frequency': frequency,
      'time': time,
      'durationMinutes': durationMinutes,
      'priority': priority?.name,
      'iconCodePoint': icon?.codePoint,
      'iconFontFamily': icon?.fontFamily,
      'iconColorValue': iconBgColor?.toARGB32(),
      'status': status.name,
      'planBOptions': planBOptions.map((x) => x.toMap()).toList(),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory HabitModel.fromMap(String id, Map<String, dynamic> map) {
    final int? codePoint = map['iconCodePoint'] != null 
        ? (map['iconCodePoint'] as num).toInt() 
        : null;
    final String fontFamily = map['iconFontFamily']?.toString() ?? 'MaterialIcons';

    final int? colorValue = map['iconColorValue'] != null 
        ? (map['iconColorValue'] as num).toInt() 
        : null;

    return HabitModel(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      frequency: map['frequency'],
      time: map['time'],
      durationMinutes: map['durationMinutes'],
      priority: map['priority'] != null
          ? HabitPriority.values.firstWhere(
              (e) => e.name == map['priority'],
              orElse: () => HabitPriority.media,
            )
          : null,
      // ignore: non_const_argument_for_const_parameter
      icon: codePoint != null ? IconData(codePoint, fontFamily: fontFamily) : null,
      iconBgColor: colorValue != null ? Color(colorValue) : null,
      status: HabitStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => HabitStatus.pendente,
      ),
      planBOptions: (map['planBOptions'] as List<dynamic>?)
              ?.map((x) => PlanBOption.fromMap(x as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}