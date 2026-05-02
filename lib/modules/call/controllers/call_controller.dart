import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import '../../../data/models/chat_message.dart';
import '../../../data/services/signaling_service.dart';

class CallController extends GetxController {
  final SignalingService _signalingService = Get.put(SignalingService());
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  final isMicOn = true.obs;
  final isCameraOn = true.obs;
  final isScreenSharing = false.obs;
  
  final isChatOpen = false.obs;
  final isParticipantsOpen = true.obs;

  final roomId = ''.obs;
  final isCreator = false.obs;
  final isConnecting = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // Chat related
  final chatController = TextEditingController();
  final messages = <ChatMessage>[].obs;
  final currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';

  @override
  void onInit() {
    super.onInit();
    _initRenderers();
    
    // Retrieve arguments
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      roomId.value = args['roomId'] ?? '';
      isCreator.value = args['isCreator'] ?? false;
      _startCall();
    } else {
      hasError.value = true;
      errorMessage.value = "Invalid room arguments.";
      isConnecting.value = false;
    }
  }

  void _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> _startCall() async {
    try {
      await _signalingService.init();

      _signalingService.onAddRemoteStream = (MediaStream stream) {
        remoteRenderer.srcObject = stream;
        update();
      };

      // Open camera
      var stream = await navigator.mediaDevices.getUserMedia({
        'video': true,
        'audio': true,
      });

      localRenderer.srcObject = stream;
      update();

      if (isCreator.value) {
        roomId.value = await _signalingService.createRoom(stream);
      } else {
        await _signalingService.joinRoom(roomId.value, stream);
      }
      
      _listenToChat();
      isConnecting.value = false;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = "Failed to connect: $e";
      isConnecting.value = false;
      print("Call start error: $e");
    }
  }

  void toggleMic() {
    if (_signalingService.localStream != null) {
      bool enabled = _signalingService.localStream!.getAudioTracks()[0].enabled;
      _signalingService.localStream!.getAudioTracks()[0].enabled = !enabled;
      isMicOn.value = !enabled;
    }
  }

  void toggleCamera() {
    if (_signalingService.localStream != null) {
      bool enabled = _signalingService.localStream!.getVideoTracks()[0].enabled;
      _signalingService.localStream!.getVideoTracks()[0].enabled = !enabled;
      isCameraOn.value = !enabled;
    }
  }

  Future<void> toggleScreenShare() async {
    try {
      if (isScreenSharing.value) {
        // Stop screen share and revert to camera
        var stream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': isMicOn.value});
        _replaceVideoTrack(stream);
        isScreenSharing.value = false;
      } else {
        // Start screen share
        var stream = await navigator.mediaDevices.getDisplayMedia({'video': true, 'audio': false});
        _replaceVideoTrack(stream);
        isScreenSharing.value = true;

        // Listen for screen share stop from browser UI
        stream.getVideoTracks()[0].onEnded = () {
          toggleScreenShare(); // revert when stopped from browser banner
        };
      }
    } catch (e) {
      print("Screen share error: $e");
    }
  }

  Future<void> _replaceVideoTrack(MediaStream newStream) async {
    var newVideoTrack = newStream.getVideoTracks()[0];
    var senders = await _signalingService.peerConnection?.getSenders();
    if (senders != null) {
      for (var sender in senders) {
        if (sender.track?.kind == 'video') {
          sender.replaceTrack(newVideoTrack);
        }
      }
    }
    
    // Update local renderer
    var oldTrack = localRenderer.srcObject?.getVideoTracks()[0];
    if (oldTrack != null) {
      localRenderer.srcObject?.removeTrack(oldTrack);
      oldTrack.stop();
    }
    localRenderer.srcObject?.addTrack(newVideoTrack);
    update();
  }

  void endCall() {
    _signalingService.hangUp();
    Get.back();
  }

  void copyRoomId() {
    Clipboard.setData(ClipboardData(text: roomId.value));
    Get.snackbar(
      'Copied',
      'Room ID copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // --- UI Toggles ---
  void toggleChat() {
    isChatOpen.value = !isChatOpen.value;
    if (isChatOpen.value && isParticipantsOpen.value) {
      // For smaller screens, maybe close participants if chat opens
      // But for web, we can leave both open if screen is large enough
    }
  }

  void toggleParticipants() {
    isParticipantsOpen.value = !isParticipantsOpen.value;
  }

  // --- Chat ---
  void _listenToChat() {
    _db
        .collection('rooms')
        .doc(roomId.value)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      messages.value = snapshot.docs.map((doc) => ChatMessage.fromMap(doc.id, doc.data())).toList();
    });
  }

  void sendMessage() {
    if (chatController.text.trim().isEmpty) return;

    var msg = ChatMessage(
      id: '',
      senderId: currentUserId,
      text: chatController.text.trim(),
      timestamp: DateTime.now(),
    );

    _db
        .collection('rooms')
        .doc(roomId.value)
        .collection('messages')
        .add(msg.toMap());

    chatController.clear();
  }

  @override
  void onClose() {
    _signalingService.hangUp();
    localRenderer.dispose();
    remoteRenderer.dispose();
    chatController.dispose();
    super.onClose();
  }
}
