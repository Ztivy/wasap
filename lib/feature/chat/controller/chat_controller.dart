import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wasap2/common/models/last_message_model.dart';
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

  Stream<List<LastMessageModel>> getAllLastMessageList(){
    return chatRepository.getAllLastMessageList();
  }

  void sendTextMessage({
    required BuildContext context,
    required String textMessage,
    required String receiverId,
  }){
    ref.read(userInfoAuthProvider).whenData((value)=>chatRepository.sendTextMessage(
      context: context,
      textMessage: textMessage,
      receiverId: receiverId,
      senderData: value!));
  }
}