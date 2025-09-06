import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:mywebapp/firebase_options.dart';
import 'package:video_player/video_player.dart';
import 'package:concentric_transition/concentric_transition.dart';
import 'package:scratcher/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: BirthdayApp(),
    ),
  );
}

class BirthdayApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      darkTheme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: OnboardingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MediaGallery extends StatefulWidget {
  const MediaGallery({Key? key}) : super(key: key);
  @override
  _MediaGalleryState createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late AnimationController _uploadAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _uploadProgressAnimation;
  File? _imageFile;
  bool _isUploadingImage = false;
  List<Map<String, String>> _imageData = [];
  File? _videoFile;
  bool _isUploadingVideo = false;
  List<Map<String, String>> _videoData = [];
  Map<String, bool> _scratchedImages = {};
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _uploadAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _uploadProgressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _uploadAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _fetchAllImages();
    _fetchAllVideos();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _uploadAnimationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;
    setState(() => _isUploadingImage = true);
    _uploadAnimationController.forward();
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(
        'birthday_images/$fileName',
      );
      await storageRef.putFile(_imageFile!);
      await _fetchAllImages();
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('Error uploading image: $e');
      HapticFeedback.heavyImpact();
    }
    setState(() => _isUploadingImage = false);
    _uploadAnimationController.reset();
  }

  Future<void> _fetchAllImages() async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'birthday_images',
      );
      final listResult = await storageRef.listAll();
      List<Map<String, String>> images = [];
      for (var item in listResult.items) {
        String url = await item.getDownloadURL();
        images.add({"url": url, "path": item.fullPath});
      }
      setState(() => _imageData = images.reversed.toList());
    } catch (e) {
      print('Error fetching images: $e');
    }
  }

  Future<void> _deleteImage(String path) async {
    try {
      await FirebaseStorage.instance.ref(path).delete();
      _scratchedImages.remove(path);
      await _fetchAllImages();
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  Future<void> _pickVideo() async {
    HapticFeedback.lightImpact();
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });
    final pickedFile = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _videoFile = File(pickedFile.path));
      await _uploadVideo();
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;
    setState(() => _isUploadingVideo = true);
    _uploadAnimationController.forward();
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final storageRef = FirebaseStorage.instance.ref().child(
        'birthday_videos/$fileName',
      );
      await storageRef.putFile(_videoFile!);
      await _fetchAllVideos();
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('Error uploading video: $e');
      HapticFeedback.heavyImpact();
    }
    setState(() => _isUploadingVideo = false);
    _uploadAnimationController.reset();
  }
  Future<void> _fetchAllVideos() async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'birthday_videos',
      );
      final listResult = await storageRef.listAll();
      List<Map<String, String>> videos = [];
      for (var item in listResult.items) {
        String url = await item.getDownloadURL();
        videos.add({"url": url, "path": item.fullPath});
      }
      setState(() => _videoData = videos.reversed.toList());
    } catch (e) {
      print('Error fetching videos: $e');
    }
  }
  Future<void> _deleteVideo(String path) async {
    try {
      await FirebaseStorage.instance.ref(path).delete();
      await _fetchAllVideos();
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('Error deleting video: $e');
    }
  }
  void _confirmDelete(String path, bool isImage) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isImage ? Icons.image_outlined : Icons.videocam_outlined,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Delete ${isImage ? 'Image' : 'Video'}?",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "This action cannot be undone",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          isImage ? _deleteImage(path) : _deleteVideo(path);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Delete"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildEmptyState(bool isImages) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isImages ? Icons.image_outlined : Icons.videocam_outlined,
              size: 50,
              color: Theme.of(context).primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isImages ? "No Images Yet" : "No Videos Yet",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            isImages
                ? "Tap the + button to add your first image"
                : "Tap the + button to add your first video",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
  Widget _buildImageCard(Map<String, String> image, int index) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String imagePath = image["path"]!;
    final bool isScratched = _scratchedImages[imagePath] ?? false;
    return Hero(
      tag: 'image_${image["path"]}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                image["url"]!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (!isScratched)
                GestureDetector(
                  onDoubleTap: () {
                    setState(() {
                      _scratchedImages[imagePath] = true;
                    });
                    HapticFeedback.mediumImpact();
                  },
                  child: Scratcher(
                    brushSize: 100,
                    threshold: 100,
                    color: Colors.grey.shade400,
                    onChange: (value) {
                      if (value > 30) {
                        setState(() {
                          _scratchedImages[imagePath] = true;
                        });
                        HapticFeedback.mediumImpact();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.touch_app,
                                size: 50,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Scratch or Double-Tap to reveal",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Surprise! 🎉",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // ✅ Delete button → only visible if scratched AND user = sathish
              if (isScratched && userProvider.canModifyImages)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _confirmDelete(image["path"]!, true),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 18,
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

  Widget _buildVideoCard(Map<String, String> video, int index) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Hero(
      tag: 'video_${video["path"]}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();

              // Instant navigation with custom transition
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      VideoPlayerScreen(videoUrl: video["url"]!),
                  transitionDuration: const Duration(milliseconds: 200),
                  reverseTransitionDuration: const Duration(milliseconds: 150),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        // Faster, smoother transition
                        return FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0.0, 0.1),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutQuart,
                                  ),
                                ),
                            child: child,
                          ),
                        );
                      },
                ),
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.8),
                        Theme.of(context).primaryColor.withOpacity(0.6),
                        Theme.of(context).primaryColor.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),

                // Play button with animation
                Center(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween(begin: 0.8, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Delete button (only show for authorized users)
                if (userProvider.canModifyImages)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _confirmDelete(video["path"]!, false),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                // Video label
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Video",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Loading indicator overlay (subtle)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.touch_app,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withOpacity(0.8),
                ),
              ),
            ),
          ),

          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Theme.of(context).primaryColor,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, size: 20),
                        SizedBox(width: 8),
                        Text("Images"),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_outlined, size: 20),
                        SizedBox(width: 8),
                        Text("Videos"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
              ],
            ),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              Column(
                children: [
                  if (_isUploadingImage)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cloud_upload,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Uploading image...",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AnimatedBuilder(
                            animation: _uploadProgressAnimation,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: _uploadProgressAnimation.value,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _imageData.isEmpty
                        ? _buildEmptyState(true)
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 1,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1,
                                  ),
                              itemCount: _imageData.length,
                              itemBuilder: (context, index) {
                                return AnimatedContainer(
                                  duration: Duration(
                                    milliseconds: 200 + (index * 50),
                                  ),
                                  curve: Curves.easeOutBack,
                                  child: _buildImageCard(
                                    _imageData[index],
                                    index,
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
              Column(
                children: [
                  if (_isUploadingVideo)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cloud_upload,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Uploading video...",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AnimatedBuilder(
                            animation: _uploadProgressAnimation,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: _uploadProgressAnimation.value,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _videoData.isEmpty
                        ? _buildEmptyState(false)
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 1,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1,
                                  ),
                              itemCount: _videoData.length,
                              itemBuilder: (context, index) {
                                return AnimatedContainer(
                                  duration: Duration(
                                    milliseconds: 200 + (index * 50),
                                  ),
                                  curve: Curves.easeOutBack,
                                  child: _buildVideoCard(
                                    _videoData[index],
                                    index,
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            // ✅ Show FAB only if user is sathish
            if (!userProvider.canModifyImages) {
              return const SizedBox.shrink(); // Empty widget
            }

            return AnimatedBuilder(
              animation: _fabScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fabScaleAnimation.value,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      if (_tabController.index == 0) {
                        _pickImage();
                      } else {
                        _pickVideo();
                      }
                    },
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      _tabController.index == 0 ? "Add Image" : "Add Video",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({Key? key, required this.videoUrl}) : super(key: key);
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsOpacityAnimation;
  bool _showControls = true;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    print("videoUrlvideoUrlvideoUrl${widget.videoUrl}"); // i have url inmy log

    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _controlsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.network(
        widget.videoUrl,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      // Add listener for errors
      _controller.addListener(() {
        if (_controller.value.hasError) {
          setState(() {
            _hasError = true;
            _errorMessage =
                _controller.value.errorDescription ?? 'Unknown error occurred';
          });
        }
      });

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Auto-play the video
        _controller.play();

        // Show controls initially
        _controlsAnimationController.forward();

        // Auto-hide controls after 3 seconds
        _autoHideControls();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video: $e';
        });
      }
    }
  }

  void _autoHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        _hideControls();
      }
    });
  }

  void _showControlsTemp() {
    setState(() => _showControls = true);
    _controlsAnimationController.forward();
    _autoHideControls();
  }

  void _hideControls() {
    setState(() => _showControls = false);
    _controlsAnimationController.reverse();
  }

  void _retryVideo() {
    setState(() {
      _hasError = false;
      _isInitialized = false;
      _errorMessage = '';
    });
    _controller.dispose();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller.dispose();
    _controlsAnimationController.dispose();
    super.dispose();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Loading video...",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please wait",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Failed to load video",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.7),
                  ),
                  child: const Text("Close"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _retryVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _isInitialized
            ? (_showControls ? _hideControls : _showControlsTemp)
            : null,
        child: Stack(
          children: [
            // Video player or loading/error states
            if (_hasError)
              _buildErrorState()
            else if (!_isInitialized)
              _buildLoadingState()
            else
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),

            // Controls overlay (only show when video is initialized)
            if (_isInitialized && !_hasError)
              AnimatedBuilder(
                animation: _controlsOpacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _controlsOpacityAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // Top controls
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Play/Pause button
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _controller.value.isPlaying
                                      ? _controller.pause()
                                      : _controller.play();
                                });
                                HapticFeedback.lightImpact();
                              },
                              icon: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Bottom controls with progress bar
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true,
                                  colors: VideoProgressColors(
                                    playedColor: Theme.of(context).primaryColor,
                                    bufferedColor: Colors.white.withOpacity(
                                      0.3,
                                    ),
                                    backgroundColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      _formatDuration(
                                        _controller.value.position,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDuration(
                                        _controller.value.duration,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Always show back button even during loading
            if (!_isInitialized || _hasError)
              SafeArea(
                child: Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatingAnimation;

  final List<Map<String, dynamic>> quotes = [
    {
      "text": "You are the sunshine in my life!",
      "emoji": "☀️",
      "gradient": [Color.fromARGB(255, 241, 236, 228), Color(0xFF19547B)],
    },
    {
      "text": "Every moment with you is a blessing",
      "emoji": "💝",
      "gradient": [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
    },
    {
      "text": "Your smile lights up my world",
      "emoji": "😊",
      "gradient": [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
    },
    {
      "text": "You make ordinary days extraordinary",
      "emoji": "✨",
      "gradient": [Color(0xFFFFD89B), Color(0xFF19547B)],
    },
    {
      "text": "Grateful for your amazing friendship",
      "emoji": "🙏",
      "gradient": [Color(0xFF667eea), Color(0xFF764ba2)],
    },
    {
      "text": "You're one in a million!",
      "emoji": "🌟",
      "gradient": [Color(0xFFf093fb), Color(0xFFf5576c)],
    },
    {
      "text": "Your kindness inspires me daily",
      "emoji": "💖",
      "gradient": [Color(0xFF4facfe), Color(0xFF00f2fe)],
    },
    {
      "text": "Life is better with you in it",
      "emoji": "🌈",
      "gradient": [Color(0xFF43e97b), Color(0xFF38f9d7)],
    },
    {
      "text": "You bring joy wherever you go",
      "emoji": "🎊",
      "gradient": [Color(0xFFfa709a), Color(0xFFfee140)],
    },
    {
      "text": "Thank you for being you!",
      "emoji": "🤗",
      "gradient": [Color(0xFFa8edea), Color(0xFFfed6e3)],
    },
    {
      "text": "Your laughter is my favorite sound",
      "emoji": "😄",
      "gradient": [Color(0xFFff9a9e), Color(0xFFfecfef)],
    },
    {
      "text": "You're incredibly special to me",
      "emoji": "💕",
      "gradient": [Color(0xFF667eea), Color(0xFF764ba2)],
    },
    {
      "text": "Dreams come true because of friends like you",
      "emoji": "🌙",
      "gradient": [Color(0xFF5ee7df), Color(0xFF66a6ff)],
    },
    {
      "text": "You make everything more fun!",
      "emoji": "🎈",
      "gradient": [Color(0xFFffecd2), Color(0xFFfcb69f)],
    },
    {
      "text": "Your friendship is my treasure",
      "emoji": "💎",
      "gradient": [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
    },
    {
      "text": "You have the most beautiful soul",
      "emoji": "👼",
      "gradient": [Color(0xFFfad0c4), Color(0xFFfad0c4)],
    },
    {
      "text": "Every day is brighter with you around",
      "emoji": "🌅",
      "gradient": [Color(0xFFffecd2), Color(0xFFfcb69f)],
    },
    {
      "text": "You're absolutely amazing!",
      "emoji": "🌺",
      "gradient": [Color(0xFFf093fb), Color(0xFFf5576c)],
    },
    {
      "text": "Your heart is pure gold",
      "emoji": "💛",
      "gradient": [Color(0xFFFFD89B), Color(0xFF19547B)],
    },
    {
      "text": "You deserve all the happiness in the world",
      "emoji": "🌍",
      "gradient": [Color(0xFF43e97b), Color(0xFF38f9d7)],
    },
    {
      "text": "You're my favorite person!",
      "emoji": "👑",
      "gradient": [Color(0xFFfa709a), Color(0xFFfee140)],
    },
    {
      "text": "Thanks For Everything",
      "emoji": "🎂",
      "gradient": [Color.fromARGB(255, 154, 164, 255), Color.fromARGB(255, 214, 184, 241)],
    },
     {
      "text": "All The best For your Happiest Future!",
      "emoji": "🎂",
      "gradient": [Color.fromARGB(255, 154, 235, 255), Color.fromARGB(255, 199, 226, 223)],
    },
     {
      "text": "Happy 24nd Birthday, beautiful soul!",
      "emoji": "🎂",
      "gradient": [Color(0xFFff9a9e), Color(0xFFf6d365)],
    },
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
       
        child: SafeArea(
          child: Column(
            children: [
              
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: quotes.length,
                    itemBuilder: (context, index) {
                      return _buildQuoteCard(index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  Widget _buildQuoteCard(int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 100 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(100 * (1 - value), 0),
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(opacity: value, child: child),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        child: Stack(
          children: [
            // Glassmorphic Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: quotes[index]["gradient"],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                ),
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Quote Number with Animation
                    AnimatedBuilder(
                      animation: _floatingAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatingAnimation.value),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: quotes[index]["gradient"][1],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quotes[index]["text"],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.4,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                quotes[index]["emoji"],
                                style: TextStyle(fontSize: 20),
                              ),
                              SizedBox(width: 8),
                              Container(
                                height: 2,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value * 0.5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFf5576c).withOpacity(0.4),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MediaGallery()),
                );
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              label: Text(
                "Gallery",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              icon: Icon(Icons.photo_library_rounded, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

class OurJourneyScreen extends StatefulWidget {
  const OurJourneyScreen({super.key});

  @override
  _OurJourneyScreenState createState() => _OurJourneyScreenState();
}
class _OurJourneyScreenState extends State<OurJourneyScreen>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatingController;
  late Animation<double> _heartAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;

  ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  @override
  void initState() {
    super.initState();

    _heartController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _heartAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _floatingAnimation = Tween<double>(begin: -15, end: 15).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _heartController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _floatingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  final List<Map<String, dynamic>> storyParts = [
    {
      "title": "December Beginning ✨",
      "text":
          "En life la first time entry anathu December month starting la, unna pathen... 😍 Yellow color dress la iruntha. Apram oru 10 times night la Ambattur stop la pathu erundhen. Even en sight kuda adichu iruken 😅.",
      "icon": "👀",
      "color": [Color(0xFF2D1B69), Color(0xFF11998e)],
    },
    {
      "title": "First Eye Contact 👀",
      "text":
          "Correct ahh December 24 evng, na bus stop la wait pannitu irundhappo, ni correct ahh vantha — green color dress, red color headset, one-side bag 😌. Un friends kita pesitu iruka nerathula, avanga sonna: 'Hey, unna antha ponnu pakudhu! Sirikuthu da!' 😆 So nanum eti pathen... yaru nu paatha, athu nee. Aparam tan eye contact vanthuchu 👀.",
      "icon": "💫",
      "color": [Color(0xFF134E5E), Color(0xFF71B280)],
    },
    {
      "title": "The Smile 😊",
      "text":
          "Nanum 2 times pathen, sirichen... niyum smile pannaaa 😊 Then, ni bus la erita 🚍.",
      "icon": "😊",
      "color": [Color(0xFF1A2980), Color(0xFF26D0CE)],
    },
    {
      "title": "Blue Dress Day 💙",
      "text":
          "Next day 25 leave, 26th morning la Chathiram bus stop la pathen — Blue color top, light blue jeans, loose hair 😍 Same bag, one side la. Front la eruntha... Na una pinnadi tan utkanthu erundhen. Ni enna pakkanum pakkanum nu na seat la straight ahh utkanthu irundhen 😐 Ni ennapaaka vey illa 😔. Ambattur la erangum pothu pesanumnu try panen, Aana pathen, kandukama poita 😢.",
      "icon": "💙",
      "color": [Color(0xFF0F4C75), Color(0xFF3282B8)],
    },
    {
      "title": "Evening Wait & Hope 🌅",
      "text":
          "Evening la bus stop la wait pannitu irundhen. Ni vantha... eye contact again... smile 😊 Aparam ni bus la erita 😔 D70 la naan, 77 la neenga. Thirumangalam kitayile 77 pinnaadi tan vanthu irundhuchu 😅. Ni bus front la stand pannitu iruntha.",
      "icon": "🚌",
      "color": [Color(0xFF283593), Color(0xFF1E88E5)],
    },
    {
      "title": "Chase & Connect 🏃‍♂️",
      "text":
          "CMBT enter aagum pothu, na erangiten... Aavai, police station side la fast ahh nadanthu vanthen 🏃‍♂️ Una paakanumnu thonichu, pathuten... Niyum smile panitu 'bye' sonna 👋😊",
      "icon": "🏃‍♂️",
      "color": [Color(0xFF512DA8), Color(0xFF7B1FA2)],
    },
    {
      "title": "Orange Chudi Day 🧡",
      "text":
          "Next day evening, ni orange color chudi la vantha. Yar kitayoo call la pesitu iruntha, serious ahh 😐 Na unnai paathu, 'Hey, edhachu problem ah?' nu keten. Ni sonna: 'V2 la land problem' 🏡 Aparam un name keten, Therinju apdiye keten: 'Appering?' Summava keten.",
      "icon": "🧡",
      "color": [Color(0xFF673AB7), Color(0xFF9C27B0)],
    },
    {
      "title": "The Big Bus & Connection 🚍",
      "text":
          "Aparam D70 white board vanthu, periya bus erunthuchu, standing la irundhom 😩 Pesitu irundhom. Na keten: 'Social media la illa ya?' Ni: 'Illaye...' Na: 'Eppadi contact pannanum?' Ni sirichaaa... 😊 Apram seat kedachuchu... Ni: 'Unna utkaranum.' Na utkanthen 😇 Un kooda bag keten, na vachukiten 🎒 Aparam 2 perum namma pathi pesi pesi vandhom 😄",
      "icon": "🎒",
      "color": [Color(0xFF8E24AA), Color(0xFFE91E63)],
    },
    {
      "title": "The Number 📝",
      "text":
          "Bus erangum pothu, ni ticket la number ezhuthi thandha 📝 Na room ponathum text panniten 📲",
      "icon": "📱",
      "color": [Color(0xFFC2185B), Color(0xFFFF5722)],
    },
    {
      "title": "Daily Journey Begins 💑",
      "text":
          "Aparam daily evening on a tha ponom 💑 Guindy varai naan vanthen... Jan la CMBT la room shift panniten... Aparam epoyachum ekkatutanga 😢 Daily bus la pora antha konjam neram romba jolly ahh irukum 🚌💕 Nila pathi share pannen... Unakku en mela kovam vanthuchu 😠 Aparam apdiye poi irunthuchu...",
      "icon": "🚌",
      "color": [Color(0xFF455A64), Color(0xFF607D8B)],
    },
    {
      "title": "Chicken Rice & Care 🍗",
      "text":
          "Apram naanum niyum chicken rice saapten 🍗🍚 Ni en mela care panna mathiri feel aachu 💗 Un kooda vara pothu happy ahh irukum 😄 Vinin intro pannom 🎉",
      "icon": "🍚",
      "color": [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
    },
    {
      "title": "Growing Closer 🥰",
      "text":
          "Aparam daily pola poi irundhuchu... Jan fulla apdiye poguthu... Feb starting la romba close aiten 🥰 Un advice romba helpful... Nila vishyam la kutty fight la pottom 🤭",
      "icon": "💝",
      "color": [Color(0xFF2D1B69), Color(0xFF11998e)],
    },
    {
      "title": "First Touch ✋❤️",
      "text":
          "Feb 3, first time un kaiya pudichen ✋❤️ Enakku theriyala... Un kai pudicha pothu support maari feel aachu 🫂",
      "icon": "🤝",
      "color": [Color(0xFF134E5E), Color(0xFF71B280)],
    },
    {
      "title": "Special Day - Birthday 🎂",
      "text":
          "Feb 21 — Nila birthday 🎂 That day, en life la never marakamatten 🙏 Mrng 10.30 ku ni en room vantha... Periods time vera 🙈 Na: 'Unna paka venam venam' sonna. Ni convince pannitu vantha 🤗",
      "icon": "🎉",
      "color": [Color(0xFF1A2980), Color(0xFF26D0CE)],
    },
    {
      "title": "Room Kiss 😘",
      "text":
          "Room la kiss keten 😘 Ni 'no' sonnathum door lock pannitten 🚪 Apram mudincha mudinja sonna... 'Seri' nu bus stop ku ponom. Anga bus illa... Enakku un mela kovam 😤 Na tittu tittu irundhen. Aana ni porumaiya irundha 😔❤️",
      "icon": "💋",
      "color": [Color(0xFF0F4C75), Color(0xFF3282B8)],
    },
    {
      "title": "Mall & Movie 🛍️🎬",
      "text":
          "10.00 ku apram forum mall ponom 🛍️ Next day movie ponom 🎬 Antha movie enakku epovum special 🌟",
      "icon": "🎬",
      "color": [Color(0xFF283593), Color(0xFF1E88E5)],
    },
    {
      "title": "Daily Attempts & Big Fight 💔",
      "text":
          "Daily morning try pannitu irundhom... Apram PRL la oru periya fight vanthuchu 💔 Na night 76 bus la irukumbothu... Kovam la unna vituten 😢 Antha na panra periya thapu... Apram tan namakulla break aachu 💔 Na pudikkama pona maathiri irunthaalum... Ni nalla avoid pannina...",
      "icon": "⚡",
      "color": [Color(0xFF512DA8), Color(0xFF7B1FA2)],
    },
    {
      "title": "Daily Fights & 104 Bus 🚌",
      "text":
          "Daily sanda... 😖 Evening la 104 la poga arambichom 🚌 Na avalo kenjinen... Because enakku unna romba pudikum 💕 Important person nee... So ego pakama kenjinen... Alauthen... 😭 Un kitaye poi poi irunthuchu...",
      "icon": "😭",
      "color": [Color(0xFF673AB7), Color(0xFF9C27B0)],
    },
    {
      "title": "Instagram Discovery 📱💔",
      "text":
          "One day, May month la, D k insta ID kandupidichen 🔍 Request kuduthen... Athuketathu full ahh odanjuten 💔 En emotions control panna mudiyala. Un kai pidichen 🙏 Un mela romba sorry... 😞 Bus la kuda pesa try pannina, Na pressure la irundhen 😣 Un kitaye avlo kovam 😖",
      "icon": "📱",
      "color": [Color(0xFF8E24AA), Color(0xFFE91E63)],
    },
    {
      "title": "Breaking Point 😭",
      "text":
          "Room ku vanthu aluthen 😭 Yar kitayum solla mudiyala... Unna miss panren nu theriyuthu... Call pannitu pesuna, Ni romba pannina... Vini kuda senthu... Aparam ni D ah pakurathu enaku romba hurt aachu 💔 Apo tan purinjudhu... Ni thapu pannala... Na dhan thapu pannen... Karma enaku venumnu nenachen... Romba hurt aachu...",
      "icon": "💔",
      "color": [Color(0xFFC2185B), Color(0xFFFF5722)],
    },
    {
      "title": "Forever Promise 💞",
      "text":
          "Unna yarukum vitu kuduka maten 😭 Un life la amma, appa, tambi, akka, apram na dhan eruken. Apdiyea iruppen... Because: You are my caretaker, my soul, my comfort zone, my happy place. 💞💫",
      "icon": "♾️",
      "color": [Color(0xFF455A64), Color(0xFF607D8B)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Container(
      
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildSliverAppBar(),



            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return   _secretTapCount==10?      _buildStoryCard(index):SizedBox();
              }, childCount: storyParts.length),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  int _secretTapCount = 0;

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: const Color.fromARGB(255, 210, 188, 235),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          child: Stack(
            children: [
              Stack(
                children: [
                
                  Center(
                    child: Lottie.asset(
                      'assets/love hearts.json',
                      width: 200, // adjust size
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
              ...List.generate(15, (index) => _buildFloatingHeart(index)),

              // Main Content
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 80),
                        AnimatedBuilder(
                          animation: _heartAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _heartAnimation.value,
                              child: Icon(
                                Icons.favorite,
                                size: 50,
                                color: Colors.red,
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Our Beautiful Journey",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),

                        /// 🔥 Hidden Easter Egg
                        InkWell(
                          onTap: () {
                           


                              setState(() {
      _secretTapCount++;
    });
                            if (_secretTapCount >= 15) {
                              _secretTapCount = 0; // reset
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SecretScreen(),
                                ),
                              );
                            }
                          },
                          child: Text(
                            "Every moment, every memory ✨",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildFloatingHeart(int index) {
    final random = math.Random(index);
    final left = random.nextDouble() * 300;
    final animationDelay = random.nextDouble() * 2000;

    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Positioned(
          left: left,
          top: 100 + (index * 15.0) + _floatingAnimation.value,
          child: Opacity(
            opacity: 0.3 + (random.nextDouble() * 0.4),
            child: Icon(
              Icons.favorite,
              color: Colors.red,
              size: 12 + (random.nextDouble() * 8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoryCard(int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 600 + (index * 150)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: Opacity(opacity: value, child: child),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Stack(
          children: [
            // Story Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: storyParts[index]["color"],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: storyParts[index]["color"][1].withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
                padding: EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _floatingAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatingAnimation.value * 0.3),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  storyParts[index]["icon"],
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            storyParts[index]["title"],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        storyParts[index]["text"],
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black.withOpacity(0.1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index < storyParts.length - 1)
                      Center(
                        child: Container(
                          margin: EdgeInsets.only(top: 20),
                          width: 3,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                      Colors.white.withOpacity(0.05),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}
class _MyWidgetState extends State<MyWidget> {
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/Christmaswindchimes.json'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: TextFormField(
                  controller: userProvider.nameController,
                  decoration: const InputDecoration(
                    labelText: 'Enter text',
                    border: OutlineInputBorder(),
                  ),
                  validator: userProvider.validateName,
                ),
              ),
              const SizedBox(height: 12),
              IconButton(
                icon: const Icon(Icons.wallet_giftcard_sharp, size: 48),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (userProvider.checkAndNavigate(context)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyHomePage()),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  OnboardingPage({Key? key}) : super(key: key);
  final data = [
    CardPlanetData(
      title: "Happy Birthday 🎂",
      subtitle:
          "Wishing you endless joy, laughter, and love on your special day. You deserve all the happiness in the world!",
      image: Lottie.asset('assets/Gift Box.json'),
      backgroundColor: const Color(0xFF0043D0),
      titleColor: Colors.white,
      subtitleColor: Colors.white,
    ),
    CardPlanetData(
      title: "With Lots of Love ❤️",
      subtitle:
          "May your birthday be as beautiful and sweet as your heart. Here's to celebrating you today and always!",
      image: Lottie.asset('assets/love hearts.json'),
      backgroundColor: Colors.white,
      titleColor: const Color(0xFF0043D0),
      subtitleColor: const Color.fromRGBO(0, 10, 56, 1),
    ),
    CardPlanetData(
      title: "A Special Surprise 🎁",
      subtitle:
          "Every moment with you is a gift. May this year bring new adventures, success, and unforgettable memories!",
      image: Lottie.asset('assets/Happy gift.json'),
      backgroundColor: const Color.fromARGB(255, 139, 115, 245),
      titleColor: Colors.white,
      subtitleColor: const Color.fromARGB(255, 0, 0, 0),
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConcentricPageView(
        colors: data.map((e) => e.backgroundColor).toList(),
        itemCount: data.length,
        itemBuilder: (int index) {
          return CardPlanet(data: data[index]);
        },
        onFinish: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyWidget()),
          );
        },
      ),
    );
  }
}
class CardPlanetData {
  final String title;
  final String subtitle;
  final Widget image; // Changed to Widget
  final Color backgroundColor;
  final Color titleColor;
  final Color subtitleColor;
  final Widget? background;
  CardPlanetData({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.backgroundColor,
    required this.titleColor,
    required this.subtitleColor,
    this.background,
  });
}
class CardPlanet extends StatelessWidget {
  const CardPlanet({required this.data, Key? key}) : super(key: key);
  final CardPlanetData data;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (data.background != null) data.background!,
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              SizedBox(height: 200, child: data.image), // Use directly
              const Spacer(flex: 1),
              Text(
                data.title.toUpperCase(),
                style: TextStyle(
                  color: data.titleColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
              const Spacer(flex: 1),
              Center(
                child: Text(
                  data.subtitle,
                  style: TextStyle(color: data.subtitleColor, fontSize: 14),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                ),
              ),
              const Spacer(flex: 6),
            ],
          ),
        ),
      ],
    );
  }
}

class UserProvider with ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  String? _loggedInUser;

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter something";
    }
    if (value != "sathish@soul" && value != "snegasoul") {
      return "Value must be ''";
    }
    return null;
  }

  bool checkAndNavigate(BuildContext context) {
    final name = nameController.text.trim().toLowerCase();
    if (name == "sathish@soul" || name == "snegasoul") {
      _loggedInUser = name; // store logged user
      notifyListeners();
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect value—it must be '*******88")),
      );
      return false;
    }
  }
  String? get loggedInUser => _loggedInUser;
  bool get canModifyImages => _loggedInUser == "sathish@soul";
  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> {
  final _pageController = PageController(initialPage: 0);
  final NotchBottomBarController _controller = NotchBottomBarController(
    index: 0,
  );
  int maxCount = 5;
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final List<Widget> bottomBarPages = [
      HomeScreen(),
      const MediaGallery(),
      const OurJourneyScreen(),
    ];
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          bottomBarPages.length,
          (index) => bottomBarPages[index],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: (bottomBarPages.length <= maxCount)
          ? AnimatedNotchBottomBar(
              notchBottomBarController: _controller,
              color: const Color.fromARGB(255, 201, 199, 199),
              showLabel: true,
              textOverflow: TextOverflow.visible,
              maxLine: 1,
              shadowElevation: 5,
              kBottomRadius: 28.0,
              notchColor: const Color.fromARGB(255, 130, 96, 223),
              removeMargins: false,
              bottomBarWidth: 500,
              showShadow: false,
              durationInMilliSeconds: 300,
              itemLabelStyle: const TextStyle(fontSize: 10),
             elevation: 1,
              bottomBarItems: const [
                BottomBarItem(
                  inActiveItem: Icon(Icons.home_filled, color: Colors.blueGrey),
                  activeItem: Icon(Icons.home_filled, color: Colors.white),
                  itemLabel: 'Home',
                ),
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.wallet_giftcard_outlined,
                    color: Colors.blueGrey,
                  ),
                  activeItem: Icon(
                    Icons.wallet_giftcard_outlined,
                    color: Colors.white,
                  ),
                  itemLabel: 'Suprise',
                ),
                BottomBarItem(
                  inActiveItem: Icon(Icons.favorite, color: Colors.blueGrey),
                  activeItem: Icon(Icons.favorite, color: Colors.white),
                  itemLabel: 'Memories',
                ),
              ],
              onTap: (index) {
                _pageController.jumpToPage(index);
              },
              kIconSize: 24.0,
            )
          : null,
    );
  }
}
class SecretScreen extends StatefulWidget {
  const SecretScreen({super.key});
  @override
  State<SecretScreen> createState() => _SecretScreenState();
}
class _SecretScreenState extends State<SecretScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Hi Sneka 💖 Life oda end ku ponalaum   like  age 25- 60 analum oru silar person  avanga namba kuda illa nalum avanga memoeries namba kuda vey erukum  i hope athu mathri tan enaku niumm ..Enaku ni life la Happy ahh erukanum sirichuteyy erukanum...unaku nalla understanding oda oru life partner kedaikanum...recent ahh ni pantra hardworkk ku la nalla result ahh un life nalla padiya erukanum na pray panntren epovum pray pannuven snega.,Ni oru special gem person 💎 100% ,--unkita pudikatha tha vida puduchathu tan atigam..ni pantra oru china china visayam kuda ena romba impresee panni eruku....life la unna mathri oru preson meet pannathu romba happy and lucky.. epovumm unna vi2 kudakamaten..one day ku na daily athigama nenaikuren unna .... enoda breakup aprm en life la second love ku chance-ey illa nu nenachen… but unna first time pakum pothu kuda oru good feel 🥰. Nalla friends apdi dhan irunthom… but poga poga un mela affection atigama achu ❤️.Feb 21 antha day 😍, na life la expect pannatha nadanthathu. Morning 10.30 to evening 7.30 — entire day — andha time romba romba special for me 🌸. Enimel apdi oru moment kidaikum nu kuda theriyala 😌. Unoda character therinjitu ni ennoda mela care ah dhan irunthiya 🤗.Ethachum konjam na enna change panna try panninen… panniten nu namburen 💪. First time un hand pudicha pothu 🤝… andha feel something special ❤️🔥. Na unakaga ethachum pannathum illa… ennala mudincha vishayam unaku wait panni unkuda antha konjam neram bus travel 🚍 — athuve mattum dhan ennala mudinathu. Dec 28 la irunthu iniku varikum atha panniten 🙈.Ni first sonna 21 Feb evng park la enaku un mela love feel vandhuchu 💕. But caste reason nala sollala 😔. Athai kekka kuda happy ah irunthuchu 😌… but appo kuda hurt ayiten 💔. Days poga poga dhan oru person oda value ennanu purinjathu. Apo dhan realize panninen — unna mathiri oru ponnu kidaikurathu romba rare 🌹. Ni oru real gem 💎.Apo dhan life la first time caste ah nenachen 😢. "Ithu illa Sneka ku enna pudikum la?" nu yosichen. Aana unna romba pudikum dii ❤️. Ni pesurathu 🎶… na unnai pathu iruka pothu 😍… ni en kitta kekra parvai la 💫… athu enaku romba pudikum 😘.Main ah antha "YES YES" 💍, aprm @shot dog ku sonna vishayam 🐶… athu mathiri naraya iruku. Unkitta pudikatha konjam visayangal kuda irunthuchu… aana andha konjam vishayam dhan enaku narya hurt panniduchu 🥺.Sometimes na yosippen — Sneka life la na varaama iruntha, avalukku pudicha vishayam pannitu happy ah irupa nu 😌. "Thevai illa naama dhan vandhutom" nu feel pannuren 😢. Athu en reason unakum theriyum.Enkitta avlo easy ah azhaga varaathu 😞. Aana un visayathula nenachitu pogum pothu aluthuvaren 😭. Sometime ellarum thapu pannuvanga… nanum unkitte narya thapu panniten 💔. Aprl month night 76 bus la na vitutu poi iruka koodathu 🚍… appo dhan namma bond break anathu 😞.First time movie pakka ponapothu 🎬… andha 2 hours la last life oda end varikum maraka maten 💕. Antha first kiss 💋, first touch ✋, first hug 🤗 — athu romba special Sneka. Unna romba miss pannuren 😢.Theriyum, na unkitte antha feelings ah nalla express pannala 😔. First un range ennanu purinjukittu… unna top la vachiruken 👑. Enaku nalla theriyum ni ennai avoid panradhu. Unaku na deserve illa nu nenaipen… aana kastama iruku 💔.Fine… unaku na romba expensive gift kudutha kuda, na avlo happy feel panna maten. Aana andha earning umm antha povum vangi kudutha pothu dhan enaku avlo happiness 🥹. Then  Ni ennoda life la en partner ahh  en wife ahh Nmaba babys ku amma va aprm en amma appa ku nalla ponna erukum nu naraya time asa pa2eruken .sila visyam namaku kedaikathu nu therunjum asa padurathu oru pain. Intha birthday unkuda iruken 🎂… next birthday epdi nu theriyala 🤷… but epovum unaga irupen… varuven  ,ipo la enna avoid pantra nu nalla therium enaku , but enakum avoid  panna manasuvarala  munjula adicha mathiri pesura...athu enkau palagiruchu...but  poga poga distance atigama aguthu athu tan enaku kastam eruku...unaku vera oru person puduchuruku enaku therium parava but ithuvaraikum niya enkit avanthu ath apathi pesa kuda  enkit apesur atime kamiairuchu  new peron vanthutangaaa....enaku possove aguthu...athuveyy unakit aerunth alove ethiapthi  na ethvum mey pannala but apo apo feel agum hurt agum....namba ennn ver aunierse la poranthu eruka kudathu... apoyachum enn aethupila...enaku mentaly and phucial ahhh yarkudaiumm  ivlo attach anathu ill ajanani .nila aprm ni tan snega... thanks for everything romba miss pannuven unna. enkita ethuvumey illa unaku kudu enakit aerukathu illa unkud atime spend pantarthu tan then enaku finacial problem ill ana unaku naray seiyanum vangikudukanum naraya explore pannum romba asai but unfortunately enakit source illa.na kadaisi varikum un kud aerunth happy ana memeories ma2um en life la gothroe pannni kondupoven...enaku ethu nalla natanthulum nium erukanum.ithu ithod break aira kuda.100% sure unkita close anathuku aprm unkit aethuvumey marachathula.. but ni ethuvum vachuerukiy anu theriyal.. ni ipo site adikura logesh unaku pudcu @ perukum puduchu love okey agi..marriage pani avan unn ahappy ahh pathukita enaku jelaouse agum erunthalum 2perum happy ahh erukanum pray pannuven.enfriend ma22um illa di  ni enod afamil memeber ahh tan pakuren. unna ethucmm hurt panni eruntha sorry snega .next jenmam eruntha kandiap unna mathiri oru person kuda lige poganum ❤️.Love you snega un mela  enaku vanth ahh feeling ma2um 100% unmaai na thirumangalam ahh papen othukuren athukaga un mela eruntha feel poi illa na yarukum alayala illa un akka number ketathu un birthady kaga avanag wish panna solli memories collect pannatan avanag anumber keten matha padi enth athapa intenstion la number kekal avanag instgram la request kuduthen accept panna vey illa atha un kita aka number keten same athukaga tan meghana number umm unkita vanguna othervise ver aenth areson umm illa 28-aug-2025 thursday night vini enkita anth apaiyan kamichathu na over react pannieruka kudatha antha word use panni eruka kudath enaku 2 weeks munadiyea therium unaku logesh ahh puduchueruku nu ni vini t atempel pogumpoth sollieruka..ava enkit asonna snega logesh nu oru paiayn kuda pesura puduchueruku ahhh  ni ava kita kekatha avala unkita solluralanu paru sonna ithuvarikum niya enkita solla nanum kekal.but enaku therium ni pesurathu mrng  night pogum pothu phone pesuarthu la unna pesah anu solura ethathula oru frienda hh eruken nenachenn but na apudi sonnathu ni enna oru second la tuki potaaa unna thoduren  chi nu solli thali vidura... aprm ni yaru first enna touch pantarthuku ketuta...na sonna thu thapu tan just casual ahh sonna promise ahh un character ahh thapa solli mean pannala ivalo day unkud erunthuerukun so enaku therum nanum epudi pakuren nu  but ni narya words vi2ta snega  ena thodurathuku ni yaru di sollatha  ..first na enn unkita enoda life la nadakurathu sollnum apudila naraya pesita..enimel unkita epudi erukanum mooo apudi tan erukanum...ella psangalaum matiri tan nium apudi la sollita..konja oru sec yosichu paru  starting unkit aevlo porumaya erunthuerukrn .evlo kovam  vanthalum control panni2 unkit akamichukamatan erunthen  oru 3 time en control umm miri kovampatueruken... 1000 soory snega en ignore panna aramichuta ..its okey  correct tan snega na romba unkita advantage eduthukiten..en mela tan full thapu enimel di solla meten unna touch pann maten ...  en character konjam bad tan but puducha person kaga etha vena siven ethavena mathipen ni sonnan nu tan nila kud aavlova pesurathu illa dp remove pannen .ehy means  nalla thuku tan sollven nu  💞– Ipadikku KP ,jandhu, (Sathish) ✍️',
              ),
            ),
          ),
        ),
      ),
    );
  }
}


