import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Утилита для адаптивных размеров UI элементов
/// Увеличивает размеры для веб-платформы для удобства использования
class ResponsiveSizes {
  // Проверка платформы
  static bool get isWeb => kIsWeb;
  
  // Множители для веба
  static const double webTextMultiplier = 1.3;
  static const double webButtonMultiplier = 1.4;
  static const double webIconMultiplier = 1.3;
  static const double webPaddingMultiplier = 1.2;
  
  // Размеры текста
  static double fontSize12(BuildContext context) => isWeb ? 16.0 : 12.0;
  static double fontSize14(BuildContext context) => isWeb ? 18.0 : 14.0;
  static double fontSize16(BuildContext context) => isWeb ? 20.0 : 16.0;
  static double fontSize18(BuildContext context) => isWeb ? 23.0 : 18.0;
  static double fontSize20(BuildContext context) => isWeb ? 26.0 : 20.0;
  static double fontSize24(BuildContext context) => isWeb ? 31.0 : 24.0;
  
  // Размеры иконок
  static double iconSize14(BuildContext context) => isWeb ? 18.0 : 14.0;
  static double iconSize16(BuildContext context) => isWeb ? 21.0 : 16.0;
  static double iconSize18(BuildContext context) => isWeb ? 23.0 : 18.0;
  static double iconSize20(BuildContext context) => isWeb ? 26.0 : 20.0;
  static double iconSize24(BuildContext context) => isWeb ? 31.0 : 24.0;
  static double iconSize48(BuildContext context) => isWeb ? 62.0 : 48.0;
  static double iconSize64(BuildContext context) => isWeb ? 83.0 : 64.0;
  
  // Отступы
  static double padding4(BuildContext context) => isWeb ? 5.0 : 4.0;
  static double padding6(BuildContext context) => isWeb ? 7.0 : 6.0;
  static double padding8(BuildContext context) => isWeb ? 10.0 : 8.0;
  static double padding10(BuildContext context) => isWeb ? 12.0 : 10.0;
  static double padding12(BuildContext context) => isWeb ? 14.0 : 12.0;
  static double padding16(BuildContext context) => isWeb ? 19.0 : 16.0;
  static double padding20(BuildContext context) => isWeb ? 24.0 : 20.0;
  static double padding24(BuildContext context) => isWeb ? 29.0 : 24.0;
  
  // Размеры кнопок
  static EdgeInsets buttonPadding(BuildContext context) => isWeb 
      ? const EdgeInsets.symmetric(vertical: 20, horizontal: 32)
      : const EdgeInsets.symmetric(vertical: 16, horizontal: 24);
      
  static double buttonHeight(BuildContext context) => isWeb ? 56.0 : 48.0;
  
  // Радиусы скругления
  static double radius8(BuildContext context) => isWeb ? 10.0 : 8.0;
  static double radius10(BuildContext context) => isWeb ? 12.0 : 10.0;
  static double radius12(BuildContext context) => isWeb ? 14.0 : 12.0;
  static double radius16(BuildContext context) => isWeb ? 19.0 : 16.0;
  static double radius20(BuildContext context) => isWeb ? 24.0 : 20.0;
  
  // Минимальные размеры для кликабельных элементов (для веба)
  static double minTouchTarget(BuildContext context) => isWeb ? 48.0 : 40.0;
}
