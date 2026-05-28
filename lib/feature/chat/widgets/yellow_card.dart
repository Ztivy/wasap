import 'package:flutter/material.dart';
import 'package:wasap2/common/extension/custom_theme_extension.dart';

class yellowCard extends StatelessWidget {
  const yellowCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10,horizontal: 30),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.theme.yellowCardBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('Message and calls are end-to-end encrypted. No one outside of ths chat, not even WhatsApp, can read or listen to then. Tap to learn more.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 13,color: context.theme.yellowCardTextColor),),
    );
  }
}