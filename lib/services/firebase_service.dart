import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../models/exercise.dart';
import '../models/social.dart';
import '../models/workout.dart';
import '../state/fit_state.dart';
import 'local_store.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  User? get currentUser => _auth?.currentUser;
  String? get currentUid => _auth?.currentUser?.uid;

  /// Initialize Firebase app & authenticate user anonymously if not already signed in.
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;

      // Enable offline persistence settings
      _firestore?.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Sign in anonymously if needed so the user has an online identity
      if (_auth?.currentUser == null) {
        try {
          await _auth?.signInAnonymously();
        } catch (e) {
          debugPrint('Firebase anonymous sign-in notice: $e');
        }
      }

      _initialized = true;
      debugPrint('FirebaseService successfully initialized. UID: ${currentUid ?? "none"}');
      return true;
    } catch (e) {
      debugPrint('FirebaseService initialization fallback (offline mode): $e');
      _initialized = false;
      return false;
    }
  }

  /// Checks if a given handle is available to be claimed or already owned by the current user.
  Future<bool> isHandleAvailable(String handle) async {
    if (!_initialized || _firestore == null) return true;
    final clean = handle.trim().toLowerCase().replaceAll('@', '').replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (clean.isEmpty) return false;
    try {
      final doc = await _firestore!.collection('handles').doc(clean).get();
      if (!doc.exists) return true;
      final ownerUid = doc.data()?['uid'] as String?;
      return ownerUid == currentUid;
    } catch (e) {
      debugPrint('Error checking handle availability: $e');
      return true;
    }
  }

  /// Checks if the user's current handle is claimed by a different user in Firestore.
  Future<bool> isCurrentHandleClaimedByOther() async {
    if (!_initialized || _firestore == null || currentUid == null) return false;
    final handle = fit.profileHandle.trim().toLowerCase().replaceAll('@', '').replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (handle.isEmpty) return false;
    try {
      final doc = await _firestore!.collection('handles').doc(handle).get();
      if (!doc.exists) return false;
      final ownerUid = doc.data()?['uid'] as String?;
      return ownerUid != null && ownerUid != currentUid;
    } catch (e) {
      debugPrint('Error checking current handle conflict: $e');
      return false;
    }
  }

  /// Atomically claims a handle in Firestore if it is free or already owned by this user.
  /// Returns true on success, or false if already taken by another user.
  Future<bool> claimHandle(String requestedHandle) async {
    if (!_initialized || _firestore == null || currentUid == null) return false;
    final clean = requestedHandle.trim().toLowerCase().replaceAll('@', '').replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (clean.isEmpty) return false;

    try {
      final success = await _firestore!.runTransaction<bool>((tx) async {
        final handlesCol = _firestore!.collection('handles');
        final targetRef = handlesCol.doc(clean);
        final targetSnap = await tx.get(targetRef);

        if (targetSnap.exists) {
          final owner = targetSnap.data()?['uid'] as String?;
          if (owner != currentUid) {
            // Already taken by another athlete
            return false;
          }
        }

        // Release old handle if different
        final userRef = _firestore!.collection('users').doc(currentUid);
        final userSnap = await tx.get(userRef);
        final oldHandle = userSnap.data()?['handle'] as String?;
        if (oldHandle != null && oldHandle.isNotEmpty && oldHandle != clean) {
          tx.delete(handlesCol.doc(oldHandle));
        }

        // Claim target handle doc
        tx.set(targetRef, {
          'uid': currentUid,
          'handle': clean,
          'backupCode': fit.backupCode,
          'claimedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Update user doc
        tx.set(userRef, {
          'handle': clean,
          'backupCode': fit.backupCode,
        }, SetOptions(merge: true));

        return true;
      });

      return success;
    } catch (e) {
      debugPrint('Error claiming handle: $e');
      return false;
    }
  }

  /// Syncs local profile metadata, routines, streak & backup code to Firestore.
  /// NOTE: Profile picture & banner are strictly NOT synced to Firebase per requirement.
  Future<void> syncUserProfile() async {
    if (!_initialized || _firestore == null || currentUid == null) return;
    try {
      final p = fit.profile;
      final streak = fit.currentStreak;
      final workouts = fit.totalSessions;
      final lastSession = fit.sessions.isEmpty ? null : fit.sessions.last.date;

      final handle = fit.profileHandle;
      final isAvailable = await isHandleAvailable(handle);
      if (isAvailable) {
        await claimHandle(handle);
      }

      final onlineProfile = UserProfileOnline(
        uid: currentUid!,
        handle: handle,
        displayName: p.name.isNotEmpty ? p.name : fit.displayName,
        badge: p.badge.isNotEmpty ? p.badge : 'blue',
        streak: streak,
        maxStreak: streak,
        weeklyGoal: p.weeklyGoal,
        workoutsCompleted: workouts,
        lastWorkoutDate: lastSession,
      );

      final fullData = {
        ...onlineProfile.toMap(),
        'backupCode': fit.backupCode,
        'sex': p.sex,
        'age': p.age,
        'heightCm': p.heightCm,
        'weightKg': p.weightKg,
        'units': fit.units,
        'routines': fit.routines.map((r) => r.toJson()).toList(),
        'customExercises': fit.customExercises.map((e) => e.toJson()).toList(),
        'weeklyPlan': fit.weeklyPlan.map((k, v) => MapEntry(k.toString(), v)),
        'lastSync': FieldValue.serverTimestamp(),
      };

      await _firestore!.collection('users').doc(currentUid).set(
            fullData,
            SetOptions(merge: true),
          );

      // Keep handles collection in sync with current backupCode
      await _firestore!.collection('handles').doc(handle.trim().toLowerCase()).set({
        'uid': currentUid,
        'handle': handle.trim().toLowerCase(),
        'backupCode': fit.backupCode,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing user profile to Firebase: $e');
    }
  }

  /// Search users in the community by handle
  Future<List<UserProfileOnline>> searchUsersByHandle(String query) async {
    if (!_initialized || _firestore == null) return [];
    final clean = query.trim().toLowerCase().replaceAll('@', '');
    if (clean.isEmpty) return [];

    try {
      final snap = await _firestore!
          .collection('users')
          .where('handle', isGreaterThanOrEqualTo: clean)
          .where('handle', isLessThanOrEqualTo: '$clean\uf8ff')
          .limit(15)
          .get();

      return snap.docs
          .where((d) => d.id != currentUid)
          .map((d) => UserProfileOnline.fromMap(d.data(), d.id))
          .toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  /// Send a friend request to target athlete
  Future<bool> sendFriendRequest(UserProfileOnline target) async {
    if (!_initialized || _firestore == null || currentUid == null) return false;
    try {
      final p = fit.profile;
      final reqId = '${currentUid}_${target.uid}';
      final req = FriendRequest(
        id: reqId,
        fromUid: currentUid!,
        toUid: target.uid,
        fromHandle: fit.profileHandle,
        fromName: p.name.isNotEmpty ? p.name : fit.displayName,
        fromBadge: p.badge,
        fromStreak: fit.currentStreak,
        createdAt: DateTime.now(),
      );

      await _firestore!.collection('friend_requests').doc(reqId).set(req.toMap());
      return true;
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      return false;
    }
  }

  /// Accept an incoming friend request
  Future<bool> acceptFriendRequest(FriendRequest req) async {
    if (!_initialized || _firestore == null || currentUid == null) return false;
    try {
      final batch = _firestore!.batch();

      // Create mutual friend relationship documents
      final myFriendRef = _firestore!
          .collection('users')
          .doc(currentUid)
          .collection('friends')
          .doc(req.fromUid);

      final theirFriendRef = _firestore!
          .collection('users')
          .doc(req.fromUid)
          .collection('friends')
          .doc(currentUid);

      batch.set(myFriendRef, {
        'friendUid': req.fromUid,
        'addedAt': DateTime.now().toIso8601String(),
      });

      batch.set(theirFriendRef, {
        'friendUid': currentUid,
        'addedAt': DateTime.now().toIso8601String(),
      });

      // Delete or update the request
      final reqRef = _firestore!.collection('friend_requests').doc(req.id);
      batch.delete(reqRef);

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      return false;
    }
  }

  /// Decline or remove a friend request
  Future<bool> declineFriendRequest(FriendRequest req) async {
    if (!_initialized || _firestore == null) return false;
    try {
      await _firestore!.collection('friend_requests').doc(req.id).delete();
      return true;
    } catch (e) {
      debugPrint('Error declining friend request: $e');
      return false;
    }
  }

  /// Remove a friend from both users' friend collections
  Future<bool> removeFriend(String friendUid) async {
    if (!_initialized || _firestore == null || currentUid == null) return false;
    try {
      final batch = _firestore!.batch();
      batch.delete(_firestore!
          .collection('users')
          .doc(currentUid)
          .collection('friends')
          .doc(friendUid));
      batch.delete(_firestore!
          .collection('users')
          .doc(friendUid)
          .collection('friends')
          .doc(currentUid));
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error removing friend: $e');
      return false;
    }
  }

  /// Real-time stream of incoming friend requests
  Stream<List<FriendRequest>> streamIncomingRequests() {
    if (!_initialized || _firestore == null || currentUid == null) {
      return Stream<List<FriendRequest>>.value(<FriendRequest>[]).asBroadcastStream();
    }
    return _firestore!
        .collection('friend_requests')
        .where('toUid', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FriendRequest.fromMap(d.data(), d.id))
            .toList())
        .handleError((Object e) {
          debugPrint('Error in streamIncomingRequests: $e');
          return <FriendRequest>[];
        })
        .asBroadcastStream();
  }

  /// Real-time stream of user IDs to whom the current user has sent a pending friend request
  Stream<Set<String>> streamSentRequestUids() {
    if (!_initialized || _firestore == null || currentUid == null) {
      return Stream<Set<String>>.value(<String>{}).asBroadcastStream();
    }
    return _firestore!
        .collection('friend_requests')
        .where('fromUid', isEqualTo: currentUid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => (d.data()['toUid'] as String?) ?? '')
            .where((id) => id.isNotEmpty)
            .toSet())
        .handleError((Object e) {
          debugPrint('Error in streamSentRequestUids: $e');
          return <String>{};
        })
        .asBroadcastStream();
  }

  /// Retrieve locally cached friends list for offline showcasing
  List<UserProfileOnline> getCachedFriends() {
    try {
      final raw = Store.instance.note('cached_friends');
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw);
      if (list is List) {
        return list
            .whereType<Map>()
            .map((m) => UserProfileOnline.fromMap(m.cast<String, dynamic>()))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading cached friends: $e');
    }
    return [];
  }

  /// Save friends list locally for offline showcasing
  void saveCachedFriends(List<UserProfileOnline> friends) {
    try {
      final list = friends.map((f) => f.toMap()).toList();
      Store.instance.setNote('cached_friends', jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving cached friends: $e');
    }
  }

  /// Real-time stream of user's friends with latest streaks and workout status
  Stream<List<UserProfileOnline>> streamFriends() {
    final cached = getCachedFriends();
    if (!_initialized || _firestore == null || currentUid == null) {
      return Stream<List<UserProfileOnline>>.value(cached).asBroadcastStream();
    }

    return _firestore!
        .collection('users')
        .doc(currentUid)
        .collection('friends')
        .snapshots()
        .asyncMap((snap) async {
          if (snap.docs.isEmpty) {
            saveCachedFriends([]);
            return <UserProfileOnline>[];
          }
          final friendUids = snap.docs.map((d) => d.id).toList();

          // Chunk requests by 10 for Firestore 'whereIn' limits
          final results = <UserProfileOnline>[];
          for (var i = 0; i < friendUids.length; i += 10) {
            final chunk = friendUids.sublist(i, min(i + 10, friendUids.length));
            try {
              final usersSnap = await _firestore!
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: chunk)
                  .get();

              results.addAll(usersSnap.docs
                  .map((d) => UserProfileOnline.fromMap(d.data(), d.id)));
            } catch (e) {
              debugPrint('Error loading friend profiles chunk: $e');
            }
          }
          // Sort by active streak descending
          results.sort((a, b) => b.streak.compareTo(a.streak));
          saveCachedFriends(results);
          return results;
        })
        .handleError((Object e) {
          debugPrint('Error in streamFriends: $e');
          return getCachedFriends();
        })
        .asBroadcastStream();
  }

  /// Share a Routine to the online community with a unique share code
  Future<SharedRoutineOnline?> shareRoutine(
    Routine routine, {
    String description = '',
  }) async {
    if (!_initialized || _firestore == null || currentUid == null) return null;
    try {
      final code = _generateShareCode();
      final p = fit.profile;
      final totalDays = routine.dayExercises.isNotEmpty ? routine.dayExercises.keys.length : 1;
      final totalExercises = routine.exerciseIds.length;

      final shared = SharedRoutineOnline(
        id: '',
        code: code,
        title: routine.name.isNotEmpty ? routine.name : 'Routine',
        description: description,
        authorUid: currentUid!,
        authorName: p.name.isNotEmpty ? p.name : fit.displayName,
        authorHandle: fit.profileHandle,
        authorBadge: p.badge,
        daysCount: totalDays,
        exercisesCount: totalExercises,
        downloads: 0,
        sharedAt: DateTime.now(),
        routineData: routine.toJson(),
      );

      final docRef = await _firestore!.collection('shared_routines').add(shared.toMap());
      return SharedRoutineOnline.fromMap(shared.toMap(), docRef.id);
    } catch (e) {
      debugPrint('Error sharing routine to Firebase: $e');
      return null;
    }
  }

  /// Fetch a shared routine by its 6-character code (e.g. GYM-8X2A)
  Future<SharedRoutineOnline?> getSharedRoutineByCode(String code) async {
    if (!_initialized || _firestore == null) return null;
    try {
      final clean = code.trim().toUpperCase();
      final snap = await _firestore!
          .collection('shared_routines')
          .where('code', isEqualTo: clean)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first;
      return SharedRoutineOnline.fromMap(d.data(), d.id);
    } catch (e) {
      debugPrint('Error getting shared routine: $e');
      return null;
    }
  }

  /// Stream recent community & friend shared routines
  Stream<List<SharedRoutineOnline>> streamCommunityRoutines({int limit = 20}) {
    if (!_initialized || _firestore == null) {
      return Stream<List<SharedRoutineOnline>>.value(<SharedRoutineOnline>[]).asBroadcastStream();
    }
    return _firestore!
        .collection('shared_routines')
        .orderBy('sharedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SharedRoutineOnline.fromMap(d.data(), d.id))
            .toList())
        .handleError((Object e) {
          debugPrint('Error in streamCommunityRoutines: $e');
          return <SharedRoutineOnline>[];
        })
        .asBroadcastStream();
  }

  /// Import a shared routine into local Keizoku routines
  Future<bool> importSharedRoutine(SharedRoutineOnline shared) async {
    try {
      final raw = Map<String, dynamic>.from(shared.routineData);
      final newId = 'r${DateTime.now().microsecondsSinceEpoch}';
      final r = Routine.fromJson(raw);
      final imported = Routine(
        newId,
        '${shared.title} (@${shared.authorHandle})',
        r.exerciseIds,
        sets: r.sets,
        chained: r.chained,
        plan: r.plan,
        rest: r.rest,
        dayExercises: r.dayExercises,
        daySets: r.daySets,
        dayChained: r.dayChained,
        dayPlan: r.dayPlan,
        dayRest: r.dayRest,
        group: r.group,
        color: r.color,
      );

      // Insert into local routines and persist
      fit.addRoutine(imported);

      // Increment download counter online asynchronously
      if (_initialized && _firestore != null && shared.id.isNotEmpty) {
        _firestore!.collection('shared_routines').doc(shared.id).update({
          'downloads': FieldValue.increment(1),
        }).catchError((_) {});
      }

      return true;
    } catch (e) {
      debugPrint('Error importing routine: $e');
      return false;
    }
  }

  /// Restore user account, routines, streak, and friends using username & backup code.
  Future<({bool success, String? error, int routinesCount, int friendsCount, int streak})>
      restoreAccountWithBackupCode(String handle, String backupCode) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok || _firestore == null) {
        return (
          success: false,
          error: 'Unable to connect to server. Please check your internet connection.',
          routinesCount: 0,
          friendsCount: 0,
          streak: 0,
        );
      }
    }

    final cleanHandle = handle.trim().toLowerCase().replaceAll('@', '').replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final cleanCode = backupCode.trim().toUpperCase().replaceAll(' ', '');

    if (cleanHandle.isEmpty) {
      return (success: false, error: 'Please enter your username', routinesCount: 0, friendsCount: 0, streak: 0);
    }
    if (cleanCode.isEmpty) {
      return (success: false, error: 'Please enter your backup code', routinesCount: 0, friendsCount: 0, streak: 0);
    }

    try {
      // 1. Look up handle in Firestore
      String? targetUid;
      String? storedCode;

      final handleDoc = await _firestore!.collection('handles').doc(cleanHandle).get();
      if (handleDoc.exists) {
        final data = handleDoc.data()!;
        targetUid = data['uid'] as String?;
        storedCode = data['backupCode'] as String?;
      }

      // If not in handle doc, check users collection by handle field
      if (targetUid == null) {
        final query = await _firestore!
            .collection('users')
            .where('handle', isEqualTo: cleanHandle)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          targetUid = doc.id;
          storedCode = doc.data()['backupCode'] as String?;
        }
      }

      if (targetUid == null) {
        return (
          success: false,
          error: 'No account found with username @$cleanHandle',
          routinesCount: 0,
          friendsCount: 0,
          streak: 0,
        );
      }

      // Fetch user document from targetUid
      final userDoc = await _firestore!.collection('users').doc(targetUid).get();
      if (!userDoc.exists) {
        return (
          success: false,
          error: 'Account data not found for @$cleanHandle',
          routinesCount: 0,
          friendsCount: 0,
          streak: 0,
        );
      }

      final userData = userDoc.data()!;
      storedCode ??= userData['backupCode'] as String?;

      // 2. Validate backup code (ignoring hyphens and case)
      final normInput = cleanCode.replaceAll('-', '');
      final normStored = (storedCode ?? '').trim().toUpperCase().replaceAll('-', '');

      if (normStored.isEmpty || normInput != normStored) {
        return (
          success: false,
          error: 'Invalid backup code for @$cleanHandle. Please double check.',
          routinesCount: 0,
          friendsCount: 0,
          streak: 0,
        );
      }

      // 3. Restore Account Data
      // (a) Profile
      final name = (userData['displayName'] as String?) ?? (userData['name'] as String?) ?? '';
      if (name.isNotEmpty) fit.profile.name = name;
      fit.profile.handle = cleanHandle;
      if (userData['badge'] is String) fit.profile.badge = userData['badge'] as String;
      if (userData['weeklyGoal'] is num) fit.profile.weeklyGoal = (userData['weeklyGoal'] as num).toInt();
      if (userData['sex'] is String) fit.profile.sex = userData['sex'] as String;
      if (userData['age'] is num) fit.profile.age = (userData['age'] as num).toInt();
      if (userData['heightCm'] is num) fit.profile.heightCm = (userData['heightCm'] as num).toDouble();
      if (userData['weightKg'] is num) fit.profile.weightKg = (userData['weightKg'] as num).toDouble();
      if (userData['units'] is String) fit.units = userData['units'] as String;
      fit.backupCode = storedCode!;

      // (b) Routines
      int restoredRoutines = 0;
      final rawRoutines = userData['routines'];
      if (rawRoutines is List) {
        final existingIds = fit.routines.map((r) => r.id).toSet();
        for (final item in rawRoutines) {
          if (item is Map) {
            try {
              final r = Routine.fromJson(item.cast<String, dynamic>());
              if (!existingIds.contains(r.id)) {
                fit.routines.add(r);
                existingIds.add(r.id);
                restoredRoutines++;
              }
            } catch (e) {
              debugPrint('Error restoring routine: $e');
            }
          }
        }
      }

      // (c) Custom Exercises
      final rawCustom = userData['customExercises'];
      if (rawCustom is List) {
        final existingIds = fit.customExercises.map((e) => e.id).toSet();
        for (final item in rawCustom) {
          if (item is Map) {
            try {
              final ex = Exercise.fromJson(item.cast<String, dynamic>());
              if (!existingIds.contains(ex.id)) {
                fit.customExercises.add(ex);
                existingIds.add(ex.id);
              }
            } catch (e) {
              debugPrint('Error restoring custom exercise: $e');
            }
          }
        }
      }

      // (d) Weekly Plan
      final rawPlan = userData['weeklyPlan'];
      if (rawPlan is Map) {
        for (final entry in rawPlan.entries) {
          final day = int.tryParse(entry.key.toString());
          if (day != null && entry.value is String) {
            fit.weeklyPlan[day] = entry.value as String;
          }
        }
      }

      // (e) Friends & Social
      int restoredFriends = 0;
      if (currentUid != null) {
        // Fetch friends from old UID's friends subcollection
        final oldFriendsSnap = await _firestore!
            .collection('users')
            .doc(targetUid)
            .collection('friends')
            .get();

        restoredFriends = oldFriendsSnap.docs.length;

        // If this device has a different UID than targetUid, copy friends relationship over
        if (currentUid != targetUid) {
          final batch = _firestore!.batch();
          for (final doc in oldFriendsSnap.docs) {
            final friendUid = doc.id;
            final myFriendRef = _firestore!
                .collection('users')
                .doc(currentUid)
                .collection('friends')
                .doc(friendUid);
            batch.set(myFriendRef, doc.data());

            // Update friend's reference to point to currentUid
            final theirFriendRef = _firestore!
                .collection('users')
                .doc(friendUid)
                .collection('friends')
                .doc(currentUid);
            batch.set(theirFriendRef, {
              'friendUid': currentUid,
              'addedAt': DateTime.now().toIso8601String(),
            });
          }

          // Transfer handle ownership to currentUid
          batch.set(_firestore!.collection('handles').doc(cleanHandle), {
            'uid': currentUid,
            'handle': cleanHandle,
            'backupCode': storedCode,
            'restoredAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          await batch.commit();
        }
      }

      final restoredStreak = (userData['streak'] as num?)?.toInt() ?? fit.currentStreak;

      // Complete onboarding and persist to disk
      fit.completeOnboarding();
      fit.persistNow();

      // Sync updated state online
      unawaited(syncUserProfile());

      return (
        success: true,
        error: null,
        routinesCount: restoredRoutines,
        friendsCount: restoredFriends,
        streak: restoredStreak,
      );
    } catch (e) {
      debugPrint('Error restoring account with backup code: $e');
      return (
        success: false,
        error: 'Failed to restore account: $e',
        routinesCount: 0,
        friendsCount: 0,
        streak: 0,
      );
    }
  }

  /// Completely deletes all remote cloud database data associated with this user in Firestore.
  Future<bool> deleteAccountAndAllData() async {
    if (!_initialized || _firestore == null || currentUid == null) return true;
    final uid = currentUid!;
    try {
      final batch = _firestore!.batch();

      // 1. Delete handle claim
      final handle = fit.profileHandle.trim().toLowerCase().replaceAll('@', '').replaceAll(RegExp(r'[^a-z0-9_]'), '');
      if (handle.isNotEmpty) {
        batch.delete(_firestore!.collection('handles').doc(handle));
      }

      // 2. Delete user doc
      batch.delete(_firestore!.collection('users').doc(uid));

      // 3. Remove from all friends subcollections
      final friendsSnap = await _firestore!.collection('users').doc(uid).collection('friends').get();
      for (final friendDoc in friendsSnap.docs) {
        final friendUid = friendDoc.id;
        batch.delete(friendDoc.reference);
        batch.delete(_firestore!.collection('users').doc(friendUid).collection('friends').doc(uid));
      }

      // 4. Delete outgoing and incoming friend requests
      final outgoingReqs = await _firestore!.collection('friend_requests').where('fromUid', isEqualTo: uid).get();
      for (final d in outgoingReqs.docs) {
        batch.delete(d.reference);
      }
      final incomingReqs = await _firestore!.collection('friend_requests').where('toUid', isEqualTo: uid).get();
      for (final d in incomingReqs.docs) {
        batch.delete(d.reference);
      }

      // 5. Delete shared routines
      final routinesSnap = await _firestore!.collection('shared_routines').where('authorUid', isEqualTo: uid).get();
      for (final d in routinesSnap.docs) {
        batch.delete(d.reference);
      }

      await batch.commit();

      // 6. Delete auth user or sign out
      try {
        await _auth?.currentUser?.delete();
      } catch (e) {
        debugPrint('Auth user delete notice: $e');
        await _auth?.signOut();
      }

      // 7. Re-sign in anonymously with fresh UID for clean slate
      try {
        await _auth?.signInAnonymously();
      } catch (e) {
        debugPrint('Re-signin anonymously notice: $e');
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting account and all data from Firestore: $e');
      return false;
    }
  }

  String _generateShareCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    final buffer = StringBuffer('GYM-');
    for (var i = 0; i < 4; i++) {
      buffer.write(chars[rand.nextInt(chars.length)]);
    }
    return buffer.toString();
  }
}

final firebaseService = FirebaseService.instance;
