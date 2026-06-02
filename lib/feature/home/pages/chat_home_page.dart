import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/models/group_model.dart';
import 'package:wasap2/common/models/last_message_model.dart';
import 'package:wasap2/common/models/user_model.dart';
import 'package:wasap2/common/routes/routes.dart';
import 'package:wasap2/common/utils/coloors.dart';
import 'package:wasap2/feature/chat/controller/chat_controller.dart';

class ChatHomePage extends ConsumerWidget {
  const ChatHomePage({super.key});

  navigateToContactPage(context) {
    Navigator.pushNamed(context, Routes.contact);
  }

  /// Obtiene el UserModel completo desde Firestore y navega al chat.
  Future<void> _navigateToChat(
      BuildContext context, String contactId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(contactId)
          .get();
      if (!context.mounted) return;
      if (!doc.exists || doc.data() == null) return;
      final user = UserModel.fromMap(doc.data()!);
      Navigator.pushNamed(context, Routes.chat, arguments: user);
    } catch (_) {
      // Si falla, no navegamos — el usuario sigue en la lista
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: StreamBuilder<List<LastMessageModel>>(
        stream:
            ref.watch(chatControllerProvider).getAllLastMessageList(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Coloors.greenDark),
            );
          }

          final oneToOneChats = snapshot.data ?? [];

          return StreamBuilder<List<GroupModel>>(
            stream: ref
                .watch(chatControllerProvider)
                .getAllGroupChatList(),
            builder: (_, groupSnapshot) {
              if (groupSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                      color: Coloors.greenDark),
                );
              }

              final groups = groupSnapshot.data ?? [];

              if (groups.isEmpty && oneToOneChats.isEmpty) {
                return Center(
                  child: Text(
                    'No chats yet',
                    style:
                        TextStyle(color: context.theme.greyColor),
                  ),
                );
              }

              final items = <Widget>[];

              // ── Grupos ─────────────────────────────────────────────
              if (groups.isNotEmpty) {
                items.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      'Group chats',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.theme.greyColor,
                      ),
                    ),
                  ),
                );

                items.addAll(groups.map((group) {
                  return ListTile(
                    onTap: () => Navigator.pushNamed(
                      context,
                      Routes.groupChat,
                      arguments: group,
                    ),
                    leading: group.groupPicture.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(
                                group.groupPicture),
                            radius: 24,
                          )
                        : const CircleAvatar(
                            radius: 24,
                            child: Icon(Icons.group),
                          ),
                    title: Text(group.groupName),
                    subtitle: Text(
                      group.lastMessage.isNotEmpty
                          ? group.lastMessage
                          : 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: context.theme.greyColor),
                    ),
                    trailing: Text(
                      DateFormat.Hm().format(group.timeSent),
                      style: TextStyle(
                          fontSize: 13,
                          color: context.theme.greyColor),
                    ),
                  );
                }));

                items.add(const Divider(height: 1));
              }

              // ── Chats 1 a 1 ───────────────────────────────────────
              items.addAll(oneToOneChats.map((lastMsg) {
                return ListTile(
                  // ↓ Aquí está el cambio clave: fetch completo antes de navegar
                  onTap: () =>
                      _navigateToChat(context, lastMsg.contactId),
                  title: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(lastMsg.username),
                      Text(
                        DateFormat.Hm().format(lastMsg.timeSent),
                        style: TextStyle(
                            fontSize: 13,
                            color: context.theme.greyColor),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      lastMsg.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: context.theme.greyColor),
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                        lastMsg.profileImageUrl),
                    radius: 24,
                  ),
                );
              }));

              return ListView(
                shrinkWrap: true,
                children: items,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigateToContactPage(context),
        child: const Icon(Icons.chat),
      ),
    );
  }
}