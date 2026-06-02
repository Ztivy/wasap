import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_clippers/custom_clippers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/helper/last_seen_message.dart';
import 'package:wasap2/common/models/message_model.dart';
import 'package:wasap2/common/models/user_model.dart';
import 'package:wasap2/common/routes/routes.dart';
import 'package:wasap2/common/widgets/custom_icon_button.dart';
import 'package:wasap2/feature/auth/controller/auth_controller.dart';
import 'package:wasap2/feature/chat/controller/chat_controller.dart';
import 'package:wasap2/feature/chat/widgets/chat_text_field.dart';
import 'package:wasap2/feature/chat/widgets/message_card.dart';
import 'package:wasap2/feature/chat/widgets/show_date_card.dart';
import 'package:wasap2/feature/chat/widgets/yellow_card.dart';

final PageStorageBucket bucket = PageStorageBucket();

class ChatPage extends ConsumerWidget {
  ChatPage({super.key, required this.user});

  final UserModel user;
  final ScrollController scrollController = ScrollController();

  // ── Video call dialog ──────────────────────────────────────────────────────
  void _startVideoCall(BuildContext context) {
  // El channelId debe ser igual en ambos dispositivos.
  // Ordenar los UIDs garantiza que sea el mismo sin importar quién llama.
  final myUid = FirebaseAuth.instance.currentUser!.uid;
  final ids = [myUid, user.uId]..sort();
  final channelId = ids.join('_');

  Navigator.pushNamed(
    context,
    Routes.videoCall,
    arguments: {
      'channelId': channelId,
      'calleeName': user.username,
      'calleeAvatarUrl': user.profileImageUrl,
    },
  );
}

  // ── Marcar mensajes recibidos como vistos ──────────────────────────────────
  void _markMessagesAsSeen(
      BuildContext context, WidgetRef ref, List<MessageModel> messages) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    for (final msg in messages) {
      if (msg.senderId != currentUid && !msg.isSeen) {
        ref
            .read(chatControllerProvider)
            .setChatMessageSeen(context, user.uId, msg.messageId);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.theme.chatPageBgColor,
      appBar: AppBar(
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              const Icon(Icons.arrow_back),
              Hero(
                tag: 'profile',
                child: Container(
                  width: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                          user.profileImageUrl),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: InkWell(
          onTap: () => Navigator.pushNamed(context, Routes.profile,
              arguments: user),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username,
                    style: const TextStyle(
                        fontSize: 18, color: Colors.white)),
                const SizedBox(height: 3),
                StreamBuilder(
                  stream: ref
                      .read(authControllerProvider)
                      .getUserPresenceStatus(uid: user.uId),
                  builder: (_, snapshot) {
                    if (snapshot.connectionState !=
                        ConnectionState.active) {
                      return const Text('connecting',
                          style: TextStyle(
                              fontSize: 12, color: Colors.white));
                    }
                    final singleUserModel = snapshot.data!;
                    final lastMessage =
                        lastSeenMessage(singleUserModel.lastSeen);
                    return Text(
                      singleUserModel.active
                          ? "Online"
                          : "$lastMessage ago",
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          CustomIconButton(
            onTap: () => _startVideoCall(context),
            icon: Icons.video_call,
            iconColor: Colors.white,
          ),
          CustomIconButton(
              onTap: () {}, icon: Icons.call, iconColor: Colors.white),
          CustomIconButton(
              onTap: () {},
              icon: Icons.more_vert,
              iconColor: Colors.white),
        ],
      ),
      body: Stack(
        children: [
          Image(
            height: double.maxFinite,
            width: double.maxFinite,
            image: const AssetImage('assets/images/doodle_bg.png'),
            fit: BoxFit.cover,
            color: context.theme.chatPageDoodleColor,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: StreamBuilder(
              stream: ref
                  .watch(chatControllerProvider)
                  .getAllOneToOneMessage(user.uId),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.active) {
                  return ListView.builder(
                    itemCount: 15,
                    itemBuilder: (_, index) {
                      final random = Random().nextInt(14);
                      return Container(
                        alignment: random.isEven
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        margin: EdgeInsets.only(
                          top: 5,
                          bottom: 5,
                          left: random.isEven ? 150 : 15,
                          right: random.isEven ? 15 : 150,
                        ),
                        child: ClipPath(
                          clipper: UpperNipMessageClipperTwo(
                            random.isEven
                                ? MessageType.send
                                : MessageType.receive,
                            nipWidth: 8,
                            nipHeight: 10,
                            bubbleRadius: 12,
                          ),
                          child: Shimmer.fromColors(
                            baseColor: random.isEven
                                ? context.theme.greyColor!
                                    .withOpacity(.3)
                                : context.theme.greyColor!
                                    .withOpacity(.2),
                            highlightColor: random.isEven
                                ? context.theme.greyColor!
                                    .withOpacity(.4)
                                : context.theme.greyColor!
                                    .withOpacity(.3),
                            child: Container(
                              height: 40,
                              width: 170 +
                                  double.parse((random * 2).toString()),
                              color: Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                // Marcar mensajes como vistos al cargar
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markMessagesAsSeen(
                      context, ref, snapshot.data ?? []);
                });

                return PageStorage(
                  bucket: bucket,
                  child: ListView.builder(
                    key: const PageStorageKey('chat_page_list'),
                    itemCount: snapshot.data!.length,
                    shrinkWrap: true,
                    controller: scrollController,
                    itemBuilder: (_, index) {
                      final message = snapshot.data![index];
                      final isSender = message.senderId ==
                          FirebaseAuth.instance.currentUser!.uid;
                      final haveNip = (index == 0) ||
                          (index == snapshot.data!.length - 1 &&
                              message.senderId !=
                                  snapshot.data![index - 1].senderId) ||
                          (message.senderId !=
                                  snapshot.data![index - 1].senderId &&
                              message.senderId ==
                                  snapshot.data![index + 1].senderId) ||
                          (message.senderId !=
                                  snapshot.data![index - 1].senderId &&
                              message.senderId !=
                                  snapshot.data![index + 1].senderId);
                      final isShowDateCard = (index == 0) ||
                          ((index == snapshot.data!.length - 1) &&
                              (message.timeSent.day >
                                  snapshot.data![index - 1].timeSent
                                      .day)) ||
                          (message.timeSent.day >
                                  snapshot.data![index - 1].timeSent
                                      .day &&
                              message.timeSent.day <=
                                  snapshot.data![index + 1].timeSent
                                      .day);

                      return Column(
                        children: [
                          if (index == 0) yellowCard(),
                          if (isShowDateCard)
                            ShowDateCard(date: message.timeSent),
                          MessageCard(
                            isSender: isSender,
                            haveNip: haveNip,
                            message: message,
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            alignment: const Alignment(0, 1),
            child: ChatTextField(
              receiverId: user.uId,
              scrollController: scrollController,
            ),
          ),
        ],
      ),
    );
  }
}