class ClassSession {
  const ClassSession({
    this.classTitle = 'React Native & UI Mobile Nâng cao - Buổi 9',
    this.shortTitle = 'React Native & UI Mobile',
    this.instructor = 'ThS. Hoàng Nam',
    this.studentName = 'Minh Anh',
    this.roomCode,
    this.classId,
    this.classScheduleId,
    this.liveKitToken,
    this.cameraEnabled = true,
    this.microphoneEnabled = true,
    this.participantCount = 28,
    this.unreadChat = 5,
  });

  final String classTitle;
  final String shortTitle;
  final String instructor;
  final String studentName;
  final String? roomCode;
  final int? classId;
  final int? classScheduleId;
  final String? liveKitToken;
  final bool cameraEnabled;
  final bool microphoneEnabled;
  final int participantCount;
  final int unreadChat;

  ClassSession copyWith({
    String? classTitle,
    String? shortTitle,
    String? instructor,
    String? studentName,
    String? roomCode,
    int? classId,
    int? classScheduleId,
    String? liveKitToken,
    bool? cameraEnabled,
    bool? microphoneEnabled,
    int? participantCount,
    int? unreadChat,
  }) {
    return ClassSession(
      classTitle: classTitle ?? this.classTitle,
      shortTitle: shortTitle ?? this.shortTitle,
      instructor: instructor ?? this.instructor,
      studentName: studentName ?? this.studentName,
      roomCode: roomCode ?? this.roomCode,
      classId: classId ?? this.classId,
      classScheduleId: classScheduleId ?? this.classScheduleId,
      liveKitToken: liveKitToken ?? this.liveKitToken,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      microphoneEnabled: microphoneEnabled ?? this.microphoneEnabled,
      participantCount: participantCount ?? this.participantCount,
      unreadChat: unreadChat ?? this.unreadChat,
    );
  }
}

enum ParticipantRole { instructor, self, student }

class ClassroomParticipant {
  const ClassroomParticipant({
    required this.name,
    this.role = ParticipantRole.student,
    this.micOn = false,
    this.cameraOn = false,
    this.handRaised = false,
    this.borderColor,
  });

  final String name;
  final ParticipantRole role;
  final bool micOn;
  final bool cameraOn;
  final bool handRaised;
  final int? borderColor;
}

const defaultParticipants = [
  ClassroomParticipant(
    name: 'ThS. Hoàng Nam',
    role: ParticipantRole.instructor,
    micOn: true,
  ),
  ClassroomParticipant(
    name: 'Minh Anh',
    role: ParticipantRole.self,
    micOn: true,
    cameraOn: true,
    borderColor: 0xFF3525CD,
  ),
  ClassroomParticipant(
    name: 'Tuấn Kiệt',
    handRaised: true,
  ),
  ClassroomParticipant(
    name: 'Lan Phương',
    cameraOn: true,
  ),
  ClassroomParticipant(
    name: 'Đức Thắng',
  ),
  ClassroomParticipant(
    name: 'Bảo Long',
    micOn: true,
  ),
  ClassroomParticipant(
    name: 'Khánh Linh',
  ),
  ClassroomParticipant(
    name: 'Hoàng Yến',
    handRaised: true,
  ),
  ClassroomParticipant(
    name: 'Quốc Huy',
  ),
  ClassroomParticipant(
    name: 'Mai Chi',
  ),
];
