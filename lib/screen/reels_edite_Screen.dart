import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/data/firebase_service/firestor.dart';
import 'package:flutter_instagram_clone/data/firebase_service/storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class ReelsEditeScreen extends StatefulWidget {
  final File videoFile;
  const ReelsEditeScreen(this.videoFile, {super.key});

  @override
  State<ReelsEditeScreen> createState() => _ReelsEditeScreenState();
}

class _ReelsEditeScreenState extends State<ReelsEditeScreen> {
  final caption = TextEditingController();
  late VideoPlayerController controller;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          controller.setLooping(true);
          controller.setVolume(1.0);
          controller.play();
        }
      });
  }

  @override
  void dispose() {
    super.dispose();
    caption.dispose();
    controller.dispose();
  }

  Future<void> _handleShare() async {
    setState(() {
      isLoading = true;
    });

    try {
      String reelsUrl =
          await StorageMethod().uploadImageToStorage('Reels', widget.videoFile);
      await Firebase_Firestor().CreatReels(
        video: reelsUrl,
        caption: caption.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share Reels: $e')),
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: false,
        title: const Text(
          'New Reels',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.black),
              )
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Column(
                  children: [
                    SizedBox(height: 30.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Container(
                        width: 270.w,
                        height: 420.h,
                        child: controller.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: controller.value.aspectRatio,
                                child: VideoPlayer(controller),
                              )
                            : const CircularProgressIndicator(),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      height: 60,
                      width: 280.w,
                      child: TextField(
                        controller: caption,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          hintText: 'Write a caption ...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Divider(),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          alignment: Alignment.center,
                          height: 45.h,
                          width: 150.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.black,
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            'Save draft',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                        ),
                        GestureDetector(
                          onTap: isLoading ? null : _handleShare,
                          child: Container(
                            alignment: Alignment.center,
                            height: 45.h,
                            width: 150.w,
                            decoration: BoxDecoration(
                              color: isLoading ? Colors.grey : Colors.blue,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              'Share',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
