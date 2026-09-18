import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG assets exported from Figma (OFOCUS-2 classroom flows).
abstract final class ClassroomIcons {
  static const _base = 'assets/classroom/icons';

  static const back = '$_base/back.svg';
  static const mic = '$_base/mic.svg';
  static const micToggle = '$_base/mic_toggle.svg';
  static const micMuted = '$_base/mic_muted.svg';
  static const camera = '$_base/camera.svg';
  static const cameraToggle = '$_base/camera_toggle.svg';
  static const cameraFlip = '$_base/camera_flip.svg';
  static const chat = '$_base/chat.svg';
  static const more = '$_base/more.svg';
  static const endCall = '$_base/end_call.svg';
  static const people = '$_base/people.svg';
  static const shield = '$_base/camera_switch.svg';
  static const backgroundWand = '$_base/background_wand.svg';
  static const speaker = '$_base/speaker.svg';
  static const play = '$_base/play.svg';
  static const aiNoise = '$_base/ai_noise.svg';
  static const handRaised = '$_base/hand_raised.svg';
  static const groups = '$_base/groups.svg';
  static const close = '$_base/chevron_right.svg';
  static const pin = '$_base/pin.svg';
  static const emoji = '$_base/play.svg';
  static const attach = '$_base/pin.svg';
  static const send = '$_base/attach.svg';
  static const screenShare = '$_base/discussion_room.svg';
  static const record = '$_base/screen_share.svg';
  static const whiteboard = '$_base/whiteboard.svg';
  static const poll = '$_base/poll.svg';
  static const settings = '$_base/settings.svg';
  static const apps = '$_base/more.svg';
  static const chevronRight = '$_base/record.svg';
}

class ClassroomIcon extends StatelessWidget {
  const ClassroomIcon(
    this.asset, {
    super.key,
    this.size = 16,
    this.color,
  });

  final String asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
