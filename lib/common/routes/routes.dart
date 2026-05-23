import 'package:flutter/material.dart';
import 'package:wasap2/feature/auth/pages/login_page.dart';
import 'package:wasap2/feature/auth/pages/user_info_page.dart';
import 'package:wasap2/feature/auth/pages/verification_page.dart';
import 'package:wasap2/feature/home/pages/home_page.dart';
import 'package:wasap2/feature/welcome/pages/welcome_page.dart';

class Routes {
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String verification = 'verification';
  static const String userInfo = 'user-info';
  static const String home = 'home';

static  Route<dynamic> onGenerateRoute(RouteSettings settings){
    switch(settings.name){
      case welcome:
      return MaterialPageRoute(builder: (context) => WelcomePage());
      case login:
      return MaterialPageRoute(builder: (context) => LoginPage());
      case verification:
      final Map args = settings.arguments as Map;
      return MaterialPageRoute(builder: (context) => VerificationPage(smsCodeId: args['smsCodeId'],
      phoneNumber: args['phoneNumber'],),);
      case userInfo:
      return MaterialPageRoute(builder: (context) => UserInfoPage());
      case home:
      return MaterialPageRoute(builder: (context) => HomePage());



      default:
      return MaterialPageRoute(builder: (context)=>const Scaffold(
        body: Center(child: Text('No Page Route Provided'),),
      ),);
    }
  }
}