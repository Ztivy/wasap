import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_clippers/custom_clippers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/helper/last_seen_message.dart';
import 'package:wasap2/common/models/user_model.dart';
import 'package:wasap2/common/routes/routes.dart';
import 'package:wasap2/common/widgets/custom_icon_button.dart';
import 'package:wasap2/feature/auth/controller/auth_controller.dart';
import 'package:wasap2/feature/chat/controller/chat_controller.dart';
import 'package:wasap2/feature/chat/widgets/chat_text_field.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.theme.chatPageBgColor ,
      appBar: AppBar(
        leading: InkWell(
          onTap: (){
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Icon(Icons.arrow_back),
              Hero(
                  tag: 'profile',
                  child: Container(
                  width: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(image: CachedNetworkImageProvider(user.profileImageUrl))
                  ),
                                ),
                ),
            ],
          ),
        ),
        title: InkWell(
          onTap: (){
            Navigator.pushNamed(context, Routes.profile,arguments: user);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3,vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username, style: const TextStyle(fontSize: 18, color: Colors.white),),
                SizedBox(height: 3,),
                StreamBuilder(
                  stream: ref.read(authControllerProvider).getUserPresenceStatus(uid:user.uId),
                  builder: (_,snapshot){
                    if(snapshot.connectionState!=ConnectionState.active){
                      return const Text(
                        'connecting', 
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white
                          ),
                        );
                      }
                    final singleUserModel=snapshot.data!;
                    final lastMessage=lastSeenMessage(singleUserModel.lastSeen);
            
                    return Text(singleUserModel.active ? "Online":"$lastMessage ago",
                    style:const TextStyle(
                          fontSize: 12,
                          color: Colors.white
                          ),);
                    },
                ),
              ],
            ),
          ),
        ),
        actions: [
          CustomIconButton(onTap: (){}, icon: Icons.video_call,iconColor: Colors.white,),
          CustomIconButton(onTap: (){}, icon: Icons.call,iconColor: Colors.white,),
          CustomIconButton(onTap: (){}, icon: Icons.more_vert,iconColor: Colors.white,),
        ],
      ),
      body: Stack(
        children: [
          Image(
          height: double.maxFinite,
          width: double.maxFinite,
          image:const AssetImage('assets/images/doodle_bg.png'),
          fit: BoxFit.cover,
          color: context.theme.chatPageDoodleColor,),
          Column(
            children: [
              Expanded(child: StreamBuilder(
                stream: ref
                .watch(chatControllerProvider)
                .getAllOneToOneMessage(user.uId),
                builder: (context, snapshot){
                  if(snapshot.connectionState != ConnectionState.active){
                    return const Center(child: CircularProgressIndicator(),);
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (_,index){
                      final message=snapshot.data![index];
                      final isSender=message.senderId==FirebaseAuth.instance.currentUser!.uid;
                      final haveNip=(index==0)||(index== snapshot.data!.length-1 && message.senderId != snapshot.data![index-1].senderId)
                      || (message.senderId != snapshot.data![index - 1].senderId && message.senderId == snapshot.data![index+1].senderId)
                      || (message.senderId != snapshot.data![index - 1].senderId && message.senderId != snapshot.data![index+1].senderId);

                      return Column(
                        children: [
                          if(index==0)Container(
                            margin: EdgeInsets.symmetric(vertical: 10,horizontal: 30),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.theme.yellowCardBgColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Message and calls are end-to-end encrypted. No one outside of ths chat, not even WhatsApp, can read or listen to then. Tap to learn more.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13,color: context.theme.yellowCardTextColor),),
                          ),
                          Container(
                            alignment: isSender? Alignment.centerRight:Alignment.centerLeft,
                            margin:  EdgeInsets.only(
                              top: 4,
                              bottom: 4,
                              left: isSender ? 80: haveNip ? 10:15,
                              right: isSender ? haveNip ? 10 :15 :80,
                            ),
                            child: ClipPath(
                              clipper: haveNip ? UpperNipMessageClipperTwo(isSender ? MessageType.send: MessageType.receive,
                              nipWidth: 8,
                              nipHeight: 10,
                              bubbleRadius: haveNip ? 12:0
                              ):null,
                              child: Container(
                                padding:  EdgeInsets.only(top: 8,bottom: 8,
                                left: isSender ? 10 :15,
                                right: isSender ? 15:10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSender?context.theme.senderChatCardBg:context.theme.receiverChatCardBg,
                                  borderRadius: haveNip? null: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black38)],
                                ),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 5 ),
                                      child: Text("${message.textMessage}       ", style: TextStyle(fontSize: 16),),
                                    ),
                                    Positioned(bottom: 0,right: 0 , child: Text(DateFormat.Hm().format(message.timeSent)
                                    ,style: TextStyle(fontSize: 11,color: context.theme.greyColor),
                                    ))
                                  ],
                                ),),
                            ),),
                        ],
                      );
                    },
                  );
                },
              ),
              ),
            ChatTextField(receiverId: user.uId),
          ],
          ),
        ],
      ),
    );
  }
}