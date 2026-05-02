import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_util.dart';
import '../controllers/call_controller.dart';
import '../widgets/call_controls_widget.dart';
import '../widgets/chat_panel_widget.dart';
import '../widgets/participant_tile_widget.dart';
import '../widgets/video_view_widget.dart';

class CallView extends GetView<CallController> {
  const CallView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtil.isDesktop(context);
    final isTablet = ResponsiveUtil.isTablet(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.hasError.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.accentRed, size: 48),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(fontSize: 18, color: AppColors.accentRed),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }

        if (controller.isConnecting.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 24),
                Text('Connecting to room...', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        return SafeArea(
          child: Stack(
            children: [
              Row(
                children: [
                  // Participants Sidebar
                  if (controller.isParticipantsOpen.value && (isDesktop || isTablet))
                    _buildParticipantsPanel(),

                  // Main Video Area
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Stack(
                        children: [
                          // Remote Video
                          VideoViewWidget(
                            renderer: controller.remoteRenderer,
                            label: 'Remote Participant',
                          ),
                          
                          // Local Video (PiP)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              width: 200,
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: VideoViewWidget(
                                renderer: controller.localRenderer,
                                isLocal: true,
                                isMuted: !controller.isMicOn.value,
                                label: 'You',
                              ),
                            ),
                          ),

                          // Room ID Pill
                          Positioned(
                            top: 16,
                            left: 16,
                            child: _buildRoomIdPill(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Chat Sidebar
                  if (controller.isChatOpen.value && isDesktop)
                    const Padding(
                      padding: EdgeInsets.only(top: 16, bottom: 100, right: 16),
                      child: ChatPanelWidget(),
                    ),
                ],
              ),

              // Bottom Controls
              const Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: CallControlsWidget(),
                ),
              ),

              // Chat for mobile/tablet overlaid
              if (controller.isChatOpen.value && !isDesktop)
                Positioned(
                  top: 16,
                  bottom: 100,
                  right: 16,
                  child: const ChatPanelWidget(),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildParticipantsPanel() {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(top: 16, bottom: 100, left: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Participants (2)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: controller.toggleParticipants,
                  color: AppColors.textSecondary,
                )
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ParticipantTileWidget(
                  name: 'You',
                  isHost: controller.isCreator.value,
                  isMuted: !controller.isMicOn.value,
                ),
                ParticipantTileWidget(
                  name: 'Remote Participant',
                  isHost: !controller.isCreator.value,
                  isMuted: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomIdPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, size: 14, color: AppColors.accentGreen),
          const SizedBox(width: 8),
          Text(
            'Room: ${controller.roomId.value}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: controller.copyRoomId,
            child: const Icon(Icons.copy, size: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
