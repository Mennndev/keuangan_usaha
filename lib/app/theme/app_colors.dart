import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.income,
    required this.incomeSurface,
    required this.expense,
    required this.expenseSurface,
    required this.info,
    required this.infoSurface,
    required this.canvas,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Color income;
  final Color incomeSurface;
  final Color expense;
  final Color expenseSurface;
  final Color info;
  final Color infoSurface;
  final Color canvas;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  static const light = AppColors(
    income: Color(0xFF16A34A),
    incomeSurface: Color(0xFFF0FDF4),
    expense: Color(0xFFDC2626),
    expenseSurface: Color(0xFFFEF2F2),
    info: Color(0xFF2563EB),
    infoSurface: Color(0xFFEFF6FF),
    canvas: Color(0xFFF5F7FA),
    card: Colors.white,
    border: Color(0xFFE5E7EB),
    textPrimary: Color(0xFF172033),
    textSecondary: Color(0xFF667085),
  );

  static const dark = AppColors(
    income: Color(0xFF4ADE80),
    incomeSurface: Color(0xFF103B24),
    expense: Color(0xFFF87171),
    expenseSurface: Color(0xFF481B1B),
    info: Color(0xFF60A5FA),
    infoSurface: Color(0xFF172B4D),
    canvas: Color(0xFF0F172A),
    card: Color(0xFF172033),
    border: Color(0xFF334155),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
  );

  @override
  AppColors copyWith({
    Color? income,
    Color? incomeSurface,
    Color? expense,
    Color? expenseSurface,
    Color? info,
    Color? infoSurface,
    Color? canvas,
    Color? card,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
  }) {
    return AppColors(
      income: income ?? this.income,
      incomeSurface: incomeSurface ?? this.incomeSurface,
      expense: expense ?? this.expense,
      expenseSurface: expenseSurface ?? this.expenseSurface,
      info: info ?? this.info,
      infoSurface: infoSurface ?? this.infoSurface,
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      income: Color.lerp(income, other.income, t)!,
      incomeSurface: Color.lerp(incomeSurface, other.incomeSurface, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseSurface: Color.lerp(expenseSurface, other.expenseSurface, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSurface: Color.lerp(infoSurface, other.infoSurface, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
