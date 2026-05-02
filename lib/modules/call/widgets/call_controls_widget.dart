import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/call_controller.dart';

class CallControlsWidget extends GetView<CallController> {
  const CallControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(() => _ControlButton(
                icon: controller.isMicOn.value ? Icons.mic : Icons.mic_off,
                label: 'Mic',
                isActive: controller.isMicOn.value,
                onTap: controller.toggleMic,
                activeColor: AppColors.accentGreen,
              )),
          const SizedBox(width: 16),
          Obx(() => _ControlButton(
                icon: controller.isCameraOn.value ? Icons.videocam : Icons.videocam_off,
                label: 'Camera',
                isActive: controller.isCameraOn.value,
                onTap: controller.toggleCamera,
                activeColor: AppColors.accentGreen,
              )),
          const SizedBox(width: 16),
          Obx(() => _ControlButton(
                icon: controller.isScreenSharing.value ? Icons.stop_screen_share : Icons.screen_share,
                label: 'Share',
                isActive: controller.isScreenSharing.value,
                onTap: controller.toggleScreenShare,
                activeColor: AppColors.primary,
              )),
          const SizedBox(width: 16),
          _ControlButton(
            icon: Icons.call_end,
            label: 'End Call',
            isActive: true,
            onTap: controller.endCall,
            activeColor: AppColors.accentRed,
            isEndCall: true,
          ),
          const SizedBox(width: 32),
          Container(width: 1, height: 40, color: AppColors.divider),
          const SizedBox(width: 32),
          Obx(() => _ControlButton(
                icon: Icons.chat,
                label: 'Chat',
                isActive: controller.isChatOpen.value,
                onTap: controller.toggleChat,
                activeColor: AppColors.primary,
              )),
          const SizedBox(width: 16),
          Obx(() => _ControlButton(
                icon: Icons.people,
                label: 'People',
                isActive: controller.isParticipantsOpen.value,
                onTap: controller.toggleParticipants,
                activeColor: AppColors.primary,
              )),
        ],
      ),
    );
  }
}

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final bool isEndCall;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    this.isEndCall = false,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isEndCall
        ? AppColors.accentRed
        : (widget.isActive ? widget.activeColor.withOpacity(0.2) : Colors.white12);
    final iconColor = widget.isEndCall
        ? Colors.white
        : (widget.isActive ? widget.activeColor : Colors.white54);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(isHovering ? 1.05 : 1.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isHovering ? bgColor.withOpacity(widget.isEndCall ? 0.8 : 0.4) : bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isActive ? Colors.white : Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
