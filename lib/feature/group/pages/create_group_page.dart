import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/models/group_model.dart';
import 'package:wasap2/common/models/user_model.dart';
import 'package:wasap2/common/utils/coloors.dart';
import 'package:wasap2/common/widgets/custom_elevated_button.dart';

class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {
  final TextEditingController _nameController = TextEditingController();
  final List<UserModel> _selectedContacts = [];
  List<UserModel> _allContacts = [];
  bool _hidePhoneNumbers = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').get();
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    setState(() {
      _allContacts = snapshot.docs
          .map((d) => UserModel.fromMap(d.data()))
          .where((u) => u.uId != currentUid)
          .toList();
    });
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one contact')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final groupId = const Uuid().v1();
    final membersUid = [
      currentUid,
      ..._selectedContacts.map((c) => c.uId),
    ];

    final group = GroupModel(
      groupId: groupId,
      groupName: _nameController.text.trim(),
      groupPicture: '',
      creatorId: currentUid,
      hidePhoneNumbers: _hidePhoneNumbers,
      membersUid: membersUid,
      lastMessage: '',
      timeSent: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .set(group.toMap());

    for (final uid in membersUid) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'groupId': FieldValue.arrayUnion([groupId])
      });
    }

    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Group "${_nameController.text.trim()}" created!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group',
            style: TextStyle(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Group name',
                    hintStyle:
                        TextStyle(color: context.theme.greyColor),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Coloors.greenDark),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Coloors.greenDark, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Hide phone numbers from members',
                        style:
                            TextStyle(color: context.theme.greyColor),
                      ),
                    ),
                    Switch(
                      value: _hidePhoneNumbers,
                      onChanged: (val) =>
                          setState(() => _hidePhoneNumbers = val),
                      activeColor: Coloors.greenDark,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_selectedContacts.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: _selectedContacts
                        .map((c) => Chip(
                              label: Text(c.username),
                              onDeleted: () => setState(
                                  () => _selectedContacts.remove(c)),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 10),
                Text(
                  'Select participants',
                  style: TextStyle(
                    color: context.theme.greyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _allContacts.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Coloors.greenDark))
                : ListView.builder(
                    itemCount: _allContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _allContacts[index];
                      final isSelected =
                          _selectedContacts.contains(contact);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              contact.profileImageUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      contact.profileImageUrl)
                                  : null,
                          child: contact.profileImageUrl.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(contact.username),
                        subtitle: Text(contact.phoneNumber,
                            style: TextStyle(
                                color: context.theme.greyColor)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: Coloors.greenDark)
                            : const Icon(Icons.circle_outlined),
                        onTap: () => setState(() {
                          isSelected
                              ? _selectedContacts.remove(contact)
                              : _selectedContacts.add(contact);
                        }),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: Coloors.greenDark)
                : CustomElevatedButton(
                    onPressed: _createGroup,
                    text: 'CREATE GROUP',
                  ),
          ),
        ],
      ),
    );
  }
}