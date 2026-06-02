import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wasap2/common/enum/message_type.dart';
import 'package:wasap2/common/models/group_model.dart';
import 'package:wasap2/common/models/last_message_model.dart';
import 'package:wasap2/common/models/message_model.dart';
import 'package:wasap2/feature/auth/controller/auth_controller.dart';
import 'package:wasap2/feature/chat/repository/chat_repository.dart';

final chatControllerProvider = Provider((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return ChatController(
    chatRepository: chatRepository,
    ref: ref,
  );
});

class ChatController {
  final ChatRepository chatRepository;
  final Ref ref;

  ChatController({required this.chatRepository, required this.ref});

  // Marcar mensaje como visto
  Future<void> setChatMessageSeen(
    BuildContext context,
    String receiverId,
    String messageId,
  ) {
    return chatRepository.setChatMessageSeen(
        context, receiverId, messageId);
  }

  // Enviar archivo
  void sendFileMessage(
    BuildContext context,
    var file,
    String receiverId,
    MessageType messageType,
  ) {
    ref.read(userInfoAuthProvider).whenData((senderData) {
      return chatRepository.sendFileMessage(
        file: file,
        context: context,
        receiverId: receiverId,
        senderData: senderData!,
        ref: ref,
        messageType: messageType,
      );
    });
  }

  // Stream mensajes 1 a 1
  Stream<List<MessageModel>> getAllOneToOneMessage(String receiverId) {
    return chatRepository.getAllOneToOneMessage(receiverId);
  }

  // Stream lista últimos mensajes
  Stream<List<LastMessageModel>> getAllLastMessageList() {
    return chatRepository.getAllLastMessageList();
  }

  Stream<List<GroupModel>> getAllGroupChatList() {
    return chatRepository.getAllGroupChatList();
  }

  // Enviar texto
  void sendTextMessage({
    required BuildContext context,
    required String textMessage,
    required String receiverId,
  }) {
    ref.read(userInfoAuthProvider).whenData((value) =>
        chatRepository.sendTextMessage(
          context: context,
          textMessage: textMessage,
          receiverId: receiverId,
          senderData: value!,
        ));
  }
}