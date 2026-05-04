import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle titleMedium(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(color: AppColors.primary);

  static TextStyle body(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!;
}
