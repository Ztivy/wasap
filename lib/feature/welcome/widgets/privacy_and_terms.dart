import 'package:flutter/material.dart';
import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/utils/coloors.dart';

class PrivacyAndTerms extends StatelessWidget {
  const PrivacyAndTerms({Key? key}):super(key:key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:30,vertical: 20),
      child: RichText(
        textAlign: TextAlign.center,
        text:  TextSpan(
        text: 'Read our',
        style: TextStyle(
          color: context.theme.greyColor,
          height: 1.5,
        ),
        children: [
          TextSpan(
            text: 'Privacy Policy.',
            style: TextStyle(
              color: context.theme.blueColor,
            ),
          ),
          const TextSpan(
            text: 'Tap "Agree and continue" to accept the'
          ),
          TextSpan(
            text: 'Terms of Service.',
            style: TextStyle(
              color: context.theme.blueColor
            ),
          )
        ]
      )),
    );
  }
}