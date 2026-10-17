// lib/screen/profile_screen.dart
// Profile screen - profile data from Supabase, posts from Supabase, follows from Firebase (transitional)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/core/auth/auth_service.dart';
import 'package:flutter_instagram_clone/data/firebase_service/firestor.dart';
import 'package:flutter_instagram_clone/data/model/post.dart';
import 'package:flutter_instagram_clone/data/model/user_profile.dart';
import 'package:flutter_instagram_clone/data/supabase_service/supabase_posts.dart';
import 'package:flutter_instagram_clone/data/supabase_service/supabase_profile.dart';
import 'package:flutter_instagram_clone/screen/post_screen.dart';
import 'package:flutter_instagram_clone/util/image_cached.dart';
import 'package:flutter_instagram_clone/widgets/post_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  bool isOwnProfile = false;
  List following = [];
  bool isFollowing = false;

  // Posts state
  final _posts = <Post>[];
  PostCursor? _nextCursor;
  bool _isLoadingPosts = false;
  bool _hasMorePosts = true;
  bool _hasPostsError = false;
  String? _postsErrorMessage;
  final _postsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFollowingData();
    final currentUserId = AuthService.instance.currentUserId;
    if (widget.uid == currentUserId && mounted) {
      setState(() {
        isOwnProfile = true;
      });
    }
    _postsScrollController.addListener(_onPostsScroll);
    _loadUserPosts();
  }

  @override
  void dispose() {
    _postsScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowingData() async {
    final currentUserId = AuthService.instance.currentUserId;
    if (currentUserId == null) return;

    final snap =
        await _firebaseFirestore.collection('users').doc(currentUserId).get();

    if (!snap.exists || !mounted) return;
    final data = snap.data();
    final followingData =
        data is Map<String, dynamic> ? data['following'] : null;
    following = followingData is List ? followingData : <dynamic>[];

    if (following.contains(widget.uid)) {
      setState(() {
        isFollowing = true;
      });
    }
  }

  Future<void> _loadUserPosts() async {
    if (_isLoadingPosts) return;
    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final page = await SupabasePostsService.instance.getUserPosts(
        userId: widget.uid,
      );
      if (mounted) {
        setState(() {
          _posts.clear();
          _posts.addAll(page.posts);
          _nextCursor = page.nextCursor;
          _hasMorePosts = page.hasMore;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingPosts || !_hasMorePosts || _nextCursor == null) return;

    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final page = await SupabasePostsService.instance.getUserPosts(
        userId: widget.uid,
        cursor: _nextCursor,
      );
      if (mounted) {
        setState(() {
          _posts.addAll(page.posts);
          _nextCursor = page.nextCursor;
          _hasMorePosts = page.hasMore;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  void _onPostsScroll() {
    if (_postsScrollController.position.pixels >=
        _postsScrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.instance.signOut();
      // Navigation handled by MainPage authStateChanges stream
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(
          child: CustomScrollView(
            controller: _postsScrollController,
            slivers: [
              SliverToBoxAdapter(
                child: FutureBuilder<UserProfile?>(
                  future:
                      SupabaseProfileService.instance.getProfile(widget.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }
                    final user = snapshot.data;
                    if (user == null) {
                      return _buildEmptyState('User not found');
                    }
                    return Head(user);
                  },
                ),
              ),
              _isLoadingPosts && _posts.isEmpty
                  ? _buildPostsLoading()
                  : _posts.isEmpty
                      ? _buildEmptyPosts()
                      : _buildPostsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsLoading() {
    return SliverToBoxAdapter(
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildEmptyPosts() {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.post_add, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                isOwnProfile ? 'No posts yet' : 'No posts available',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsGrid() {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == _posts.length) {
          return _isLoadingPosts && _hasMorePosts
              ? _buildLoadMoreIndicator()
              : const SizedBox.shrink();
        }
        final post = _posts[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => PostScreen(post)));
          },
          child: CachedImage(
            SupabasePostsService.instance.getPostImageUrl(post.imagePath),
          ),
        );
      },
          childCount:
              _posts.length + (_isLoadingPosts && _hasMorePosts ? 1 : 0)),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: EdgeInsets.all(16.h),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(String error, {bool isSliver = false}) {
    final widget = Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load profile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
    return isSliver ? SliverToBoxAdapter(child: widget) : widget;
  }

  Widget _buildEmptyState(String message, {bool isSliver = false}) {
    final widget = Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.post_add, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
    return isSliver ? SliverToBoxAdapter(child: widget) : widget;
  }

  // ignore: non_constant_identifier_names
  Widget Head(UserProfile user) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
                child: ClipOval(
                  child: SizedBox(
                    width: 80.w,
                    height: 80.h,
                    child: CachedImage(
                      user.avatarPath != null
                          ? SupabaseProfileService.instance
                              .getAvatarPublicUrl(user.avatarPath!)
                          : null,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(width: 35.w),
                      Text(
                        _posts.length.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(width: 53.w),
                      // Follower/following counts from Firebase (transitional)
                      // Will be migrated in Phase G
                      FutureBuilder<int>(
                        future: _getFollowerCount(),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data?.toString() ?? '0',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 70.w),
                      FutureBuilder<int>(
                        future: _getFollowingCount(),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data?.toString() ?? '0',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width: 30.w),
                      Text(
                        'Posts',
                        style: TextStyle(
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(width: 25.w),
                      Text(
                        'Followers',
                        style: TextStyle(
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(width: 19.w),
                      Text(
                        'Following',
                        style: TextStyle(
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isOwnProfile) ...[
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) {
                    if (value == 'logout') {
                      _handleLogout();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Log Out', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  user.bio,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Visibility(
            visible: !isFollowing,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 13.w),
              child: GestureDetector(
                onTap: () {
                  if (!isOwnProfile) {
                    Firebase_Firestor().flollow(uid: widget.uid);
                    setState(() {
                      isFollowing = true;
                    });
                  }
                },
                child: Container(
                  alignment: Alignment.center,
                  height: 30.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isOwnProfile ? Colors.white : Colors.blue,
                    borderRadius: BorderRadius.circular(5.r),
                    border: Border.all(
                        color:
                            isOwnProfile ? Colors.grey.shade400 : Colors.blue),
                  ),
                  child: isOwnProfile
                      ? const Text('Edit Your Profile')
                      : const Text(
                          'Follow',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
          Visibility(
            visible: isFollowing && !isOwnProfile,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 13.w),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Firebase_Firestor().flollow(uid: widget.uid);
                        setState(() {
                          isFollowing = false;
                        });
                      },
                      child: Container(
                          alignment: Alignment.center,
                          height: 30.h,
                          width: 100.w,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(5.r),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Text('Unfollow')),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      height: 30.h,
                      width: 100.w,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(5.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Text(
                        'Message',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 5.h),
          SizedBox(
            width: double.infinity,
            height: 30.h,
            child: const TabBar(
              unselectedLabelColor: Colors.grey,
              labelColor: Colors.black,
              indicatorColor: Colors.black,
              tabs: [
                Icon(Icons.grid_on),
                Icon(Icons.video_collection),
                Icon(Icons.person),
              ],
            ),
          ),
          SizedBox(
            height: 5.h,
          )
        ],
      ),
    );
  }

  Future<int> _getFollowerCount() async {
    try {
      final snap =
          await _firebaseFirestore.collection('users').doc(widget.uid).get();
      final data = snap.data();
      final followers = data?['followers'];
      return followers is List ? followers.length : 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getFollowingCount() async {
    try {
      final snap =
          await _firebaseFirestore.collection('users').doc(widget.uid).get();
      final data = snap.data();
      final following = data?['following'];
      return following is List ? following.length : 0;
    } catch (_) {
      return 0;
    }
  }
}
