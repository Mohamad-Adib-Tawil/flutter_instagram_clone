import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/screen/reelsScreen.dart';
import 'package:flutter_instagram_clone/screen/reels_edite_Screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

class AddReelsScreen extends StatefulWidget {
  const AddReelsScreen({super.key});

  @override
  State<AddReelsScreen> createState() => _AddReelsScreenState();
}

class _AddReelsScreenState extends State<AddReelsScreen> {
  final List<Widget> _mediaList = [];
  final List<File> path = [];
  File? _file;
  int currentPage = 0;
  int? lastPage;
  PermissionState? _permissionState;
  bool _isLoading = false;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  Future<void> _checkAndRequestPermission() async {
    setState(() {
      _isLoading = true;
    });

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!mounted) return;

    setState(() {
      _permissionState = ps;
      _isLoading = false;
    });

    if (ps.isAuth) {
      _fetchNewMedia();
    }
  }

  Future<void> _fetchNewMedia() async {
    lastPage = currentPage;
    List<AssetPathEntity> album =
        await PhotoManager.getAssetPathList(type: RequestType.video);
    List<AssetEntity> media =
        await album[0].getAssetListPaged(page: currentPage, size: 60);

    for (var asset in media) {
      if (asset.type == AssetType.video) {
        final file = await asset.file;
        if (file != null) {
          path.add(File(file.path));
          _file = path[0];
        }
      }
    }
    List<Widget> temp = [];
    for (var asset in media) {
      temp.add(
        FutureBuilder(
          future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (asset.type == AssetType.video)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Container(
                          alignment: Alignment.center,
                          width: 35.w,
                          height: 15.h,
                          child: Row(
                            children: [
                              Text(
                                asset.videoDuration.inMinutes.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                ':',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                asset.videoDuration.inSeconds.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                ],
              );
            }

            return Container();
          },
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _mediaList.addAll(temp);
      currentPage++;
    });
  }

  Future<void> _handlePermissionDenied() async {
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
            'This app needs access to your videos to create Reels. Please grant permission in settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    if (shouldOpenSettings == true && mounted) {
      await PhotoManager.openSetting();
      _checkAndRequestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'New Reels',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissionState == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_permissionState!.isAuth) {
      return _buildPermissionDeniedView();
    }

    return GridView.builder(
      shrinkWrap: true,
      itemCount: _mediaList.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 250,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 5.h,
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = index;
                _file = path[index];
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ReelsEditeScreen(_file!),
                ));
              });
            },
            child: _mediaList[index]);
      },
    );
  }

  Widget _buildPermissionDeniedView() {
    final isLimited = _permissionState == PermissionState.limited;
    final isDenied = _permissionState == PermissionState.denied;
    final isRestricted = _permissionState == PermissionState.restricted;

    String title;
    String message;

    if (isLimited) {
      title = 'Limited Access';
      message = 'You have granted limited access to your videos. '
          'You can select from the available videos or grant full access in settings.';
    } else if (isDenied) {
      title = 'Permission Denied';
      message = 'This app needs access to your videos to create Reels. '
          'Please grant permission to continue.';
    } else if (isRestricted) {
      title = 'Access Restricted';
      message = 'Video access is restricted on this device. '
          'Please check your device settings.';
    } else {
      title = 'Permission Required';
      message = 'This app needs access to your videos to create Reels.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLimited ? Icons.video_library_outlined : Icons.lock_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isLimited) ...[
              ElevatedButton.icon(
                onPressed: _fetchNewMedia,
                icon: const Icon(Icons.refresh),
                label: const Text('Load Available Videos'),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: _handlePermissionDenied,
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
