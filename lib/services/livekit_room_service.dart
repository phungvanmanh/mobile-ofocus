import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:livekit_client/livekit_client.dart';
// ignore: implementation_imports
import 'package:livekit_client/src/managers/broadcast_manager.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:ofocus/services/media_permission_service.dart';

class LiveKitRoomService {
  LiveKitRoomService({this.onRoomChanged});

  final VoidCallback? onRoomChanged;

  Room? _room;
  EventsListener<RoomEvent>? _listener;

  Room? get room => _room;

  bool get isConnected => _room?.connectionState == ConnectionState.connected;

  List<Participant> get participants {
    final current = _room;
    if (current == null) return const [];

    return [
      if (current.localParticipant != null) current.localParticipant!,
      ...current.remoteParticipants.values,
    ];
  }

  int get participantCount => participants.length;

  LocalParticipant? get localParticipant => _room?.localParticipant;

  bool get isMicrophoneEnabled =>
      localParticipant?.isMicrophoneEnabled() ?? false;

  bool get isCameraEnabled => localParticipant?.isCameraEnabled() ?? false;

  bool get isScreenShareEnabled =>
      localParticipant?.isScreenShareEnabled() ?? false;

  Future<void> toggleMicrophone() async {
    final participant = localParticipant;
    if (participant == null) return;

    final enabling = !participant.isMicrophoneEnabled();
    if (enabling) {
      final granted = await MediaPermissionService.ensureMicrophone();
      if (!granted) {
        throw StateError('Quyền microphone bị từ chối');
      }
    }

    await participant.setMicrophoneEnabled(enabling);
    onRoomChanged?.call();
  }

  Future<void> toggleCamera() async {
    final participant = localParticipant;
    if (participant == null) return;

    final enabling = !participant.isCameraEnabled();
    if (enabling) {
      final granted = await MediaPermissionService.ensureCamera();
      if (!granted) {
        throw StateError('Quyền camera bị từ chối');
      }
    }

    await participant.setCameraEnabled(enabling);
    onRoomChanged?.call();
  }

  Future<void> toggleScreenShare() async {
    if (!isConnected) {
      throw StateError('Chưa kết nối phòng học');
    }

    final participant = localParticipant;
    if (participant == null) return;

    if (participant.isScreenShareEnabled()) {
      if (lkPlatformIs(PlatformType.iOS)) {
        await BroadcastManager().requestStop();
      }
      await participant.setScreenShareEnabled(false);
      await _stopAndroidScreenShareBackground();
      onRoomChanged?.call();
      return;
    }

    if (lkPlatformIs(PlatformType.android)) {
      final hasCapturePermission = await Helper.requestCapturePermission();
      if (!hasCapturePermission) return;

      await _ensureAndroidScreenShareBackground();
    }

    await participant.setScreenShareEnabled(true);
    onRoomChanged?.call();
  }

  Future<void> _ensureAndroidScreenShareBackground({bool isRetry = false}) async {
    try {
      var hasPermissions = await FlutterBackground.hasPermissions;
      if (!isRetry) {
        const androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: 'Chia sẻ màn hình',
          notificationText: 'ofocus đang chia sẻ màn hình.',
          notificationImportance: AndroidNotificationImportance.normal,
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
        );
        hasPermissions = await FlutterBackground.initialize(
          androidConfig: androidConfig,
        );
      }
      if (hasPermissions && !FlutterBackground.isBackgroundExecutionEnabled) {
        await FlutterBackground.enableBackgroundExecution();
      }
    } catch (error) {
      if (!isRetry) {
        await Future<void>.delayed(const Duration(seconds: 1));
        return _ensureAndroidScreenShareBackground(isRetry: true);
      }
      rethrow;
    }
  }

  Future<void> _stopAndroidScreenShareBackground() async {
    if (!lkPlatformIs(PlatformType.android)) return;

    try {
      if (FlutterBackground.isBackgroundExecutionEnabled) {
        await FlutterBackground.disableBackgroundExecution();
      }
    } catch (error) {
      debugPrint('[LiveKit] Failed to stop screen share background: $error');
    }
  }

  Future<List<String>> connect({
    required String url,
    required String token,
    bool cameraEnabled = true,
    bool microphoneEnabled = true,
  }) async {
    await disconnect();

    final room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultScreenShareCaptureOptions: ScreenShareCaptureOptions(
          useiOSBroadcastExtension: true,
        ),
      ),
    );

    _listener = room.createListener()
      ..on<TrackSubscribedEvent>((_) => onRoomChanged?.call())
      ..on<TrackUnsubscribedEvent>((_) => onRoomChanged?.call())
      ..on<TrackMutedEvent>((_) => onRoomChanged?.call())
      ..on<TrackUnmutedEvent>((_) => onRoomChanged?.call())
      ..on<LocalTrackPublishedEvent>((_) => onRoomChanged?.call())
      ..on<LocalTrackUnpublishedEvent>((_) => onRoomChanged?.call())
      ..on<ParticipantConnectedEvent>((_) => onRoomChanged?.call())
      ..on<ParticipantDisconnectedEvent>((event) {
        debugPrint(
          '[LiveKit] Participant left: ${event.participant.identity}',
        );
        onRoomChanged?.call();
      })
      ..on<RoomDisconnectedEvent>((event) {
        debugPrint('[LiveKit] Room disconnected: ${event.reason}');
        onRoomChanged?.call();
      });

    await room.connect(url, token);
    _room = room;

    final warnings = <String>[];
    final permissions = await MediaPermissionService.ensureCameraAndMicrophone(
      requestCamera: cameraEnabled,
      requestMicrophone: microphoneEnabled,
    );
    warnings.addAll(permissions.warnings);

    if (cameraEnabled && permissions.cameraGranted) {
      try {
        await room.localParticipant?.setCameraEnabled(true);
      } catch (error) {
        debugPrint('[LiveKit] Failed to enable camera: $error');
        warnings.add('Không thể bật camera');
      }
    }

    if (microphoneEnabled && permissions.microphoneGranted) {
      try {
        await room.localParticipant?.setMicrophoneEnabled(true);
      } catch (error) {
        debugPrint('[LiveKit] Failed to enable microphone: $error');
        warnings.add('Không thể bật microphone');
      }
    }

    onRoomChanged?.call();
    return warnings;
  }

  Future<void> disconnect() async {
    await _stopAndroidScreenShareBackground();

    _listener?.dispose();
    _listener = null;

    final room = _room;
    _room = null;
    if (room != null) {
      await room.disconnect();
      await room.dispose();
    }
  }

  void dispose() {
    disconnect();
  }
}
