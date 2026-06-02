import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/models/group_model.dart';
import 'package:wasap2/common/models/user_model.dart';
import 'package:wasap2/common/utils/coloors.dart';

class GroupChatPage extends ConsumerWidget {
  const GroupChatPage({super.key, required this.group});

  final GroupModel group;

  Future<List<UserModel>> _loadMembers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uId', whereIn: group.membersUid)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (group.groupPicture.isNotEmpty)
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    CachedNetworkImageProvider(group.groupPicture),
              )
            else
              const CircleAvatar(
                radius: 20,
                child: Icon(Icons.group),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                group.groupName,
                style: const TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group members',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.theme.greyColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${group.membersUid.length} members',
                  style: TextStyle(color: context.theme.greyColor),
                ),
                const SizedBox(height: 20),
                Text(
                  group.lastMessage.isNotEmpty
                      ? 'Last message: ${group.lastMessage}'
                      : 'No messages yet',
                  style: TextStyle(color: context.theme.greyColor),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _loadMembers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final members = snapshot.data ?? [];
                if (members.isEmpty) {
                  return Center(
                    child: Text(
                      'No members found',
                      style: TextStyle(color: context.theme.greyColor),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            member.profileImageUrl.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    member.profileImageUrl)
                                : null,
                        child: member.profileImageUrl.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(member.username),
                      subtitle: Text(
                        member.phoneNumber,
                        style: TextStyle(color: context.theme.greyColor),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Group chat messaging is not implemented yet.'),
              ),
            );
          },
          icon: const Icon(Icons.chat),
          label: const Text('Open group chat'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Coloors.greenDark,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ),
    );
  }
}
