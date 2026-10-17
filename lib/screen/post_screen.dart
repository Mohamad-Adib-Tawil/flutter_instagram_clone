// lib/screen/post_screen.dart
// Single post view using Supabase Post model

import 'package:flutter/material.dart';
import 'package:halalgram/data/model/post.dart';
import 'package:halalgram/widgets/post_widget.dart';

class PostScreen extends StatelessWidget {
  final Post post;
  const PostScreen(this.post, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: PostWidget(post)),
    );
  }
}
