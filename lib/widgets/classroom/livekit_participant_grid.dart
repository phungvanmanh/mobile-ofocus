import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:ofocus/theme/app_colors.dart';

class LiveKitParticipantGrid extends StatelessWidget {
  const LiveKitParticipantGrid({
    super.key,
    required this.participants,
    this.dimmed = false,
  });

  final List<Participant> participants;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return Center(
        child: Text(
          'Đang chờ người tham gia...',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.onDarkSurface,
          ),
        ),
      );
    }

    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 174 / 130.5,
        ),
        itemCount: participants.length,
        itemBuilder: (context, index) {
          return _LiveKitParticipantTile(participant: participants[index]);
        },
      ),
    );
  }
}

class _LiveKitParticipantTile extends StatelessWidget {
  const _LiveKitParticipantTile({required this.participant});

  final Participant participant;

  VideoTrack? _videoTrack() {
    VideoTrack? cameraTrack;
    VideoTrack? screenTrack;

    for (final publication in participant.videoTrackPublications) {
      final track = publication.track;
      if (track is! VideoTrack || publication.muted) continue;

      if (publication.source == TrackSource.screenShareVideo) {
        screenTrack = track;
      } else if (publication.source == TrackSource.camera) {
        cameraTrack = track;
      }
    }

    return screenTrack ?? cameraTrack;
  }

  @override
  Widget build(BuildContext context) {
    final videoTrack = _videoTrack();
    final name = participant.name.isNotEmpty
        ? participant.name
        : participant.identity;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.classroomTile,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (videoTrack != null)
            VideoTrackRenderer(videoTrack)
          else
            ColoredBox(
              color: AppColors.classroomBg,
              child: Center(
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: AppColors.onDarkSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
