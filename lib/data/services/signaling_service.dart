import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

class SignalingService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;

  StreamStateCallback? onAddRemoteStream;

  Future<SignalingService> init() async {
    return this;
  }

  Future<String> createRoom(MediaStream localStreamParam) async {
    localStream = localStreamParam;
    
    DocumentReference roomRef = _db.collection('rooms').doc();
    roomId = roomRef.id;

    peerConnection = await _createPeerConnection();
    _registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Caller candidates
    var callerCandidatesCollection = roomRef.collection('callerCandidates');

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      callerCandidatesCollection.add(candidate.toMap());
    };

    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    Map<String, dynamic> roomWithOffer = {
      'offer': offer.toMap(),
      'created_at': FieldValue.serverTimestamp(),
    };

    await roomRef.set(roomWithOffer);

    // Listen for remote answer
    roomRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
      if (data != null && peerConnection?.getRemoteDescription() == null && data['answer'] != null) {
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await peerConnection?.setRemoteDescription(answer);
      }
    });

    // Listen for remote ICE candidates
    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });

    return roomId!;
  }

  Future<void> joinRoom(String roomIdParam, MediaStream localStreamParam) async {
    roomId = roomIdParam;
    localStream = localStreamParam;
    
    DocumentReference roomRef = _db.collection('rooms').doc(roomId);
    var roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      throw Exception('Room not found');
    }

    peerConnection = await _createPeerConnection();
    _registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      calleeCandidatesCollection.add(candidate.toMap());
    };

    Map<String, dynamic> data = roomSnapshot.data() as Map<String, dynamic>;
    var offer = data['offer'];
    await peerConnection?.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );

    var answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    Map<String, dynamic> roomWithAnswer = {
      'answer': {'type': answer.type, 'sdp': answer.sdp}
    };
    await roomRef.update(roomWithAnswer);

    roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    };
    return await createPeerConnection(configuration);
  }

  void _registerPeerConnectionListeners() {
    peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        onAddRemoteStream?.call(remoteStream!);
      }
    };

    peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      print('ICE connection state change: $state');
    };
  }

  Future<void> hangUp() async {
    if (roomId != null) {
      try {
        var roomRef = _db.collection('rooms').doc(roomId);
        var calleeCandidates = await roomRef.collection('calleeCandidates').get();
        for (var document in calleeCandidates.docs) {
          await document.reference.delete();
        }

        var callerCandidates = await roomRef.collection('callerCandidates').get();
        for (var document in callerCandidates.docs) {
          await document.reference.delete();
        }

        await roomRef.delete();
      } catch (e) {
        print("Error deleting room data: $e");
      }
    }

    localStream?.dispose();
    remoteStream?.dispose();
    peerConnection?.close();
    
    localStream = null;
    remoteStream = null;
    peerConnection = null;
    roomId = null;
  }
}
