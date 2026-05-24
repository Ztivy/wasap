import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/utils/coloors.dart';

ThemeData darkTheme(){
  final ThemeData base= ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: Coloors.backgroundDark,
    extensions: [
      CustomThemeExtension.darkMode,
    ],
    appBarTheme:const AppBarTheme(
      backgroundColor: Coloors.greyBackground,
      titleTextStyle: TextStyle(fontSize: 18,fontWeight: FontWeight.w600,color: Coloors.greyDark),
      systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
    ),
    iconTheme: IconThemeData(
      color: Coloors.greyDark,
    ),
  ),

    colorScheme: const ColorScheme.dark().copyWith(
      background: Coloors.backgroundDark,
      surface: Coloors.backgroundDark
    ),
    tabBarTheme: const TabBarThemeData(
      indicator: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Coloors.greenDark,
            width: 2
          ),
        ),
      ),
      labelColor: Coloors.greyDark,
      unselectedLabelColor: Coloors.greyDark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Coloors.greenDark,
          foregroundColor: Coloors.backgroundDark,
          splashFactory: NoSplash.splashFactory,
          elevation: 0,
          shadowColor: Colors.transparent,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Coloors.greyBackground,
      modalBackgroundColor: Coloors.greyBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20),),
      )
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Coloors.greyBackground, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}