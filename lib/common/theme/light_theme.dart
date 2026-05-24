import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/utils/coloors.dart';

ThemeData lightTheme(){
  final ThemeData base= ThemeData.light();
  return base.copyWith(
    scaffoldBackgroundColor: Coloors.backgroundLight,
    extensions: [
      CustomThemeExtension.lightMode,
    ],
    colorScheme: const ColorScheme.light().copyWith(
      background: Coloors.backgroundLight,
      surface: Coloors.backgroundLight
    ),
    appBarTheme:const AppBarTheme(
      backgroundColor: Coloors.greenLight,
      titleTextStyle: TextStyle(fontSize: 18,fontWeight: FontWeight.w600),
      systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
    ),
    ),
    tabBarTheme: const TabBarThemeData(
      indicator: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white,
            width: 2
          ),
        ),
      ),
      labelColor: Colors.white,
      unselectedLabelColor: Color(0xFFB3D9D2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Coloors.greenLight,
          foregroundColor: Coloors.backgroundLight,
          splashFactory: NoSplash.splashFactory,
          elevation: 0,
          shadowColor: Colors.transparent,
      )
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Coloors.backgroundLight,
      modalBackgroundColor: Coloors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20),),
      )
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Coloors.backgroundLight, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}