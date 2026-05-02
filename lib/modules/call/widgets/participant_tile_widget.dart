import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ParticipantTileWidget extends StatefulWidget {
  final String name;
  final bool isMuted;
  final bool isHost;

  const ParticipantTileWidget({
    super.key,
    required this.name,
    this.isMuted = false,
    this.isHost = false,
  });

  @override
  State<ParticipantTileWidget> createState() => _ParticipantTileWidgetState();
}

class _ParticipantTileWidgetState extends State<ParticipantTileWidget> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHovering ? AppColors.background : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(
                widget.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (widget.isHost)
                    Text(
                      'Host',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              widget.isMuted ? Icons.mic_off : Icons.mic,
              color: widget.isMuted ? AppColors.accentRed : AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
