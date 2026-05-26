import 'package:flutter/material.dart';
import 'package:wasap2/common/utils/coloors.dart';

extension ExtendedTheme on BuildContext{
  CustomThemeExtension get theme {
    return Theme.of(this).extension<CustomThemeExtension>()!;
  }
}

class CustomThemeExtension extends ThemeExtension<CustomThemeExtension>{
  static const lightMode=CustomThemeExtension(
    circleImageColor: Color(0xFF25D366),
    greyColor: Coloors.greyLight,
    blueColor: Coloors.blueLight,
    langBtnBgColor: Color(0xFFF7F8FA),
    langBtnHighlightColor: Color(0xFFE8E8ED),
    authAppBarTextColor: Coloors.greenLight,
    photoIconBgColor: Color(0xFFF1F1F1),
    photoIconColor: Color(0xFF9DAAB3),
    profilePageBg: Color(0xFFF7F8FA)
  );

  static const darkMode=CustomThemeExtension(
    circleImageColor: Coloors.greenDark,
    greyColor: Coloors.greyDark,
    blueColor: Coloors.blueDark,
    langBtnBgColor: Color(0xFF182229),
    langBtnHighlightColor: Color(0xFF09141A),
    authAppBarTextColor: Color(0xFFE9EDEF),
    photoIconBgColor: Color(0xFF283339),
    photoIconColor: Color(0xFF61717B),
    profilePageBg: Color(0xFF0B141A)
  );

  final Color? circleImageColor;
  final Color? greyColor;
  final Color? blueColor;
  final Color? langBtnBgColor;
  final Color? langBtnHighlightColor;
  final Color? authAppBarTextColor;
  final Color? photoIconBgColor;
  final Color? photoIconColor;
  final Color? profilePageBg;

  const CustomThemeExtension({this.circleImageColor, this.greyColor, this.blueColor,
  this.langBtnBgColor, this.langBtnHighlightColor,
  this.authAppBarTextColor, this.photoIconBgColor, this.photoIconColor, this.profilePageBg});

  @override
  ThemeExtension<CustomThemeExtension> copyWith(
    {Color? circleImageColor,
    Color? greyColor,
    Color? blueColor,
    Color? langBtnBgColor,
    Color? langBtnHighlightColor,
    Color? authAppBarTextColor,
    Color? photoIconBgColor,
    Color? photoIconColor,
    Color? profilePageBg,
    }) {
    return CustomThemeExtension(
      circleImageColor: circleImageColor ?? this.circleImageColor,
      greyColor: greyColor ?? this.greyColor,
      blueColor: blueColor ?? this.blueColor,
      langBtnBgColor: langBtnBgColor ?? this.langBtnBgColor,
      langBtnHighlightColor: langBtnHighlightColor ?? this.langBtnHighlightColor,
      authAppBarTextColor: authAppBarTextColor ?? this.authAppBarTextColor,
      photoIconBgColor: photoIconBgColor ?? this.photoIconBgColor,
      photoIconColor: photoIconColor ?? this.photoIconColor,
      profilePageBg: profilePageBg ?? this.profilePageBg,
    );
  }

  @override
  ThemeExtension<CustomThemeExtension> lerp(covariant ThemeExtension<CustomThemeExtension>? other, double t) {
    if(other is! CustomThemeExtension)return this;
    return CustomThemeExtension(
      circleImageColor: Color.lerp(circleImageColor,other.circleImageColor,t),
      greyColor: Color.lerp(greyColor,other.greyColor,t),
      blueColor: Color.lerp(blueColor,other.blueColor,t),
      langBtnBgColor: Color.lerp(langBtnBgColor,other.langBtnBgColor,t),
      langBtnHighlightColor: Color.lerp(langBtnHighlightColor,other.langBtnHighlightColor,t),
      authAppBarTextColor: Color.lerp(authAppBarTextColor,other.authAppBarTextColor,t),
      photoIconBgColor: Color.lerp(photoIconBgColor,other.photoIconBgColor,t),
      photoIconColor: Color.lerp(photoIconColor,other.photoIconColor,t),
      profilePageBg: Color.lerp(profilePageBg,other.profilePageBg,t),
    );
  }
}