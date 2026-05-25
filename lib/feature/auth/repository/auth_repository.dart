import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wasap2/common/helper/show_alert_dialog.dart';
import 'package:wasap2/common/helper/show_loading_dialog.dart';
import 'package:wasap2/common/models/user_model.dart';
import 'package:wasap2/common/repository/SupabaseStorageRepository.dart';
import 'package:wasap2/common/routes/routes.dart';

final AuthRepositoryProvider=Provider((ref){
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    realtime: FirebaseDatabase.instance,
    );
});

class AuthRepository{
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseDatabase realtime;

  AuthRepository({required this.auth, required this.firestore, required this.realtime});

  Stream<UserModel> getUserPresenceStatus({required String uid}) {
  return realtime.ref().child(uid).onValue.asyncMap((event) async {
    // Obtiene datos de presencia desde Realtime Database
    final presenceData = event.snapshot.value as Map<dynamic, dynamic>?;
    
    // Obtiene el resto del perfil desde Firestore
    final userInfo = await firestore.collection('users').doc(uid).get();
    final user = UserModel.fromMap(userInfo.data()!);
    
    // Combina con los datos de presencia en tiempo real
    return UserModel(
      username: user.username,
      uId: user.uId,
      profileImageUrl: user.profileImageUrl,
      phoneNumber: user.phoneNumber,
      groupId: user.groupId,
      active: presenceData?['active'] ?? false,
      lastSeen: presenceData?['lastSeen'] ?? 0,
    );
  });
}

  void updateUserPresence()async{
    Map<String, dynamic>online={
      'active':true,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    };
    Map<String, dynamic> offline={
      'active':false,
      'lastSeen':DateTime.now().millisecondsSinceEpoch,
    };

    final connectedRef = realtime.ref('.info/connected');

    connectedRef.onValue.listen((event)async{
      final isConnected=event.snapshot.value as bool? ??false;
      if(isConnected){
        await realtime.ref().child(auth.currentUser!.uid).update(online);
      }else{
        realtime.ref().child(auth.currentUser!.uid).onDisconnect().update(offline);
      }
    });
  }

  Future <UserModel?> getCurrentUserInfo()async{
    UserModel? user;
    final userInfo= await firestore.collection('users').doc(auth.currentUser?.uid).get();
    if(userInfo.data()==null)return user;
    user=UserModel.fromMap(userInfo.data()!);
    return user;
  }

  void saveUserInfoToFirestore(
    {required String username,
    required var profileImage,
    required Ref ref,
    required BuildContext context,
    required bool mounted}
  )async{
    try{
      showLoadingDialog(context: context, message: 'Saving user Info ...');
      String uid= auth.currentUser!.uid;
      String profileImageUrl=profileImage is String? profileImage: '';
      if(profileImage != null && profileImage is! String){
        profileImageUrl = await ref.read(supabaseStorageRepositoryProvider).storeFileToSupabase('profileImage/$uid', profileImage);
      }
      UserModel user = UserModel(
        username: username,
        uId: uid,
        profileImageUrl: profileImageUrl,
        active: true,
        lastSeen: DateTime.now().millisecondsSinceEpoch,
        phoneNumber: auth.currentUser!.phoneNumber!,
        groupId: []);

        await firestore.collection('users').doc(uid).set(user.toMap());

        if(!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route)=>false);
    }catch(e){
      Navigator.pop(context);
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
        showLoadingDialog(context: context, message: 'Verifiying code ...');
        final credential = PhoneAuthProvider.credential(verificationId: smsCodeId, smsCode: smsCode,);
        await auth.signInWithCredential(credential);
        UserModel? user = await getCurrentUserInfo();
        if(!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(Routes.userInfo, (route)=>false,
        arguments: user?.profileImageUrl,);
      }on FirebaseAuthException catch(e){
        Navigator.pop(context);
        showAlertDialog(context: context, message: e.toString());
      }
    }

  void sendSmsCode({required BuildContext context,required String phoneNumber,})
  async{
    try{
      showLoadingDialog(context: context, message: 'Sending a verfication code to $phoneNumber');
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
      Navigator.pop(context);
      showAlertDialog(context: context, message: e.toString());
    }
  }
}