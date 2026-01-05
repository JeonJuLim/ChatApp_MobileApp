import 'package:flutter/material.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';

class VideoCallPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Conversation: $conversationId',
                style: AppTextStyles.legalText.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'UI Video Call (placeholder)\nChưa implement call logic.',
                style: AppTextStyles.legalText.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.call_end),
                label: const Text('End / Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
