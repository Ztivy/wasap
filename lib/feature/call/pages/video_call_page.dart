import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIGURACIÓN AGORA
// ─────────────────────────────────────────────────────────────────────────────
const String _agoraAppId = '97a6d6c864d54b39a59fec8ae963e7ed';

// Token generado en el panel de Agora para el canal 'testcall'
const String _agoraToken =
    '007eJxTYPCs9NdMPtP5tmPj6vfn9Zav9WxcKfeHYeOc7IWcyUopmt0KDJbmiWYpZskWZiYppiZJxpaJppZpqckWiamWZsap5qkpkwLkshoCGRnyhKUYGRkgEMTnYChJLS5JTszJYWAAAMgSICU=';

// ⚠️  IMPORTANTE: Este canal DEBE coincidir con el que usaste
//     para generar el token en el panel de Agora.
//     Ambos dispositivos se unen al mismo canal → se conectan.
const String _testChannel = 'testcall';
// ─────────────────────────────────────────────────────────────────────────────

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({
    super.key,
    required this.channelId,   // recibido desde chat_page (se ignora por ahora)
    required this.calleeName,
    this.calleeAvatarUrl,
  });

  final String channelId;
  final String calleeName;
  final String? calleeAvatarUrl;

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  RtcEngine? _engine;
  bool _engineReady = false;
  int? _remoteUid;
  bool _localJoined = false;
  bool _mutedAudio = false;
  bool _mutedVideo = false;
  bool _speakerOn = true;
  bool _frontCamera = true;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.camera, Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: _agoraAppId));
    await _engine!.enableVideo();
    await _engine!.startPreview();

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint('✅ Local joined uid=${connection.localUid}');
          if (mounted) setState(() => _localJoined = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          debugPrint('✅ Remote joined uid=$remoteUid');
          if (mounted) setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          debugPrint('❌ Remote left uid=$remoteUid reason=$reason');
          if (mounted) setState(() => _remoteUid = null);
          _endCall();
        },
        onError: (err, msg) {
          debugPrint('🔴 Agora error [$err]: $msg');
          // Error 110 = token expirado
          // Error 101 = App ID inválido
          // Error 17  = canal inválido
        },
        onTokenPrivilegeWillExpire: (connection, token) {
          debugPrint('⚠️ Token por expirar');
        },
      ),
    );

    // ⚠️  Usamos _testChannel (no widget.channelId) para que
    //     coincida con el token que generaste en el panel.
    await _engine!.joinChannel(
      token: _agoraToken,
      channelId: _testChannel,
      uid: 0,
      options: const ChannelMediaOptions(
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    if (mounted) setState(() => _engineReady = true);
  }

  Future<void> _endCall() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleMuteAudio() async {
    _mutedAudio = !_mutedAudio;
    await _engine?.muteLocalAudioStream(_mutedAudio);
    setState(() {});
  }

  Future<void> _toggleMuteVideo() async {
    _mutedVideo = !_mutedVideo;
    await _engine?.muteLocalVideoStream(_mutedVideo);
    setState(() {});
  }

  Future<void> _toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    await _engine?.setEnableSpeakerphone(_speakerOn);
    setState(() {});
  }

  Future<void> _switchCamera() async {
    _frontCamera = !_frontCamera;
    await _engine?.switchCamera();
    setState(() {});
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: _testChannel),
        ),
      );
    }
    return Container(
      color: const Color(0xFF0B141A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 64,
            backgroundColor: const Color(0xFF1F2C34),
            backgroundImage: widget.calleeAvatarUrl != null
                ? NetworkImage(widget.calleeAvatarUrl!)
                : null,
            child: widget.calleeAvatarUrl == null
                ? const Icon(Icons.person, size: 64, color: Colors.white54)
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            widget.calleeName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            _localJoined ? 'Llamando...' : 'Conectando...',
            style: const TextStyle(color: Colors.white60, fontSize: 16),
          ),
          const SizedBox(height: 8),
          // Indicador visual de que está intentando conectar
          if (!_localJoined)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: Colors.white54, strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _localVideo() {
    if (!_engineReady || _mutedVideo) {
      return Container(
        color: const Color(0xFF1F2C34),
        child:
            const Icon(Icons.videocam_off, color: Colors.white54, size: 32),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  Widget _buildControls() {
    return AnimatedOpacity(
      opacity: _controlsVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ControlButton(
              icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
              label: _speakerOn ? 'Speaker' : 'Earpiece',
              onTap: _toggleSpeaker,
            ),
            _ControlButton(
              icon: _mutedAudio ? Icons.mic_off : Icons.mic,
              label: _mutedAudio ? 'Unmute' : 'Mute',
              onTap: _toggleMuteAudio,
              active: _mutedAudio,
            ),
            _ControlButton(
              icon: Icons.call_end,
              label: 'End',
              onTap: _endCall,
              isEnd: true,
            ),
            _ControlButton(
              icon: _mutedVideo ? Icons.videocam_off : Icons.videocam,
              label: _mutedVideo ? 'Show' : 'Hide',
              onTap: _toggleMuteVideo,
              active: _mutedVideo,
            ),
            _ControlButton(
              icon: Icons.flip_camera_ios,
              label: 'Flip',
              onTap: _switchCamera,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () =>
            setState(() => _controlsVisible = !_controlsVisible),
        child: Stack(
          children: [
            Positioned.fill(child: _remoteVideo()),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              width: 110,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _localVideo(),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  widget.calleeName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildControls(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.isEnd = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool isEnd;

  @override
  Widget build(BuildContext context) {
    final bgColor = isEnd
        ? const Color(0xFFE53935)
        : active
            ? Colors.white24
            : Colors.white12;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}