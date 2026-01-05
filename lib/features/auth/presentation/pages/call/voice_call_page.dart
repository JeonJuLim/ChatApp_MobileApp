import 'dart:async';
import 'package:flutter/material.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';

enum CallUiState { calling, connected, noAnswer, ended }

class VoiceCallPage extends StatefulWidget {
  final String title;
  final String conversationId;
  final String myUserId;
  final bool isGroup;

  const VoiceCallPage({
    super.key,
    required this.title,
    required this.conversationId,
    required this.myUserId,
    required this.isGroup,
  });

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  CallUiState _state = CallUiState.calling;

  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  // Nếu muốn timeout "không bắt máy" sau X giây (ví dụ 30s)
  Timer? _ringTimeout;
  static const Duration _ringingMax = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();

    // Mặc định mở page là "đang gọi"
    _setCalling();

    // TODO: connect socket + emit call:start ở đây (phần 2)
    // _startCall();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ringTimeout?.cancel();
    // TODO: disconnect socket/listeners nếu có
    super.dispose();
  }

  // ============= UI STATE HELPERS =============
  void _setCalling() {
    _ticker?.cancel();
    _elapsed = Duration.zero;

    _ringTimeout?.cancel();
    _ringTimeout = Timer(_ringingMax, () {
      // Nếu quá thời gian mà chưa connected -> coi như noAnswer
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
        return _formatDuration(_elapsed); // 00:00, 00:01...
      case CallUiState.noAnswer:
        return 'Người nhận không bắt máy';
      case CallUiState.ended:
        return 'Đã kết thúc';
    }
  }

  IconData _statusIcon() {
    switch (_state) {
      case CallUiState.calling:
        return Icons.wifi_calling_3;
      case CallUiState.connected:
        return Icons.call;
      case CallUiState.noAnswer:
        return Icons.call_missed_outgoing;
      case CallUiState.ended:
        return Icons.call_end;
    }
  }

  Color _statusColor() {
    switch (_state) {
      case CallUiState.connected:
        return Colors.green;
      case CallUiState.noAnswer:
        return Colors.orange;
      case CallUiState.ended:
        return Colors.red;
      case CallUiState.calling:
      default:
        return AppColors.textSecondary;
    }
  }

  bool get _canEnd => _state != CallUiState.ended;

  // ============= BUTTON ACTIONS =============
  Future<void> _endAndBack() async {
    if (!_canEnd) {
      Navigator.pop(context);
      return;
    }

    // TODO: emit call:end qua socket, update CallLog ở backend
    // await _socket.emit('call:end', {...});

    _setEnded();
    if (mounted) Navigator.pop(context);
  }

  // ============= SOCKET HOOKS (bạn sẽ gọi các hàm này khi nhận event) =============
  void onSocketCallAccepted() {
    // B accept -> bắt đầu WebRTC + khi ICE/SDP xong có thể setConnected luôn
    _setConnected();
  }

  void onSocketCallNoAnswerOrTimeout() {
    _setNoAnswer();
  }

  void onSocketCallEndedByPeer() {
    _setEnded();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusText();
    final isTimer = _state == CallUiState.connected;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Voice Call',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                widget.title,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Conversation id (giữ lại cho debug)
              Text(
                'Conversation: ${widget.conversationId}',
                style: AppTextStyles.legalText.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Status icon
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 20,
                      offset: Offset(0, 8),
                      color: Color(0x1A000000),
                    ),
                  ],
                ),
                child: Icon(
                  _statusIcon(),
                  size: 40,
                  color: _statusColor(),
                ),
              ),

              const SizedBox(height: 16),

              // Status text or timer
              Text(
                status,
                style: isTimer
                    ? AppTextStyles.heading1.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 1.0,
                )
                    : AppTextStyles.bodyText.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // Sub status hint
              Text(
                _state == CallUiState.calling
                    ? 'Đang chờ người nhận trả lời'
                    : _state == CallUiState.connected
                    ? 'Cuộc gọi đang diễn ra'
                    : _state == CallUiState.noAnswer
                    ? 'Vui lòng thử lại sau'
                    : '',
                style: AppTextStyles.legalText.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // End button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _endAndBack,
                  icon: const Icon(Icons.call_end),
                  label: Text(
                    _state == CallUiState.noAnswer ? 'Quay lại' : 'Kết thúc',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              // Dev buttons (tạm) để test UI nhanh nếu chưa có socket
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _setCalling,
                    child: const Text('Test: Calling'),
                  ),
                  OutlinedButton(
                    onPressed: _setConnected,
                    child: const Text('Test: Connected'),
                  ),
                  OutlinedButton(
                    onPressed: _setNoAnswer,
                    child: const Text('Test: No Answer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
