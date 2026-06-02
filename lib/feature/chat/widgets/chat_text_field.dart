import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wasap2/common/enum/message_type.dart';

import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/utils/coloors.dart';
import 'package:wasap2/common/widgets/custom_icon_button.dart';
import 'package:wasap2/feature/auth/pages/image_picker_page.dart';
import 'package:wasap2/feature/chat/controller/chat_controller.dart';

class ChatTextField extends ConsumerStatefulWidget {
  const ChatTextField({
    super.key,
    required this.receiverId,
    required this.scrollController,
  });

  final String receiverId;
  final ScrollController scrollController;

  @override
  ConsumerState<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends ConsumerState<ChatTextField>
    with SingleTickerProviderStateMixin {
  late TextEditingController messageController;

  // Flutter Sound
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderReady = false;

  // Estado UI
  bool isMessageIconEnabled = false;
  double cardHeight = 0;
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;

  // Animación del punto rojo
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
    _initRecorder();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;
    await _recorder.openRecorder();
    setState(() => _recorderReady = true);
  }

  @override
  void dispose() {
    messageController.dispose();
    _recorder.closeRecorder();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Scroll al fondo ───────────────────────────────────────────────────────
  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Enviar texto ──────────────────────────────────────────────────────────
  void sendTextMessage() async {
    if (!isMessageIconEnabled) return;
    ref.read(chatControllerProvider).sendTextMessage(
          context: context,
          textMessage: messageController.text,
          receiverId: widget.receiverId,
        );
    messageController.clear();
    setState(() => isMessageIconEnabled = false);
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
  }

  // ── Enviar archivo ────────────────────────────────────────────────────────
  void sendFileMessage(var file, MessageType messageType) async {
    ref.read(chatControllerProvider).sendFileMessage(
          context,
          file,
          widget.receiverId,
          messageType,
        );
    await Future.delayed(const Duration(milliseconds: 500));
    _scrollToBottom();
  }

  // ── Galería ───────────────────────────────────────────────────────────────
  void sendImageMessageFromGallery() async {
    final image = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ImagePickerPage()),
    );
    if (image != null) {
      sendFileMessage(image, MessageType.image);
      setState(() => cardHeight = 0);
    }
  }

  // ── Cámara ────────────────────────────────────────────────────────────────
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo == null) return;
      sendFileMessage(File(photo.path), MessageType.image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  // ── Video desde galería o cámara ──────────────────────────────────────────
  Future<void> _pickVideoFromGallery() async {
    try {
      final XFile? video = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (video == null) return;
      sendFileMessage(File(video.path), MessageType.video);
      setState(() => cardHeight = 0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video error: $e')),
        );
      }
    }
  }

  Future<void> _recordVideoFromCamera() async {
    try {
      final XFile? video = await ImagePicker().pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );
      if (video == null) return;
      sendFileMessage(File(video.path), MessageType.video);
      setState(() => cardHeight = 0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video error: $e')),
        );
      }
    }
  }

  // ── Grabación ─────────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    if (!_recorderReady || _isRecording) return;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacADTS,
    );

    setState(() {
      _isRecording = true;
      _recordDuration = Duration.zero;
    });

    // Cronómetro: escucha el progreso del recorder
    _recorder.onProgress!.listen((event) {
      if (mounted && _isRecording) {
        setState(() => _recordDuration = event.duration ?? Duration.zero);
      }
    });

    await _recorder.setSubscriptionDuration(const Duration(seconds: 1));
  }

  Future<void> _stopAndSend() async {
    if (!_isRecording) return;
    final path = await _recorder.stopRecorder();
    setState(() => _isRecording = false);
    if (path == null) return;

    final file = File(path);
    if (await file.exists()) {
      sendFileMessage(file, MessageType.audio);
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
      _recordDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Menú adjuntos: ícono + texto ─────────────────────────────────────────
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
            color: context.theme.greyColor!.withOpacity(.2),
            width: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(text, style: TextStyle(color: context.theme.greyColor)),
      ],
    );
  }

  // ── Barra de grabación ────────────────────────────────────────────────────
  Widget _buildRecordingBar() {
    return Container(
      height: 62,
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.theme.chatTextFieldBg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // Cancelar
          GestureDetector(
            onTap: _cancelRecording,
            child: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 26),
          ),
          const SizedBox(width: 12),

          // Punto pulsante
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Cronómetro
          Text(
            _formatDuration(_recordDuration),
            style: TextStyle(
              fontSize: 16,
              color: context.theme.greyColor,
            ),
          ),

          const Spacer(),

          Text(
            'Desliza para cancelar',
            style: TextStyle(
              fontSize: 12,
              color: context.theme.greyColor!.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 10),

          // Enviar audio
          GestureDetector(
            onTap: _stopAndSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Coloors.greenDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Menú adjuntos animado ─────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: cardHeight,
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
                        background: const Color(0xFF7F66FE),
                      ),
                      _iconWithText(
                        onPressed: () {
                          setState(() => cardHeight = 0);
                          _recordVideoFromCamera();
                        },
                        icon: Icons.videocam,
                        text: 'Video',
                        background: const Color(0xFFFE2E74),
                      ),
                      _iconWithText(
                        onPressed: () {
                          setState(() => cardHeight = 0);
                          _pickImageFromCamera();
                        },
                        icon: Icons.camera_alt,
                        text: 'Camera',
                        background: const Color(0xFFFF6B35),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _iconWithText(
                        onPressed: sendImageMessageFromGallery,
                        icon: Icons.photo,
                        text: 'Gallery',
                        background: const Color(0xFFC861F9),
                      ),
                      _iconWithText(
                        onPressed: _pickVideoFromGallery,
                        icon: Icons.video_library,
                        text: 'Video lib',
                        background: const Color(0xFF1FA855),
                      ),
                      _iconWithText(
                        onPressed: () {},
                        icon: Icons.location_on,
                        text: 'Location',
                        background: const Color(0xFF009DE1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Barra de grabación O campo de texto ───────────────────────────
        if (_isRecording)
          _buildRecordingBar()
        else
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              children: [
                // Campo de texto
                Expanded(
                  child: TextFormField(
                    controller: messageController,
                    maxLines: 4,
                    minLines: 1,
                    onChanged: (value) {
                      setState(
                          () => isMessageIconEnabled = value.isNotEmpty);
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
                              onTap: () => setState(() => cardHeight == 0
                                  ? cardHeight = 220
                                  : cardHeight = 0),
                              icon: cardHeight == 0
                                  ? Icons.attach_file
                                  : Icons.close,
                              iconColor:
                                  Theme.of(context).listTileTheme.iconColor,
                            ),
                          ),
                          // Cámara — funcional
                          CustomIconButton(
                            onTap: _pickImageFromCamera,
                            icon: Icons.camera_alt_rounded,
                            iconColor:
                                Theme.of(context).listTileTheme.iconColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),

                // Botón send / mic
                GestureDetector(
                  // Tap: enviar texto (si hay texto escrito)
                  onTap: isMessageIconEnabled ? sendTextMessage : null,
                  // Long press: grabar audio (solo cuando no hay texto)
                  onLongPressStart: isMessageIconEnabled
                      ? null
                      : (_) => _startRecording(),
                  onLongPressEnd: isMessageIconEnabled
                      ? null
                      : (_) => _stopAndSend(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Coloors.greenDark,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isMessageIconEnabled
                          ? Icons.send_outlined
                          : Icons.mic_none_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}