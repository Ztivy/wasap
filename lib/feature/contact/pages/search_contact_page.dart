import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/models/user_model.dart';
import 'package:wasap2/common/routes/routes.dart';
import 'package:wasap2/common/utils/coloors.dart';

class SearchContactPage extends StatefulWidget {
  const SearchContactPage({super.key});

  @override
  State<SearchContactPage> createState() => _SearchContactPageState();
}

class _SearchContactPageState extends State<SearchContactPage> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _foundUsers = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSearched = false;

  Future<void> _searchUser(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _foundUsers = [];
      _errorMessage = null;
      _hasSearched = false;
    });

    try {
      // Buscar por username — trae todos los que comiencen con el texto
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('username')
          .startAt([query.trim()])
          .endAt(['${query.trim()}\uf8ff'])
          .get();

      final users = result.docs
          .map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();

      setState(() {
        _foundUsers = users;
        _hasSearched = true;
        _isLoading = false;
        if (users.isEmpty) {
          _errorMessage = 'No user found with that name';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching: ${e.toString()}';
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Find Contact',
          style: TextStyle(color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search by username',
              style: TextStyle(
                color: context.theme.greyColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Enter username...',
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
                    onSubmitted: _searchUser,
                    onChanged: (value) {
                      if (value.trim().length >= 2) {
                        _searchUser(value);
                      } else {
                        setState(() {
                          _foundUsers = [];
                          _hasSearched = false;
                          _errorMessage = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => _searchUser(_searchController.text),
                  icon: const Icon(Icons.search, color: Coloors.greenDark),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child:
                    CircularProgressIndicator(color: Coloors.greenDark),
              ),

            if (!_isLoading && _hasSearched && _errorMessage != null)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Icon(Icons.person_off,
                        size: 60,
                        color:
                            context.theme.greyColor!.withOpacity(0.4)),
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: context.theme.greyColor),
                    ),
                  ],
                ),
              ),

            if (!_isLoading && _foundUsers.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _foundUsers.length,
                  itemBuilder: (context, index) {
                    final user = _foundUsers[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            context.theme.greyColor!.withOpacity(0.3),
                        backgroundImage: user.profileImageUrl.isNotEmpty
                            ? CachedNetworkImageProvider(
                                user.profileImageUrl)
                            : null,
                        child: user.profileImageUrl.isEmpty
                            ? const Icon(Icons.person,
                                size: 30, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        user.username,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        user.active ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: user.active
                              ? Coloors.greenDark
                              : context.theme.greyColor,
                          fontSize: 12,
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          Routes.chat,
                          arguments: user,
                        ),
                        child: const Text('Message'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}