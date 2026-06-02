import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_clippers/custom_clippers.dart' as custom_clippers;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';
import 'package:wasap2/common/enum/message_type.dart';
import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/models/group_model.dart';
import 'package:wasap2/common/models/message_model.dart';
import 'package:wasap2/common/models/user_model.dart';
import 'package:wasap2/common/utils/coloors.dart';
import 'package:wasap2/common/widgets/custom_icon_button.dart';
import 'package:wasap2/feature/auth/pages/image_picker_page.dart';
import 'package:wasap2/feature/chat/widgets/show_date_card.dart';
import 'package:wasap2/feature/chat/widgets/yellow_card.dart';

// ── Provider para mensajes grupales ──────────────────────────────────────────
final groupMessagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, groupId) {
  return FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('messages')
      .orderBy('timeSent')
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => MessageModel.fromMap(d.data())).toList());
});

// ── Provider para miembros del grupo ─────────────────────────────────────────
final groupMembersProvider =
    FutureProvider.family<Map<String, UserModel>, List<String>>(
        (ref, uids) async {
  if (uids.isEmpty) return {};
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .where('uId', whereIn: uids)
      .get();
  return {
    for (var doc in snap.docs)
      doc.id: UserModel.fromMap(doc.data())
  };
});

// ─────────────────────────────────────────────────────────────────────────────

class GroupChatPage extends ConsumerStatefulWidget {
  const GroupChatPage({super.key, required this.group});

  final GroupModel group;

  @override
  ConsumerState<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends ConsumerState<GroupChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  bool _isMessageEnabled = false;
  double _cardHeight = 0;

  // ── Enviar mensaje de texto ───────────────────────────────────────────────
  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final messageId = const Uuid().v1();
    final timeSent = DateTime.now();

    final message = MessageModel(
      senderId: uid,
      receiverId: widget.group.groupId,
      textMessage: text,
      type: MessageType.text,
      timeSent: timeSent,
      messageId: messageId,
      isSeen: false,
    );

    _messageController.clear();
    setState(() => _isMessageEnabled = false);

    final batch = FirebaseFirestore.instance.batch();

    // Guardar en subcolección de mensajes del grupo
    batch.set(
      FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.groupId)
          .collection('messages')
          .doc(messageId),
      message.toMap(),
    );

    // Actualizar último mensaje del grupo
    batch.update(
      FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.groupId),
      {
        'lastMessage': text,
        'timeSent': timeSent.millisecondsSinceEpoch,
      },
    );

    await batch.commit();

    await Future.delayed(const Duration(milliseconds: 100));
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Enviar imagen ─────────────────────────────────────────────────────────
  Future<void> _sendImageFromGallery() async {
    final image = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ImagePickerPage()),
    );
    if (!mounted) return;
    if (image != null) {
      setState(() => _cardHeight = 0);
      // Aquí puedes conectar con supabase igual que en ChatTextField
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Image upload coming soon for group chats')),
      );
    }
  }

  // ── Scroll al final cuando llegan mensajes nuevos ─────────────────────────
  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ── Widget de ícono con texto (attach menu) ───────────────────────────────
  Widget _iconWithText({
    required VoidCallback onPressed,
    required IconData icon,
    required String text,
    required Color background,
  }) {
    return Column(
      children: [
        CustomIconButton(
          onTap: onPressed,
          icon: icon,
          background: background,
          minWidth: 50,
          iconColor: Colors.white,
          border: Border.all(
            color: context.theme.greyColor!.withAlpha(51),
            width: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(text, style: TextStyle(color: context.theme.greyColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final messagesAsync =
        ref.watch(groupMessagesProvider(widget.group.groupId));
    final membersAsync =
        ref.watch(groupMembersProvider(widget.group.membersUid));

    return Scaffold(
      backgroundColor: context.theme.chatPageBgColor,

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBar: AppBar(
        leadingWidth: 30,
        leading: const BackButton(color: Colors.white),
        title: Row(
          children: [
            // Foto del grupo
            widget.group.groupPicture.isNotEmpty
                ? CircleAvatar(
                    radius: 18,
                    backgroundImage: CachedNetworkImageProvider(
                        widget.group.groupPicture),
                  )
                : CircleAvatar(
                    radius: 18,
                    backgroundColor: Coloors.greenDark.withAlpha(77),
                    child: const Icon(Icons.group,
                        color: Colors.white, size: 20),
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.groupName,
                    style: const TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Subtítulo: "X participants"
                  Text(
                    '${widget.group.membersUid.length} participants',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CustomIconButton(
            onTap: () {},
            icon: Icons.video_call,
            iconColor: Colors.white,
          ),
          CustomIconButton(
            onTap: () {},
            icon: Icons.call,
            iconColor: Colors.white,
          ),
          CustomIconButton(
            onTap: () {},
            icon: Icons.more_vert,
            iconColor: Colors.white,
          ),
        ],
      ),

      // ── Body ───────────────────────────────────────────────────────────────
      body: Stack(
        children: [
          // Fondo con doodle (igual que chat_page)
          Image(
            height: double.maxFinite,
            width: double.maxFinite,
            image: const AssetImage('assets/images/doodle_bg.png'),
            fit: BoxFit.cover,
            color: context.theme.chatPageDoodleColor,
          ),

          // Lista de mensajes
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: messagesAsync.when(
              loading: () => _buildShimmerList(),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (messages) {
                _scrollToBottom();
                return membersAsync.when(
                  loading: () => _buildShimmerList(),
                  error: (e, _) =>
                      Center(child: Text(e.toString())),
                  data: (membersMap) {
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages yet.\nSay hello! 👋',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      padding: const EdgeInsets.only(top: 8),
                      itemBuilder: (_, index) {
                        final message = messages[index];
                        final isSender =
                            message.senderId == currentUid;
                        final sender =
                            membersMap[message.senderId];

                        final haveNip = (index == 0) ||
                            (message.senderId !=
                                messages[index - 1].senderId);

                        final isShowDateCard = (index == 0) ||
                            (message.timeSent.day >
                                messages[index - 1]
                                    .timeSent
                                    .day);

                        return Column(
                          children: [
                            if (index == 0) const yellowCard(),
                            if (isShowDateCard)
                              ShowDateCard(
                                  date: message.timeSent),
                            _GroupMessageCard(
                              message: message,
                              isSender: isSender,
                              haveNip: haveNip,
                              senderName: isSender
                                  ? null
                                  : (sender?.username ??
                                      'Unknown'),
                              showSenderName: !isSender &&
                                  haveNip,
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Campo de texto anclado al fondo
          Align(
            alignment: const Alignment(0, 1),
            child: _buildTextField(),
          ),
        ],
      ),
    );
  }

  // ── Shimmer de carga ──────────────────────────────────────────────────────
  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 12,
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
            clipper: custom_clippers.UpperNipMessageClipperTwo(
              random.isEven
                  ? custom_clippers.MessageType.send
                  : custom_clippers.MessageType.receive,
              nipWidth: 8,
              nipHeight: 10,
              bubbleRadius: 12,
            ),
            child: Shimmer.fromColors(
              baseColor: random.isEven
                  ? context.theme.greyColor!.withAlpha(102)
                  : context.theme.greyColor!.withAlpha(51),
              highlightColor: random.isEven
                  ? context.theme.greyColor!.withAlpha(102)
                  : context.theme.greyColor!.withAlpha(77),
              child: Container(
                height: 40,
                width: 170 + double.parse((random * 2).toString()),
                color: Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── TextField + attach menu ───────────────────────────────────────────────
  Widget _buildTextField() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Menú de adjuntos animado
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _cardHeight,
          width: double.maxFinite,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: context.theme.receiverChatCardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _iconWithText(
                          onPressed: () {},
                          icon: Icons.book,
                          text: 'File',
                          background: const Color(0xFF7F66FE)),
                      _iconWithText(
                          onPressed: () {},
                          icon: Icons.camera_alt,
                          text: 'Camera',
                          background: const Color(0xFFFE2E74)),
                      _iconWithText(
                          onPressed: _sendImageFromGallery,
                          icon: Icons.photo,
                          text: 'Gallery',
                          background: const Color(0xFFC861F9)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _iconWithText(
                          onPressed: () {},
                          icon: Icons.headphones,
                          text: 'Audio',
                          background: const Color(0xFFF96533)),
                      _iconWithText(
                          onPressed: () {},
                          icon: Icons.location_on,
                          text: 'Location',
                          background: const Color(0xFF1FA855)),
                      _iconWithText(
                          onPressed: () {},
                          icon: Icons.person,
                          text: 'Contact',
                          background: const Color(0xFF009DE1)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Fila del input
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  onChanged: (value) {
                    setState(() =>
                        _isMessageEnabled = value.isNotEmpty);
                  },
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle:
                        TextStyle(color: context.theme.greyColor),
                    filled: true,
                    fillColor: context.theme.chatTextFieldBg,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                          style: BorderStyle.none, width: 0),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    prefixIcon: Material(
                      color: Colors.transparent,
                      child: CustomIconButton(
                        onTap: () {},
                        icon: Icons.emoji_emotions_outlined,
                        iconColor:
                            Theme.of(context).listTileTheme.iconColor,
                      ),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RotatedBox(
                          quarterTurns: 45,
                          child: CustomIconButton(
                            onTap: () => setState(() => _cardHeight ==
                                    0
                                ? _cardHeight = 220
                                : _cardHeight = 0),
                            icon: _cardHeight == 0
                                ? Icons.attach_file
                                : Icons.close,
                            iconColor: Theme.of(context)
                                .listTileTheme
                                .iconColor,
                          ),
                        ),
                        CustomIconButton(
                          onTap: () {},
                          icon: Icons.camera_alt_rounded,
                          iconColor: Theme.of(context)
                              .listTileTheme
                              .iconColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              CustomIconButton(
                onTap: _sendTextMessage,
                icon: _isMessageEnabled
                    ? Icons.send_outlined
                    : Icons.mic_none_outlined,
                background: Coloors.greenDark,
                iconColor: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Burbuja de mensaje grupal ─────────────────────────────────────────────────
class _GroupMessageCard extends StatelessWidget {
  const _GroupMessageCard({
    required this.message,
    required this.isSender,
    required this.haveNip,
    this.senderName,
    required this.showSenderName,
  });

  final MessageModel message;
  final bool isSender;
  final bool haveNip;
  final String? senderName;
  final bool showSenderName;

  // Colores distintos por nombre de remitente
  Color _nameColor(String name) {
    final colors = [
      const Color(0xFF00BCD4),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFFFF5722),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment:
          isSender ? Alignment.centerRight : Alignment.centerLeft,
      margin: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isSender ? 80 : haveNip ? 10 : 15,
        right: isSender ? haveNip ? 10 : 15 : 80,
      ),
      child: ClipPath(
        clipper: haveNip
            ? custom_clippers.UpperNipMessageClipperTwo(
                isSender
                    ? custom_clippers.MessageType.send
                    : custom_clippers.MessageType.receive,
                nipWidth: 8,
                nipHeight: 10,
                bubbleRadius: 12,
              )
            : null,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isSender
                    ? context.theme.senderChatCardBg
                    : context.theme.receiverChatCardBg,
                borderRadius:
                    haveNip ? null : BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black38)],
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: message.type == MessageType.image
                    ? Padding(
                        padding: const EdgeInsets.only(
                            right: 3, top: 3, left: 3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image(
                            image: CachedNetworkImageProvider(
                                message.textMessage),
                          ),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.only(
                          top: showSenderName ? 4 : 8,
                          bottom: 8,
                          left: isSender ? 10 : 15,
                          right: isSender ? 15 : 10,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Nombre del remitente (solo en mensajes recibidos)
                            if (showSenderName &&
                                senderName != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 3),
                                child: Text(
                                  senderName!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _nameColor(senderName!),
                                  ),
                                ),
                              ),
                            Text(
                              '${message.textMessage}         ',
                              style:
                                  const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            // Hora + doble check
            Positioned(
              bottom: message.type == MessageType.text ? 8 : 4,
              right: message.type == MessageType.text
                  ? (isSender ? 15 : 10)
                  : 4,
              child: message.type == MessageType.text
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat.Hm()
                              .format(message.timeSent),
                          style: TextStyle(
                            fontSize: 11,
                            color: context.theme.greyColor,
                          ),
                        ),
                        if (isSender) ...[
                          const SizedBox(width: 3),
                          Icon(
                            message.isSeen
                                ? Icons.done_all
                                : Icons.done,
                            size: 14,
                            color: message.isSeen
                                ? Colors.blue
                                : context.theme.greyColor,
                          ),
                        ],
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.only(
                          left: 90,
                          right: 10,
                          bottom: 10,
                          top: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: const Alignment(0, -1),
                          end: const Alignment(1, 1),
                          colors: [
                            context.theme.greyColor!
                                .withAlpha(0),
                            context.theme.greyColor!
                                .withAlpha(128),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(300),
                          bottomRight: Radius.circular(100),
                        ),
                      ),
                      child: Text(
                        DateFormat.Hm()
                            .format(message.timeSent),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}