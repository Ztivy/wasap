import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_clippers/custom_clippers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:wasap2/common/enum/message_type.dart' as my_type;
import 'package:wasap2/common/extension/custom_theme_extension.dart';
import 'package:wasap2/common/models/message_model.dart';

class MessageCard extends StatelessWidget {
  const MessageCard({
    Key? key,
    required this.isSender,
    required this.haveNip,
    required this.message,
  }) : super(key: key);

  final bool isSender;
  final bool haveNip;
  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      margin: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isSender ? 80 : haveNip ? 10 : 15,
        right: isSender ? haveNip ? 10 : 15 : 80,
      ),
      child: ClipPath(
        clipper: haveNip
            ? UpperNipMessageClipperTwo(
                isSender ? MessageType.send : MessageType.receive,
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
                borderRadius: haveNip ? null : BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black38)],
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: _buildContent(context),
              ),
            ),
            _buildTimestamp(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (message.type) {
      case my_type.MessageType.image:
        return Padding(
          padding: const EdgeInsets.only(right: 3, top: 3, left: 3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
              image: CachedNetworkImageProvider(message.textMessage),
            ),
          ),
        );

      case my_type.MessageType.audio:
        return _AudioBubble(url: message.textMessage, isSender: isSender);

      case my_type.MessageType.video:
        return _VideoBubble(url: message.textMessage);

      default:
        return Padding(
          padding: EdgeInsets.only(
            top: 8,
            bottom: 8,
            left: isSender ? 10 : 15,
            right: isSender ? 15 : 10,
          ),
          child: Text(
            '${message.textMessage}         ',
            style: const TextStyle(fontSize: 16),
          ),
        );
    }
  }

  Widget _buildTimestamp(BuildContext context) {
    final isText = message.type == my_type.MessageType.text;
    final isAudio = message.type == my_type.MessageType.audio;

    if (isText || isAudio) {
      return Positioned(
        bottom: 8,
        right: isSender ? 15 : 10,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat.Hm().format(message.timeSent),
              style: TextStyle(fontSize: 11, color: context.theme.greyColor),
            ),
            if (isSender) ...[
              const SizedBox(width: 3),
              Icon(
                message.isSeen ? Icons.done_all : Icons.done,
                size: 14,
                color: message.isSeen ? Colors.blue : context.theme.greyColor,
              ),
            ],
          ],
        ),
      );
    }

    // Para imagen y video: timestamp con gradiente encima
    return Positioned(
      bottom: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.only(left: 90, right: 10, bottom: 10, top: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(0, -1),
            end: const Alignment(1, 1),
            colors: [
              context.theme.greyColor!.withOpacity(0),
              context.theme.greyColor!.withOpacity(.5),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(300),
            bottomRight: Radius.circular(100),
          ),
        ),
        child: Text(
          DateFormat.Hm().format(message.timeSent),
          style: const TextStyle(fontSize: 11, color: Colors.white),
        ),
      ),
    );
  }
}

// ── Burbuja de Audio ──────────────────────────────────────────────────────────
class _AudioBubble extends StatefulWidget {
  const _AudioBubble({required this.url, required this.isSender});
  final String url;
  final bool isSender;

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _playerReady = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    setState(() => _playerReady = true);
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (!_playerReady) return;

    if (_isPlaying) {
      await _player.pausePlayer();
      setState(() => _isPlaying = false);
    } else {
      await _player.startPlayer(
        fromURI: widget.url,
        codec: Codec.aacADTS,
        whenFinished: () {
          if (mounted) setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        },
      );

      _player.onProgress!.listen((e) {
        if (mounted) {
          setState(() {
            _position = e.position;
            _duration = e.duration;
          });
        }
      });

      await _player.setSubscriptionDuration(
          const Duration(milliseconds: 100));
      setState(() => _isPlaying = true);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: 220,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 28),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isSender
                    ? Colors.white.withOpacity(0.3)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.isSender ? Colors.white : Colors.green,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor:
                        widget.isSender ? Colors.white : Colors.green,
                    inactiveTrackColor: Colors.grey.withOpacity(0.4),
                    thumbColor:
                        widget.isSender ? Colors.white : Colors.green,
                  ),
                  child: Slider(
                    value: progress,
                    onChanged: (_) {},
                  ),
                ),
                Text(
                  _isPlaying || _position > Duration.zero
                      ? _fmt(_position)
                      : _fmt(_duration),
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isSender
                        ? Colors.white70
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Burbuja de Video ──────────────────────────────────────────────────────────
class _VideoBubble extends StatefulWidget {
  const _VideoBubble({required this.url});
  final String url;

  @override
  State<_VideoBubble> createState() => _VideoBubbleState();
}

class _VideoBubbleState extends State<_VideoBubble> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });

    _controller.addListener(() {
      if (mounted) {
        setState(() => _isPlaying = _controller.value.isPlaying);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    _isPlaying ? _controller.pause() : _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 3, top: 3, left: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 240,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video o placeholder mientras carga
              _initialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    )
                  : Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),

              // Botón play/pause
              GestureDetector(
                onTap: _togglePlay,
                child: AnimatedOpacity(
                  opacity: _isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 32),
                  ),
                ),
              ),

              // Tap en el video para pause
              if (_isPlaying)
                GestureDetector(
                  onTap: _togglePlay,
                  child: Container(color: Colors.transparent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}