import 'package:flutter/material.dart';

class PlanBOption {
  final String title;
  final String subtitle;

  PlanBOption({required this.title, required this.subtitle});

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
  final String frequency;
  final TimeOfDay? reminderTime;
  final List<PlanBOption> planBOptions;
  final bool isCompleted;

  HabitModel({
    required this.id,
    required this.title,
    required this.category,
    required this.frequency,
    this.reminderTime,
    required this.planBOptions,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap(String userId) {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'frequency': frequency,
      'reminderHour': reminderTime?.hour,
      'reminderMinute': reminderTime?.minute,
      'planBOptions': planBOptions.map((x) => x.toMap()).toList(),
      'isCompleted': isCompleted,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory HabitModel.fromMap(String id, Map<String, dynamic> map) {
    return HabitModel(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      frequency: map['frequency'] ?? '',
      reminderTime: map['reminderHour'] != null
          ? TimeOfDay(hour: map['reminderHour'], minute: map['reminderMinute'])
          : null,
      planBOptions: (map['planBOptions'] as List<dynamic>?)
              ?.map((x) => PlanBOption.fromMap(x as Map<String, dynamic>))
              .toList() ??
          [],
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}