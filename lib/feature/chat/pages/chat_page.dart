import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wasap2/common/helper/last_seen_message.dart';
import 'package:wasap2/common/models/user_model.dart';
import 'package:wasap2/common/routes/routes.dart';
import 'package:wasap2/common/widgets/custom_icon_button.dart';
import 'package:wasap2/feature/auth/controller/auth_controller.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
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
    );
  }
}