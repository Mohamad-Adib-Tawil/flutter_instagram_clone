import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/screen/addpost_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
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
    final List<AssetPathEntity> album =
        await PhotoManager.getAssetPathList(type: RequestType.image);
    if (album.isEmpty) return;

    final List<AssetEntity> media =
        await album.first.getAssetListPaged(page: currentPage, size: 60);

    for (var asset in media) {
      if (asset.type == AssetType.image) {
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
        FutureBuilder<Uint8List?>(
          future: asset.thumbnailDataWithSize(ThumbnailSize(200, 200)),
          builder: (context, snapshot) {
            final thumbnail = snapshot.data;
            if (snapshot.connectionState == ConnectionState.done &&
                thumbnail != null) {
              return Container(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.memory(
                        thumbnail,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
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
            'This app needs access to your photos to create posts. Please grant permission in settings.'),
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
      // After returning from settings, re-check permission
      _checkAndRequestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New Post',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: false,
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: GestureDetector(
                onTap: () {
                  final file = _file;
                  if (file == null) return;

                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AddPostTextScreen(file),
                  ));
                },
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: _file == null ? Colors.grey : Colors.blue,
                  ),
                ),
              ),
            ),
          ),
        ],
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

    return SingleChildScrollView(
      child: Container(
        child: Column(
          children: [
            SizedBox(
              height: 375.h,
              child: GridView.builder(
                itemCount: _mediaList.isEmpty ? 0 : 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
                ),
                itemBuilder: (context, index) {
                  final clampedIndex =
                      selectedIndex.clamp(0, _mediaList.length - 1);
                  return _mediaList[clampedIndex];
                },
              ),
            ),
            Container(
              width: double.infinity,
              height: 40.h,
              color: Colors.white,
              child: Row(
                children: [
                  SizedBox(width: 10.w),
                  Text(
                    'Recent',
                    style:
                        TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mediaList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 1,
                crossAxisSpacing: 2,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                      if (index < path.length) {
                        _file = path[index];
                      }
                    });
                  },
                  child: _mediaList[index],
                );
              },
            ),
          ],
        ),
      ),
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
      message = 'You have granted limited access to your photos. '
          'You can select from the available photos or grant full access in settings.';
    } else if (isDenied) {
      title = 'Permission Denied';
      message = 'This app needs access to your photos to create posts. '
          'Please grant permission to continue.';
    } else if (isRestricted) {
      title = 'Access Restricted';
      message = 'Photo access is restricted on this device. '
          'Please check your device settings.';
    } else {
      title = 'Permission Required';
      message = 'This app needs access to your photos to create posts.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLimited ? Icons.photo_library_outlined : Icons.lock_outline,
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
                label: const Text('Load Available Photos'),
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
