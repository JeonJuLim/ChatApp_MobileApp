import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';

enum CallUiState { calling, connected, noAnswer, ended }

class VideoCallPage extends StatefulWidget {
  final String title;
  final String conversationId;
  final String myUserId;
  final bool isGroup;

  const VideoCallPage({
    super.key,
    required this.title,
    required this.conversationId,
    required this.myUserId,
    required this.isGroup,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  // ===== UI state
  CallUiState _state = CallUiState.calling;

  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  Timer? _ringTimeout;
  static const Duration _ringingMax = Duration(seconds: 30);

  // ===== WebRTC renderers
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  MediaStream? _localStream;

  bool _micEnabled = true;
  bool _camEnabled = true;
  bool _usingFrontCam = true;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _setCalling();
    _startLocalCamera(); // ✅ bật cam ngay

    // TODO:
    // 1) connect socket
    // 2) emit call:start (type=video)
    // 3) implement signaling offer/answer/ice để set remote stream
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ringTimeout?.cancel();

    _localRenderer.dispose();
    _remoteRenderer.dispose();

    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();

    super.dispose();
  }

  // =====================
  // Local media
  // =====================
  Future<void> _startLocalCamera() async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': _usingFrontCam ? 'user' : 'environment',
          'width': 640,
          'height': 480,
          'frameRate': 24,
        },
      });

      _localStream = stream;
      _localRenderer.srcObject = stream;

      setState(() {});
    } catch (e) {
      // Nếu permission thiếu, sẽ rơi vào đây
      // Bạn có thể show dialog thông báo.
      // ignore: avoid_print
      print('getUserMedia error: $e');
    }
  }

  void _toggleMic() {
    final stream = _localStream;
    if (stream == null) return;

    _micEnabled = !_micEnabled;
    for (final t in stream.getAudioTracks()) {
      t.enabled = _micEnabled;
    }
    setState(() {});
  }

  void _toggleCamera() {
    final stream = _localStream;
    if (stream == null) return;

    _camEnabled = !_camEnabled;
    for (final t in stream.getVideoTracks()) {
      t.enabled = _camEnabled;
    }
    setState(() {});
  }

  Future<void> _switchCamera() async {
    final stream = _localStream;
    if (stream == null) return;

    final tracks = stream.getVideoTracks();
    if (tracks.isEmpty) return;

    _usingFrontCam = !_usingFrontCam;
    await Helper.switchCamera(tracks.first);
    setState(() {});
  }

  // =====================
  // UI State helpers
  // =====================
  void _setCalling() {
    _ticker?.cancel();
    _elapsed = Duration.zero;

    _ringTimeout?.cancel();
    _ringTimeout = Timer(_ringingMax, () {
      if (mounted && _state == CallUiState.calling) {
        setState(() => _state = CallUiState.noAnswer);
      }
    });

    setState(() => _state = CallUiState.calling);
  }

  void _setConnected() {
    _ringTimeout?.cancel();
    _ticker?.cancel();
    _elapsed = Duration.zero;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });

    setState(() => _state = CallUiState.connected);
  }

  void _setNoAnswer() {
    _ringTimeout?.cancel();
    _ticker?.cancel();
    setState(() => _state = CallUiState.noAnswer);
  }

  void _setEnded() {
    _ringTimeout?.cancel();
    _ticker?.cancel();
    setState(() => _state = CallUiState.ended);
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _statusText() {
    switch (_state) {
      case CallUiState.calling:
        return 'Đang gọi...';
      case CallUiState.connected:
        return _formatDuration(_elapsed);
      case CallUiState.noAnswer:
        return 'Người nhận không bắt máy';
      case CallUiState.ended:
        return 'Đã kết thúc';
    }
  }

  String _hintText() {
    switch (_state) {
      case CallUiState.calling:
        return 'Đang chờ người nhận trả lời';
      case CallUiState.connected:
        return 'Cuộc gọi video đang diễn ra';
      case CallUiState.noAnswer:
        return 'Vui lòng thử lại sau';
      case CallUiState.ended:
        return '';
    }
  }

  bool get _isTimer => _state == CallUiState.connected;

  // =====================
  // Socket hooks (gọi từ listener)
  // =====================
  void onSocketCallAccepted() => _setConnected();
  void onSocketCallNoAnswerOrTimeout() => _setNoAnswer();
  void onSocketCallEndedByPeer() {
    _setEnded();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _endAndBack() async {
    // TODO: emit call:end + duration
    _setEnded();
    if (mounted) Navigator.pop(context);
  }

  // =====================
  // Remote stream gắn vào đây khi WebRTC connected
  // =====================
  void setRemoteStream(MediaStream remoteStream) {
    _remoteRenderer.srcObject = remoteStream;
    // Khi có remote stream thường coi như connected
    _setConnected();
  }

  @override
  Widget build(BuildContext context) {
    // Remote video full screen; nếu chưa có remote thì nền đen
    final hasRemote = _remoteRenderer.srcObject != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Video Call',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          // ===== Remote video =====
          Positioned.fill(
            child: hasRemote
                ? RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
                : Container(color: Colors.black),
          ),

          // ===== Overlay status =====
          Positioned(
            left: 18,
            right: 18,
            top: 18,
            child: Column(
              children: [
                Text(
                  widget.title,
                  style: AppTextStyles.heading2.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _statusText(),
                  style: _isTimer
                      ? AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    letterSpacing: 1.0,
                  )
                      : AppTextStyles.legalText.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _hintText(),
                  style: AppTextStyles.legalText.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // ===== Local preview (luôn bật cam local) =====
          Positioned(
            right: 14,
            top: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 110,
                height: 150,
                color: Colors.black,
                child: _localRenderer.srcObject == null
                    ? const Center(child: CircularProgressIndicator())
                    : RTCVideoView(
                  _localRenderer,
                  mirror: _usingFrontCam,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),

          // ===== Controls =====
          Positioned(
            left: 0,
            right: 0,
            bottom: 26,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleBtn(
                  icon: _micEnabled ? Icons.mic : Icons.mic_off,
                  onTap: _toggleMic,
                ),
                const SizedBox(width: 14),
                _CircleBtn(
                  icon: Icons.call_end,
                  bg: Colors.red,
                  fg: Colors.white,
                  onTap: _endAndBack,
                  size: 64,
                ),
                const SizedBox(width: 14),
                _CircleBtn(
                  icon: _camEnabled ? Icons.videocam : Icons.videocam_off,
                  onTap: _toggleCamera,
                ),
                const SizedBox(width: 14),
                _CircleBtn(
                  icon: Icons.cameraswitch,
                  onTap: _switchCamera,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? bg;
  final Color? fg;
  final double size;

  const _CircleBtn({
    required this.icon,
    required this.onTap,
    this.bg,
    this.fg,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final background = bg ?? Colors.white;
    final foreground = fg ?? AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 8),
              color: Color(0x14000000),
            ),
          ],
        ),
        child: Icon(icon, color: foreground),
      ),
    );
  }
}
