import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wasap2/common/helper/show_alert_dialog.dart';
import 'package:wasap2/common/models/user_model.dart';
import 'package:wasap2/common/repository/SupabaseStorageRepository.dart';
import 'package:wasap2/common/routes/routes.dart';

final AuthRepositoryProvider=Provider((ref){
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    );
});

class AuthRepository{
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRepository({required this.auth, required this.firestore});

  void saveUserInfoToFirestore(
    {required String username,
    required var profileImage,
    required Ref ref,
    required BuildContext context,
    required bool mounted}
  )async{
    try{
      String uid= auth.currentUser!.uid;
      String profileImageUrl='';
      if(profileImage != null){
        profileImageUrl = await ref.read(supabaseStorageRepositoryProvider).storeFileToSupabase('profileImage/$uid', profileImage);
      }
      UserModel user = UserModel(
        username: username,
        uId: uid,
        profileImageUrl: profileImageUrl,
        active: true,
        phoneNumber: auth.currentUser!.phoneNumber!,
        groupId: []);

        await firestore.collection('users').doc(uid).set(user.toMap());

        if(!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route)=>false);
    }catch(e){
      showAlertDialog(context: context, message: e.toString());
    }
  }

  void verifySmsCode({
    required BuildContext context,
    required String smsCodeId,
    required String smsCode,
    required bool mounted,
    })async{
      try{
        final credential = PhoneAuthProvider.credential(verificationId: smsCodeId, smsCode: smsCode,);
        await auth.signInWithCredential(credential);
        if(!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(Routes.userInfo, (route)=>false);
      }on FirebaseAuthException catch(e){
        showAlertDialog(context: context, message: e.toString());
      }
    }

  void sendSmsCode({required BuildContext context,required String phoneNumber,})
  async{
    try{
      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential)async{
          await auth.signInWithCredential(credential);
        },
        verificationFailed: (e){
          showAlertDialog(context: context, message: e.toString());
        },
        codeSent: (smsCodeId, resendSmsCodeId){
          Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.verification,
          (route)=>false,
          arguments: {
            'phoneNumber': phoneNumber,
            'smsCodeId': smsCodeId,

          },
          );
        },
        codeAutoRetrievalTimeout: (String smsCodeId){}
        );
    }on FirebaseAuth catch(e){
      showAlertDialog(context: context, message: e.toString());
    }
  }
}