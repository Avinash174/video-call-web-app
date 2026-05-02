import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';

class HomeController extends GetxController {
  final roomController = TextEditingController();
  final isHoveringCreate = false.obs;
  final isHoveringJoin = false.obs;

  void setHoverCreate(bool value) => isHoveringCreate.value = value;
  void setHoverJoin(bool value) => isHoveringJoin.value = value;

  void createRoom() {
    // Generate a random room ID
    final roomId = _generateRandomRoomId();
    Get.toNamed(Routes.CALL, arguments: {'roomId': roomId, 'isCreator': true});
  }

  void joinRoom() {
    final roomId = roomController.text.trim();
    if (roomId.isNotEmpty) {
      Get.toNamed(Routes.CALL, arguments: {'roomId': roomId, 'isCreator': false});
    } else {
      Get.snackbar(
        'Error',
        'Please enter a valid Room ID',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  String _generateRandomRoomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }

  @override
  void onClose() {
    roomController.dispose();
    super.onClose();
  }
}
