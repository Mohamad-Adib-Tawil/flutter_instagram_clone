import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/data/firebase_service/firestor.dart';
import 'package:flutter_instagram_clone/data/firebase_service/storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddPostTextScreen extends StatefulWidget {
  final File file;
  const AddPostTextScreen(this.file, {super.key});

  @override
  State<AddPostTextScreen> createState() => _AddPostTextScreenState();
}

class _AddPostTextScreenState extends State<AddPostTextScreen> {
  final caption = TextEditingController();
  final location = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    caption.dispose();
    location.dispose();
  }

  Future<void> _handleShare() async {
    setState(() {
      isLoading = true;
    });

    try {
      String postUrl =
          await StorageMethod().uploadImageToStorage('post', widget.file);
      await Firebase_Firestor().CreatePost(
        postImage: postUrl,
        caption: caption.text,
        location: location.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New post',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: false,
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: GestureDetector(
                onTap: isLoading ? null : _handleShare,
                child: Text(
                  'Share',
                  style: TextStyle(
                    color: isLoading ? Colors.grey : Colors.blue,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.black),
              )
            : Padding(
                padding: EdgeInsets.only(top: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      child: Row(
                        children: [
                          Container(
                            width: 65.w,
                            height: 65.h,
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              image: DecorationImage(
                                image: FileImage(widget.file),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          SizedBox(
                            width: 280.w,
                            height: 60.h,
                            child: TextField(
                              controller: caption,
                              decoration: const InputDecoration(
                                hintText: 'Write a caption ...',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: SizedBox(
                        width: 280.w,
                        height: 30.h,
                        child: TextField(
                          controller: location,
                          decoration: const InputDecoration(
                            hintText: 'Add location',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
