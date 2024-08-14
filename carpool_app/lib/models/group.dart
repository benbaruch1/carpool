class Group {
  final String uid; // Add this field
  final String firstMeetingPoint;
  final String secondMeetingPoint;
  final String thirdMeetingPoint;
  final List<String> members;
  final String rideName;
  final Map<String, dynamic> times;
  final List<String> selectedDays;
  final String userId;
  final Map<String, int> memberPoints; // points
  final Map<String, String>? pickupPoints;
  int availableSeats;

  Group({
    required this.uid,
    required this.firstMeetingPoint,
    required this.secondMeetingPoint,
    required this.thirdMeetingPoint,
    required this.members,
    required this.rideName,
    required this.times,
    required this.selectedDays,
    required this.userId,
    required this.memberPoints,
    required this.availableSeats,
    this.pickupPoints,
  });

  factory Group.fromMap(Map<String, dynamic> data, String id) {
    return Group(
      uid: id,
      firstMeetingPoint: data['firstMeetingPoint'],
      secondMeetingPoint: data['secondMeetingPoint'],
      thirdMeetingPoint: data['thirdMeetingPoint'],
      members: List<String>.from(data['members']),
      rideName: data['rideName'],
      times: data['times'],
      selectedDays: List<String>.from(data['selectedDays']),
      userId: data['userId'],
      memberPoints: Map<String, int>.from(data['memberPoints'] ?? {}),
      availableSeats: data['availableSeats'] ?? 5,
      pickupPoints: Map<String, String>.from(data['pickupPoints'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstMeetingPoint': firstMeetingPoint,
      'secondMeetingPoint': secondMeetingPoint,
      'thirdMeetingPoint': thirdMeetingPoint,
      'members': members,
      'rideName': rideName,
      'times': times,
      'selectedDays': selectedDays,
      'userId': userId,
      'memberPoints': memberPoints,
    };
  }
}
