import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/theme/theme.dart';

class AppTheme {
  static ThemeData appTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.colorScheme),
    indicatorColor: AppColors.pureWhiteColor,
    primaryColor: AppColors.primaryColor,
    useMaterial3: true,
    fontFamily: 'Manrope',
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: AppColors.primaryColor,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
          color: AppColors.pureWhiteColor, fontSize: 20, fontFamily: 'Manrope'),
      iconTheme: IconThemeData(color: AppColors.pureWhiteColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputDecorationTheme,
      border: const OutlineInputBorder(
        borderSide: BorderSide.none,
      ),
    ),
    scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor,
    dividerColor: AppColors.grey300,
  );
}
