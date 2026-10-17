// lib/widgets/post_widget.dart
// Post widget using Supabase Post model and Supabase Auth

import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:halalgram/core/auth/auth_service.dart';
import 'package:halalgram/core/database/supabase_client.dart';
import 'package:halalgram/data/model/post.dart';
import 'package:halalgram/data/supabase_service/supabase_profile.dart';
import 'package:halalgram/data/supabase_service/supabase_posts.dart';
import 'package:halalgram/util/image_cached.dart';
import 'package:halalgram/widgets/comment.dart';
import 'package:halalgram/widgets/like_animation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PostWidget extends StatefulWidget {
  final Post post;
  const PostWidget(this.post, {super.key});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool isAnimating = false;
  String user = '';

  @override
  void initState() {
    super.initState();
    user = AuthService.instance.currentUserId ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 375.w,
          height: 54.h,
          color: Colors.white,
          child: Center(
            child: ListTile(
              leading: ClipOval(
                child: SizedBox(
                  width: 35.w,
                  height: 35.h,
                  child: CachedImage(
                    widget.post.author.avatarPath != null
                        ? SupabaseDatabase.avatarsStorage
                            .getPublicUrl(widget.post.author.avatarPath!)
                        : null,
                  ),
                ),
              ),
              title: Text(
                widget.post.author.username,
                style: TextStyle(fontSize: 13.sp),
              ),
              subtitle: Text(
                widget.post.location,
                style: TextStyle(fontSize: 11.sp),
              ),
              trailing: const Icon(Icons.more_horiz),
            ),
          ),
        ),
        GestureDetector(
          onDoubleTap: () {
            if (user.isNotEmpty) {
              // TODO: Phase F - implement Supabase likes
              // Firebase_Firestor().like(...)
              setState(() {
                isAnimating = true;
              });
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 375.w,
                height: 375.h,
                child: CachedImage(
                  SupabaseDatabase.postImagesStorage
                      .getPublicUrl(widget.post.imagePath),
                ),
              ),
              AnimatedOpacity(
                duration: Duration(milliseconds: 200),
                opacity: isAnimating ? 1 : 0,
                child: LikeAnimation(
                  child: Icon(
                    Icons.favorite,
                    size: 100.w,
                    color: Colors.red,
                  ),
                  isAnimating: isAnimating,
                  duration: Duration(milliseconds: 400),
                  iconlike: false,
                  End: () {
                    setState(() {
                      isAnimating = false;
                    });
                  },
                ),
              )
            ],
          ),
        ),
        Container(
          width: 375.w,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 14.h),
              Row(
                children: [
                  SizedBox(width: 14.w),
                  LikeAnimation(
                    child: IconButton(
                      onPressed: () {
                        if (user.isNotEmpty) {
                          // TODO: Phase F - implement Supabase likes
                        }
                      },
                      icon: Icon(
                        Icons.favorite_border,
                        color: Colors.black,
                        size: 24.w,
                      ),
                    ),
                    isAnimating: false,
                  ),
                  SizedBox(width: 17.w),
                  GestureDetector(
                    onTap: () {
                      showBottomSheet(
                        backgroundColor: Colors.transparent,
                        context: context,
                        builder: (context) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: DraggableScrollableSheet(
                              maxChildSize: 0.6,
                              initialChildSize: 0.6,
                              minChildSize: 0.2,
                              builder: (context, scrollController) {
                                return Comment('posts', widget.post.id);
                              },
                            ),
                          );
                        },
                      );
                    },
                    child: Image.asset(
                      'images/comment.webp',
                      height: 28.h,
                    ),
                  ),
                  SizedBox(width: 17.w),
                  Image.asset(
                    'images/send.jpg',
                    height: 28.h,
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(right: 15.w),
                    child: Image.asset(
                      'images/save.png',
                      height: 28.h,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 30.w,
                  top: 4.h,
                  bottom: 8.h,
                ),
                child: Text(
                  // TODO: Phase F - implement likes count from Supabase
                  '0',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.post.author.username +
                            ' :  ' +
                            widget.post.caption,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 15.w, top: 20.h, bottom: 8.h),
                child: Text(
                  formatDate(widget.post.createdAt, [yyyy, '-', mm, '-', dd]),
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
