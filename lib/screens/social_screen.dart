import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../models/social.dart';
import '../services/firebase_service.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/liquid_notch.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/ui_kit.dart';
import 'profile_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();

  bool _syncing = false;
  List<UserProfileOnline> _searchResults = [];
  bool _searching = false;

  late Stream<List<FriendRequest>> _requestsStream;
  late Stream<List<UserProfileOnline>> _friendsStream;
  late Stream<List<SharedRoutineOnline>> _routinesStream;

  StreamSubscription<List<FriendRequest>>? _reqSub;
  StreamSubscription<List<UserProfileOnline>>? _friendsSub;
  StreamSubscription<Set<String>>? _sentSub;

  List<UserProfileOnline> _friendsList = [];
  List<FriendRequest> _incomingRequests = [];
  Set<String> _sentRequestUids = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _initStreams();
    _sync();
  }

  void _initStreams() {
    _reqSub?.cancel();
    _friendsSub?.cancel();
    _sentSub?.cancel();

    _requestsStream = firebaseService.streamIncomingRequests();
    _friendsStream = firebaseService.streamFriends();
    _routinesStream = firebaseService.streamCommunityRoutines();

    _reqSub = _requestsStream.listen((reqs) {
      if (mounted) setState(() => _incomingRequests = reqs);
    });
    _friendsSub = _friendsStream.listen((friends) {
      if (mounted) setState(() => _friendsList = friends);
    });
    _sentSub = firebaseService.streamSentRequestUids().listen((sent) {
      if (mounted) setState(() => _sentRequestUids = sent);
    });
  }

  @override
  void dispose() {
    _reqSub?.cancel();
    _friendsSub?.cancel();
    _sentSub?.cancel();
    _tabs.dispose();
    _searchCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    await firebaseService.initialize();
    await firebaseService.syncUserProfile();
    if (mounted) {
      setState(() {
        _syncing = false;
        _initStreams();
      });
    }
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final list = await firebaseService.searchUsersByHandle(query);
    if (mounted) {
      setState(() {
        _searchResults = list;
        _searching = false;
      });
    }
  }

  Future<void> _sendRequest(UserProfileOnline target) async {
    setState(() => _sentRequestUids = {..._sentRequestUids, target.uid});
    final ok = await firebaseService.sendFriendRequest(target);
    if (!mounted) return;
    if (ok) {
      showNotchToast(
        context,
        'Friend Request Sent',
        subtitle: 'Invited @${target.handle}',
        icon: PhosphorIconsFill.paperPlaneTilt,
        accent: context.gc.sage,
      );
    } else {
      setState(() => _sentRequestUids = _sentRequestUids.where((id) => id != target.uid).toSet());
      showNotchToast(
        context,
        'Unable to send',
        subtitle: 'Please check connection',
        icon: PhosphorIconsFill.warning,
        accent: context.gc.danger,
      );
    }
  }

  Future<void> _accept(FriendRequest req) async {
    final ok = await firebaseService.acceptFriendRequest(req);
    if (!mounted) return;
    if (ok) {
      showNotchToast(
        context,
        'Friend Added!',
        subtitle: 'You and @${req.fromHandle} are now workout buddies',
        icon: PhosphorIconsFill.usersThree,
        accent: context.gc.sage,
      );
    }
  }

  Future<void> _decline(FriendRequest req) async {
    await firebaseService.declineFriendRequest(req);
  }

  Future<void> _removeFriend(UserProfileOnline friend) async {
    final confirm = await askConfirm(
      context,
      title: 'Remove Friend',
      body: 'Remove @${friend.handle} from your workout buddies?',
      confirmLabel: 'Remove',
      danger: true,
    );
    if (!confirm) return;
    final ok = await firebaseService.removeFriend(friend.uid);
    if (!mounted) return;
    if (ok) {
      showNotchToast(
        context,
        'Friend Removed',
        subtitle: '@${friend.handle} removed',
        icon: PhosphorIconsFill.trash,
        accent: context.gc.textSecondary,
      );
    }
  }

  Widget _buildSearchResultAction(GymColors gc, UserProfileOnline u) {
    final isFriend = _friendsList.any((f) => f.uid == u.uid);
    if (isFriend) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: gc.sage.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: gc.sage.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsBold.check, size: 14, color: gc.sage),
            const SizedBox(width: 5),
            Text('Friends', style: AppTheme.f(12.5, weight: FontWeight.w800, color: gc.sage)),
          ],
        ),
      );
    }

    final isSent = _sentRequestUids.contains(u.uid);
    if (isSent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: gc.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsBold.clock, size: 13, color: gc.textSecondary),
            const SizedBox(width: 5),
            Text('Requested', style: AppTheme.f(12, weight: FontWeight.w700, color: gc.textSecondary)),
          ],
        ),
      );
    }

    final incomingReq = _incomingRequests.where((r) => r.fromUid == u.uid).firstOrNull;
    if (incomingReq != null) {
      return TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: gc.sage,
          foregroundColor: gc.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        icon: Icon(PhosphorIconsBold.check, size: 14, color: gc.bg),
        label: Text('Accept', style: AppTheme.f(12, weight: FontWeight.w800, color: gc.bg)),
        onPressed: () => _accept(incomingReq),
      );
    }

    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: gc.accent,
        foregroundColor: gc.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
      icon: Icon(PhosphorIconsBold.userPlus, size: 14, color: gc.bg),
      label: Text('Add', style: AppTheme.f(12, weight: FontWeight.w800, color: gc.bg)),
      onPressed: () => _sendRequest(u),
    );
  }

  Future<void> _openShareRoutinePicker() async {
    final gc = context.gc;
    if (fit.routines.isEmpty) {
      showNotchToast(
        context,
        'No Routines to Share',
        subtitle: 'Create a routine first in the Routines tab',
        icon: PhosphorIconsFill.info,
        accent: gc.accent,
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: gc.bgRaised,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: gc.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share Routine Online',
                style: AppTheme.f(18, weight: FontWeight.w800, color: gc.text),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a routine to upload to the community and generate a share code.',
                style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary),
              ),
              const SizedBox(height: 18),
              for (final r in fit.routines)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: gc.bgRaised2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(PhosphorIconsBold.barbell, size: 20, color: gc.accent),
                  ),
                  title: Text(r.name.isNotEmpty ? r.name : 'Routine',
                      style: AppTheme.f(15, weight: FontWeight.w700, color: gc.text)),
                  subtitle: Text(
                    '${r.dayExercises.isNotEmpty ? r.dayExercises.keys.length : 1} days · ${r.exerciseIds.length} exercises',
                    style: AppTheme.f(12, color: gc.textSecondary),
                  ),
                  trailing: Icon(PhosphorIconsBold.cloudArrowUp, size: 20, color: gc.accent),
                  onTap: () async {
                    Navigator.of(bctx).pop();
                    final shared = await firebaseService.shareRoutine(r);
                    if (!mounted) return;
                    if (shared != null) {
                      _showShareSuccessDialog(shared);
                    } else {
                      showNotchToast(
                        context,
                        'Upload failed',
                        subtitle: 'Please check your connection',
                        icon: PhosphorIconsFill.warning,
                        accent: gc.danger,
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareSuccessDialog(SharedRoutineOnline shared) {
    final gc = context.gc;
    showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: gc.bgRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Routine Published! 🎉',
            style: AppTheme.f(19, weight: FontWeight.w800, color: gc.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your routine is online. Share this code with friends so they can import it instantly:',
              style: AppTheme.f(13.5, weight: FontWeight.w500, color: gc.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: gc.bgRaised2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: gc.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    shared.code,
                    style: AppTheme.f(22, weight: FontWeight.w900, color: gc.accent, letterSpacing: 2),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(PhosphorIconsRegular.copy, size: 20, color: gc.text),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shared.code));
                      showNotchToast(context, 'Copied Code', subtitle: shared.code, icon: PhosphorIconsFill.copy);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(),
            child: Text('Done', style: AppTheme.f(14, weight: FontWeight.w700, color: gc.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _importByCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();

    final shared = await firebaseService.getSharedRoutineByCode(code);
    if (!mounted) return;
    if (shared == null) {
      showNotchToast(
        context,
        'Code not found',
        subtitle: 'Check the code and try again',
        icon: PhosphorIconsFill.warning,
        accent: context.gc.danger,
      );
      return;
    }

    final ok = await firebaseService.importSharedRoutine(shared);
    if (!mounted) return;
    if (ok) {
      _codeCtrl.clear();
      showNotchToast(
        context,
        'Routine Imported! 📋',
        subtitle: '${shared.title} added to your routines',
        icon: PhosphorIconsFill.checkCircle,
        accent: context.gc.sage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final p = fit.profile;
    final streak = fit.currentStreak;

    return SafeArea(
      bottom: false,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScreenHeader(
                    title: 'Community & Streaks',
                    onBack: fit.backFromSocial,
                    titleSize: 22,
                    actions: [
                      RoundAction(
                        label: 'Sync Profile',
                        onTap: _sync,
                        child: _syncing
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: gc.text),
                              )
                            : Icon(PhosphorIconsRegular.arrowsClockwise, size: 17, color: gc.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // User's own Online Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: gc.bgRaised,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: gc.border),
                    ),
                    child: Row(
                      children: [
                        const ProfileAvatar(size: 54),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.f(16, weight: FontWeight.w800, color: gc.text),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: badgeColor(p.badge).withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      p.badge.toUpperCase(),
                                      style: AppTheme.f(9.5, weight: FontWeight.w800, color: badgeColor(p.badge)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '@${p.handle.isNotEmpty ? p.handle : "athlete"}',
                                style: AppTheme.f(13, weight: FontWeight.w600, color: gc.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        // Streak Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: gc.ember.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: gc.ember.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIconsFill.fire, size: 18, color: gc.ember),
                              const SizedBox(width: 5),
                              Text(
                                '$streak',
                                style: AppTheme.f(16, weight: FontWeight.w900, color: gc.ember),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tab selector
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: gc.bgRaised,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabs,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: gc.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: gc.bg,
                      unselectedLabelColor: gc.textSecondary,
                      labelStyle: AppTheme.f(13.5, weight: FontWeight.w800),
                      unselectedLabelStyle: AppTheme.f(13.5, weight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'Friends & Streaks'),
                        Tab(text: 'Routines Hub'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _buildFriendsTab(gc),
            _buildRoutinesTab(gc),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsTab(GymColors gc) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // Search & Add Friend Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gc.border),
          ),
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.magnifyingGlass, size: 18, color: gc.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _doSearch,
                  style: AppTheme.f(14, color: gc.text),
                  cursorColor: gc.accent,
                  decoration: InputDecoration(
                    hintText: 'Search athlete by @handle...',
                    hintStyle: AppTheme.f(14, color: gc.textTertiary),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_searchCtrl.text.isNotEmpty)
                IconButton(
                  icon: Icon(PhosphorIconsBold.x, size: 16, color: gc.textSecondary),
                  onPressed: () {
                    _searchCtrl.clear();
                    _doSearch('');
                  },
                ),
            ],
          ),
        ),
        if (_searching) ...[
          const SizedBox(height: 16),
          Center(child: CircularProgressIndicator(strokeWidth: 2, color: gc.accent)),
        ],
        // Search Results
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Search Results', style: AppTheme.f(12, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 8),
          for (final u in _searchResults)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: gc.bgRaised2,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: badgeColor(u.badge).withValues(alpha: 0.2),
                    child: Text(
                      u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : 'A',
                      style: AppTheme.f(14, weight: FontWeight.w800, color: badgeColor(u.badge)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.displayName, style: AppTheme.f(14, weight: FontWeight.w700, color: gc.text)),
                        Text('@${u.handle} · 🔥 ${u.streak}d streak',
                            style: AppTheme.f(12, color: gc.textSecondary)),
                      ],
                    ),
                  ),
                  _buildSearchResultAction(gc, u),
                ],
              ),
            ),
          const Divider(height: 24),
        ],

        // Incoming Requests Stream
        StreamBuilder<List<FriendRequest>>(
          stream: _requestsStream,
          builder: (context, snap) {
            final reqs = (snap.hasError || snap.data == null) ? <FriendRequest>[] : snap.data!;
            if (reqs.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text('Friend Requests (${reqs.length})',
                    style: AppTheme.f(12, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1)),
                const SizedBox(height: 8),
                for (final r in reqs)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: gc.bgRaised,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: gc.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: badgeColor(r.fromBadge).withValues(alpha: 0.2),
                          child: Text(
                            r.fromName.isNotEmpty ? r.fromName[0].toUpperCase() : 'A',
                            style: AppTheme.f(14, weight: FontWeight.w800, color: badgeColor(r.fromBadge)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.fromName, style: AppTheme.f(14, weight: FontWeight.w700, color: gc.text)),
                              Text('@${r.fromHandle} · 🔥 ${r.fromStreak}d streak',
                                  style: AppTheme.f(12, color: gc.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(PhosphorIconsBold.check, size: 18, color: gc.sage),
                          onPressed: () => _accept(r),
                        ),
                        IconButton(
                          icon: Icon(PhosphorIconsBold.x, size: 18, color: gc.danger),
                          onPressed: () => _decline(r),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 24),
              ],
            );
          },
        ),

        // Friends List Stream
        const SizedBox(height: 12),
        Text('My Workout Buddies', style: AppTheme.f(12, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 8),
        StreamBuilder<List<UserProfileOnline>>(
          stream: _friendsStream,
          builder: (context, snap) {
            final friends = (snap.hasError || snap.data == null) ? <UserProfileOnline>[] : snap.data!;
            if (friends.isEmpty) {
              return Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: gc.bgRaised,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gc.border),
                ),
                child: Column(
                  children: [
                    Icon(PhosphorIconsRegular.usersThree, size: 40, color: gc.textTertiary),
                    const SizedBox(height: 12),
                    Text('No friends added yet',
                        style: AppTheme.f(16, weight: FontWeight.w700, color: gc.text)),
                    const SizedBox(height: 6),
                    Text('Search by @handle above to connect and share streaks!',
                        textAlign: TextAlign.center,
                        style: AppTheme.f(13, color: gc.textSecondary, height: 1.4)),
                  ],
                ),
              );
            }

            return Column(
              children: [
                for (final f in friends)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: gc.bgRaised,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: gc.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: badgeColor(f.badge).withValues(alpha: 0.2),
                          child: Text(
                            f.displayName.isNotEmpty ? f.displayName[0].toUpperCase() : 'A',
                            style: AppTheme.f(16, weight: FontWeight.w800, color: badgeColor(f.badge)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.displayName, style: AppTheme.f(15, weight: FontWeight.w800, color: gc.text)),
                              const SizedBox(height: 2),
                              Text('@${f.handle} · ${f.workoutsCompleted} workouts',
                                  style: AppTheme.f(12.5, color: gc.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: gc.ember.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIconsFill.fire, size: 15, color: gc.ember),
                              const SizedBox(width: 4),
                              Text('${f.streak}d', style: AppTheme.f(13, weight: FontWeight.w800, color: gc.ember)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: Icon(PhosphorIconsRegular.dotsThreeVertical, size: 18, color: gc.textSecondary),
                          color: gc.bgRaised2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          onSelected: (action) {
                            if (action == 'remove') _removeFriend(f);
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'remove',
                              child: Row(
                                children: [
                                  Icon(PhosphorIconsRegular.trash, size: 16, color: gc.danger),
                                  const SizedBox(width: 8),
                                  Text('Remove Friend', style: AppTheme.f(13, color: gc.danger)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoutinesTab(GymColors gc) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // Action card to Share Routine
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gc.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: gc.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(PhosphorIconsBold.cloudArrowUp, size: 22, color: gc.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Share My Routine', style: AppTheme.f(15, weight: FontWeight.w800, color: gc.text)),
                    const SizedBox(height: 2),
                    Text('Publish to cloud & get a 6-digit share code',
                        style: AppTheme.f(12, color: gc.textSecondary)),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: gc.accent,
                  foregroundColor: gc.bg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: _openShareRoutinePicker,
                child: Text('Share', style: AppTheme.f(12.5, weight: FontWeight.w800, color: gc.bg)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Import with Share Code Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gc.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Import with Code', style: AppTheme.f(14, weight: FontWeight.w800, color: gc.text)),
              const SizedBox(height: 4),
              Text('Enter a 6-character code (e.g. GYM-8A19):',
                  style: AppTheme.f(12, color: gc.textSecondary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: gc.bgRaised2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        style: AppTheme.f(14, weight: FontWeight.w700, color: gc.text),
                        cursorColor: gc.accent,
                        decoration: InputDecoration(
                          hintText: 'GYM-XXXX',
                          hintStyle: AppTheme.f(14, color: gc.textTertiary),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: gc.bgRaised2,
                      foregroundColor: gc.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _importByCode,
                    child: Text('Import', style: AppTheme.f(13, weight: FontWeight.w800, color: gc.accent)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text("Friends' Shared Routines",
            style: AppTheme.f(12, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 10),

        // Friends' shared routines stream
        StreamBuilder<List<SharedRoutineOnline>>(
          stream: _routinesStream,
          builder: (context, snap) {
            final rawList = (snap.hasError || snap.data == null) ? <SharedRoutineOnline>[] : snap.data!;
            final friendUids = _friendsList.map((f) => f.uid).where((id) => id.isNotEmpty).toSet();
            final friendHandles = _friendsList.map((f) => f.handle.toLowerCase().trim()).where((h) => h.isNotEmpty).toSet();
            
            final list = rawList.where((item) {
              final matchesUid = item.authorUid.isNotEmpty && friendUids.contains(item.authorUid);
              final matchesHandle = item.authorHandle.isNotEmpty && friendHandles.contains(item.authorHandle.toLowerCase().trim());
              return matchesUid || matchesHandle;
            }).toList();

            if (_friendsList.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: gc.bgRaised,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gc.border),
                ),
                child: Column(
                  children: [
                    Icon(PhosphorIconsRegular.usersThree, size: 36, color: gc.textTertiary),
                    const SizedBox(height: 12),
                    Text('No friends added yet',
                        style: AppTheme.f(15, weight: FontWeight.w700, color: gc.text)),
                    const SizedBox(height: 6),
                    Text('Search for workout buddies by @handle in the Friends tab to see their shared routines here!',
                        textAlign: TextAlign.center,
                        style: AppTheme.f(13, color: gc.textSecondary, height: 1.4)),
                  ],
                ),
              );
            }

            if (list.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: gc.bgRaised,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gc.border),
                ),
                child: Column(
                  children: [
                    Icon(PhosphorIconsRegular.barbell, size: 36, color: gc.textTertiary),
                    const SizedBox(height: 12),
                    Text('No routines shared by friends yet',
                        style: AppTheme.f(15, weight: FontWeight.w700, color: gc.text)),
                    const SizedBox(height: 6),
                    Text('When your friends upload or share their routines, they will appear here!',
                        textAlign: TextAlign.center,
                        style: AppTheme.f(13, color: gc.textSecondary, height: 1.4)),
                  ],
                ),
              );
            }

            return Column(
              children: [
                for (final item in list)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: gc.bgRaised,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: gc.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: AppTheme.f(16, weight: FontWeight.w800, color: gc.text),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: gc.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.code,
                                style: AppTheme.f(11, weight: FontWeight.w800, color: gc.accent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created by @${item.authorHandle} · ${item.daysCount} days/week · ${item.exercisesCount} exercises',
                          style: AppTheme.f(12.5, color: gc.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(PhosphorIconsRegular.downloadSimple, size: 14, color: gc.textTertiary),
                                const SizedBox(width: 4),
                                Text('${item.downloads} imports',
                                    style: AppTheme.f(12, color: gc.textTertiary)),
                              ],
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                backgroundColor: gc.bgRaised2,
                                foregroundColor: gc.accent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              ),
                              icon: Icon(PhosphorIconsBold.downloadSimple, size: 14, color: gc.accent),
                              label: Text('Import to Routines',
                                  style: AppTheme.f(12, weight: FontWeight.w800, color: gc.accent)),
                              onPressed: () async {
                                final ok = await firebaseService.importSharedRoutine(item);
                                if (!context.mounted) return;
                                if (ok) {
                                  showNotchToast(
                                    context,
                                    'Routine Imported! 📋',
                                    subtitle: '${item.title} added to your routines',
                                    icon: PhosphorIconsFill.checkCircle,
                                    accent: gc.sage,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
