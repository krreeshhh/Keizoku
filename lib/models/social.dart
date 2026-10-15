class UserProfileOnline {
  UserProfileOnline({
    required this.uid,
    required this.handle,
    required this.displayName,
    this.badge = 'blue',
    this.streak = 0,
    this.maxStreak = 0,
    this.weeklyGoal = 4,
    this.workoutsCompleted = 0,
    this.lastWorkoutDate,
    this.updatedAt,
  });

  final String uid;
  final String handle;
  final String displayName;
  final String badge;
  final int streak;
  final int maxStreak;
  final int weeklyGoal;
  final int workoutsCompleted;
  final DateTime? lastWorkoutDate;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'handle': handle.toLowerCase().trim(),
        'displayName': displayName.trim(),
        'badge': badge,
        'streak': streak,
        'maxStreak': maxStreak,
        'weeklyGoal': weeklyGoal,
        'workoutsCompleted': workoutsCompleted,
        if (lastWorkoutDate != null) 'lastWorkoutDate': lastWorkoutDate!.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

  factory UserProfileOnline.fromMap(Map<String, dynamic> map, [String? docId]) => UserProfileOnline(
        uid: (map['uid'] as String?) ?? docId ?? '',
        handle: (map['handle'] as String?) ?? '',
        displayName: (map['displayName'] as String?) ?? (map['handle'] as String?) ?? 'Athlete',
        badge: (map['badge'] as String?) ?? 'blue',
        streak: (map['streak'] as num?)?.toInt() ?? 0,
        maxStreak: (map['maxStreak'] as num?)?.toInt() ?? 0,
        weeklyGoal: (map['weeklyGoal'] as num?)?.toInt() ?? 4,
        workoutsCompleted: (map['workoutsCompleted'] as num?)?.toInt() ?? 0,
        lastWorkoutDate: DateTime.tryParse((map['lastWorkoutDate'] as String?) ?? ''),
        updatedAt: DateTime.tryParse((map['updatedAt'] as String?) ?? ''),
      );
}

class FriendRequest {
  FriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.fromHandle,
    required this.fromName,
    this.fromBadge = 'blue',
    this.fromStreak = 0,
    this.status = 'pending',
    required this.createdAt,
  });

  final String id;
  final String fromUid;
  final String toUid;
  final String fromHandle;
  final String fromName;
  final String fromBadge;
  final int fromStreak;
  final String status;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'fromUid': fromUid,
        'toUid': toUid,
        'fromHandle': fromHandle,
        'fromName': fromName,
        'fromBadge': fromBadge,
        'fromStreak': fromStreak,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FriendRequest.fromMap(Map<String, dynamic> map, String id) => FriendRequest(
        id: id,
        fromUid: (map['fromUid'] as String?) ?? '',
        toUid: (map['toUid'] as String?) ?? '',
        fromHandle: (map['fromHandle'] as String?) ?? '',
        fromName: (map['fromName'] as String?) ?? '',
        fromBadge: (map['fromBadge'] as String?) ?? 'blue',
        fromStreak: (map['fromStreak'] as num?)?.toInt() ?? 0,
        status: (map['status'] as String?) ?? 'pending',
        createdAt: DateTime.tryParse((map['createdAt'] as String?) ?? '') ?? DateTime.now(),
      );
}

class SharedRoutineOnline {
  SharedRoutineOnline({
    required this.id,
    required this.code,
    required this.title,
    this.description = '',
    required this.authorUid,
    required this.authorName,
    required this.authorHandle,
    this.authorBadge = 'blue',
    this.daysCount = 0,
    this.exercisesCount = 0,
    this.downloads = 0,
    required this.sharedAt,
    required this.routineData,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final String authorUid;
  final String authorName;
  final String authorHandle;
  final String authorBadge;
  final int daysCount;
  final int exercisesCount;
  final int downloads;
  final DateTime sharedAt;
  final Map<String, dynamic> routineData;

  Map<String, dynamic> toMap() => {
        'id': id,
        'code': code.toUpperCase().trim(),
        'title': title,
        'description': description,
        'authorUid': authorUid,
        'authorName': authorName,
        'authorHandle': authorHandle,
        'authorBadge': authorBadge,
        'daysCount': daysCount,
        'exercisesCount': exercisesCount,
        'downloads': downloads,
        'sharedAt': sharedAt.toIso8601String(),
        'routineData': routineData,
      };

  factory SharedRoutineOnline.fromMap(Map<String, dynamic> map, String docId) => SharedRoutineOnline(
        id: docId,
        code: (map['code'] as String?) ?? '',
        title: (map['title'] as String?) ?? 'Routine',
        description: (map['description'] as String?) ?? '',
        authorUid: (map['authorUid'] as String?) ?? '',
        authorName: (map['authorName'] as String?) ?? 'Athlete',
        authorHandle: (map['authorHandle'] as String?) ?? '',
        authorBadge: (map['authorBadge'] as String?) ?? 'blue',
        daysCount: (map['daysCount'] as num?)?.toInt() ?? 0,
        exercisesCount: (map['exercisesCount'] as num?)?.toInt() ?? 0,
        downloads: (map['downloads'] as num?)?.toInt() ?? 0,
        sharedAt: DateTime.tryParse((map['sharedAt'] as String?) ?? '') ?? DateTime.now(),
        routineData: (map['routineData'] as Map?)?.cast<String, dynamic>() ?? {},
      );
}
