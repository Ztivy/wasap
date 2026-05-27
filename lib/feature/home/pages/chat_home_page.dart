import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/models/last_message_model.dart';
import 'package:wasap2/common/routes/routes.dart';
import 'package:wasap2/common/utils/coloors.dart';
import 'package:wasap2/feature/chat/controller/chat_controller.dart';

class ChatHomePage extends ConsumerWidget {
  const ChatHomePage({super.key});

  navigateToContactPage(context){
    Navigator.pushNamed(context, Routes.contact);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: StreamBuilder<List<LastMessageModel>>(
        stream: ref.watch(chatControllerProvider).getAllLastMessageList(),
        builder: (_,snapshot){
          if(snapshot.connectionState==ConnectionState.waiting){
            return Center(
              child: CircularProgressIndicator(
                color: Coloors.greenDark,
              ),
              );
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            shrinkWrap: true,
            itemBuilder: (context,index){
              final LastMessageData=snapshot.data![index];
              return ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(LastMessageData.username),
                    Text(DateFormat.Hm().format(LastMessageData.timeSent),
                    style: TextStyle(
                      fontSize: 13,
                      color: context.theme.greyColor,
                    ),)
                  ],
                ),
                subtitle: Padding(padding: const  EdgeInsets.only(top: 3),
                child: Text(LastMessageData.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.theme.greyColor),),
                ),
                leading: CircleAvatar(
                  backgroundImage:CachedNetworkImageProvider(LastMessageData.profileImageUrl),
                  radius: 24,
                ),
              );
            },
            );
        }),
      floatingActionButton: FloatingActionButton(onPressed: ()=>navigateToContactPage(context),
      child: const Icon(Icons.chat),),
    );
  }
}