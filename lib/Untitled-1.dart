




import 'dart:io';
import 'dart:ui';
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
void main()async {
  WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(
    
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child:      BirthdayApp(),
    ));
    
    
    

}
class BirthdayApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system, 
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.white,
     
        
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
    scaffoldBackgroundColor: Colors.white,
        cardColor: const Color.fromARGB(255, 255, 255, 255),
       
      ),
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
      CurvedAnimation(parent: _uploadAnimationController, curve: Curves.easeInOut),
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
      final storageRef = FirebaseStorage.instance.ref().child('birthday_images/$fileName');
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
      final storageRef = FirebaseStorage.instance.ref().child('birthday_images');
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
    final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
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
      final storageRef = FirebaseStorage.instance.ref().child('birthday_videos/$fileName');
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
      final storageRef = FirebaseStorage.instance.ref().child('birthday_videos');
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isImages 
                ? "Tap the + button to add your first image"
                : "Tap the + button to add your first video",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildImageCard(Map<String, String> image, int index) {
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
             
              if (isScratched)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              if (isScratched)
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
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => 
                    VideoPlayerScreen(videoUrl: video["url"]!),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.8),
                        Theme.of(context).primaryColor.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
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
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam, color: Colors.white, size: 14),
                        SizedBox(width: 4),
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
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                ),
              ),
            ),
          ),
          title: const Text(
            "Media Gallery",
            style: TextStyle(fontWeight: FontWeight.w600),
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
          child: SafeArea(
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
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1,                              ),
                                itemCount: _imageData.length,
                                itemBuilder: (context, index) {
                                  return AnimatedContainer(
                                    duration: Duration(milliseconds: 200 + (index * 50)),
                                    curve: Curves.easeOutBack,
                                    child: _buildImageCard(_imageData[index], index),
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
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1,                               ),
                                itemCount: _videoData.length,
                                itemBuilder: (context, index) {
                                  return AnimatedContainer(
                                    duration: Duration(milliseconds: 200 + (index * 50)),
                                    curve: Curves.easeOutBack,
                                    child: _buildVideoCard(_videoData[index], index),
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
        ),
        floatingActionButton: AnimatedBuilder(
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
                  }              },
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
  @override
  void initState() {
    super.initState();
        _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
        _controlsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controlsAnimationController, curve: Curves.easeInOut),
    );
        _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controlsAnimationController.forward();
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _hideControls();
          }
        });
      });
  }
  void _showControlsTemp() {
    setState(() => _showControls = true);
    _controlsAnimationController.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _hideControls();
      }
    });
  }
  void _hideControls() {
    setState(() => _showControls = false);
    _controlsAnimationController.reverse();
  }
  @override
  void dispose() {
    _controller.dispose();
    _controlsAnimationController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _showControls ? _hideControls : _showControlsTemp,
        child: Stack(
          children: [
            Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Loading...",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
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
                        if (_controller.value.isInitialized)
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
                                                if (_controller.value.isInitialized)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true,
                                  colors: VideoProgressColors(
                                    playedColor: Theme.of(context).primaryColor,
                                    bufferedColor: Colors.white.withOpacity(0.3),
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      _formatDuration(_controller.value.position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDuration(_controller.value.duration),
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
class ImageUploader extends StatefulWidget {
  const ImageUploader({Key? key}) : super(key: key);
  @override
  _ImageUploaderState createState() => _ImageUploaderState();
}
class _ImageUploaderState extends State<ImageUploader> {
  File? _imageFile;
  bool _isUploading = false;
  List<Map<String, String>> _imageData = []; // {url, path}
  @override
  void initState() {
    super.initState();
    _fetchAllImages();
  }
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }
  Future<void> _uploadImage() async {
    if (_imageFile == null) return;
    setState(() {
      _isUploading = true;
    });
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef =
          FirebaseStorage.instance.ref().child('birthday_images/$fileName');
      await storageRef.putFile(_imageFile!);
      await _fetchAllImages();
    } catch (e) {
      print('Error uploading image: $e');
    }
    setState(() {
      _isUploading = false;
    });
  }
  Future<void> _fetchAllImages() async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('birthday_images');
      final listResult = await storageRef.listAll();
      List<Map<String, String>> images = [];
      for (var item in listResult.items) {
        String url = await item.getDownloadURL();
        images.add({"url": url, "path": item.fullPath});
      }
      setState(() {
        _imageData = images.reversed.toList(); // latest first
      });
    } catch (e) {
      print('Error fetching images: $e');
    }
  }
  Future<void> _deleteImage(String path) async {
    try {
      await FirebaseStorage.instance.ref(path).delete();
      await _fetchAllImages();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
  void _confirmDelete(String path) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Image"),
        content: Text("Are you sure you want to delete this image?"),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete"),
            onPressed: () {
              Navigator.pop(context);
              _deleteImage(path);
            },
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Birthday Gallery"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchAllImages,
          )
        ],
      ),
      body: Column(
        children: [
          if (_isUploading) LinearProgressIndicator(),
          Expanded(
            child: _imageData.isEmpty
                ? Center(child: Text("No images uploaded"))
                : GridView.builder(
                    padding: EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _imageData.length,
                    itemBuilder: (context, index) {
                      final image = _imageData[index];
                      return GestureDetector(
                        onLongPress: () => _confirmDelete(image["path"]!),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                image["url"]!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => _confirmDelete(image["path"]!),
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.delete,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: Icon(Icons.add_a_photo),
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
                        MaterialPageRoute(
                          builder: (context) =>  HomeScreen(),
                        ),
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

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final List<String> quotes = [
    "You are the sunshine in my life! ☀️",
    "Every moment with you is a blessing 💝",
    "Your smile lights up my world 😊",
    "You make ordinary days extraordinary ✨",
    "Grateful for your amazing friendship 🙏",
    "You're one in a million! 🌟",
    "Your kindness inspires me daily 💖",
    "Life is better with you in it 🌈",
    "You bring joy wherever you go 🎊",
    "Thank you for being you! 🤗",
    "Your laughter is my favorite sound 😄",
    "You're incredibly special to me 💕",
    "Dreams come true because of friends like you 🌙",
    "You make everything more fun! 🎈",
    "Your friendship is my treasure 💎",
    "You have the most beautiful soul 👼",
    "Every day is brighter with you around 🌅",
    "You're absolutely amazing! 🌺",
    "Your heart is pure gold 💛",
    "You deserve all the happiness in the world 🌍",
    "You're my favorite person! 👑",
    "Happy 22nd Birthday, beautiful soul! 🎂"
  ];
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(  elevation: 0,
      title: Text("Happy BirthDay"),
      automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.living_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OurJourneyScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        color:  Colors.white,
               child: FadeTransition(
          opacity: _fadeAnimation,
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder(
                duration: Duration(milliseconds: 500 + (index * 100)),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, double value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Card(
                  color: Colors.white,
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                                        ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor:  Colors.white,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                          
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                   
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                quotes[index],
                                style: TextStyle(
                                  fontSize: 16,
                               
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MediaGallery()),
          );
        },
        child: Icon(Icons.photo_library),
      ),
    );
  }
}
class OurJourneyScreen extends StatelessWidget {
  const OurJourneyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(title: Text("Memeories"),),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
            // padding: const EdgeInsets.all(16.0),
            child: Text(
              _ourStory,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                fontFamily: 'Roboto',
              ),
            ),
          ),
      ),
    );
      }
}
const String _ourStory = '''
"That December Story..."
En life la first time entry anathu December month starting la, unna pathen... 😍Yellow color dress la iruntha. Apram oru 10 times night la Ambattur stop la pathu erundhen.Even en sight kuda adichu iruken 😅.Correct ahh December 24 evng, na bus stop la wait pannitu irundhappo, ni correct ahh vantha — green color dress, red color headset, one-side bag 😌.
Un friends kita pesitu iruka nerathula, avanga sonna:"Hey, unna antha ponnu pakudhu! Sirikuthu da!" 😆So nanum eti pathen... yaru nu paatha, athu nee.Aparam tan eye contact vanthuchu 👀.
Nanum 2 times pathen, sirichen... niyum smile pannaaa 😊Then, ni bus la erita 🚍.
Next day 25 leave, 26th morning la Chathiram bus stop la pathen —Blue color top, light blue jeans, loose hair 😍Same bag, one side la. Front la eruntha...
Na una pinnadi tan utkanthu erundhen.Ni enna pakkanum pakkanum nu na seat la straight ahh utkanthu irundhen 😐Ni ennapaaka vey illa 😔.Ambattur la erangum pothu pesanumnu try panen,Aana pathen, kandukama poita 😢.Evening la bus stop la wait pannitu irundhen.Ni vantha... eye contact again... smile 😊Aparam ni bus la erita 😔D70 la naan, 77 la neengaThirumangalam kitayile 77 pinnaadi tan vanthu irundhuchu 😅.Ni bus front la stand pannitu iruntha.CMBT enter aagum pothu, na erangiten...Aavai, police station side la fast ahh nadanthu vanthen 🏃‍♂️
Una paakanumnu thonichu, pathuten...
Niyum smile panitu "bye" sonna 👋😊Next day evening, ni orange color chudi la vantha.Yar kitayoo call la pesitu iruntha, serious ahh 😐Na unnai paathu, "Hey, edhachu problem ah?" nu keten.Ni sonna: "V2 la land problem" 🏡
Aparam un name keten,Therinju apdiye keten: "Appering?Summava keten.
Aparam D70 white board vanthu, periya bus erunthuchu, standing la irundhom 😩
Pesitu irundhom.Na keten: "Social media la illa ya?"Ni: "Illaye..."Na: "Eppadi contact pannanum?"Ni sirichaaa... 😊Apram seat kedachuchu...Ni: "Unna utkaranum."Na utkanthen 😇Un kooda bag keten, na vachukiten 🎒Aparam 2 perum namma pathi pesi pesi vandhom 😄Bus erangum pothu, ni ticket la number ezhuthi thandha 📝Na room ponathum text panniten 📲
Aparam daily evening on a tha ponom 💑Guindy varai naan vanthen...Jan la CMBT la room shift panniten...Aparam epoyachum ekkatutanga 😢Daily bus la pora antha konjam neram romba jolly ahh irukum 🚌💕Nila pathi share pannen...Unakku en mela kovam vanthuchu 😠Aparam apdiye poi irunthuchu...Apram naanum niyum chicken rice saapten 🍗🍚Ni en mela care panna mathiri feel aachu 💗Un kooda vara pothu happy ahh irukum 😄Vinin intro pannom 🎉
Aparam daily pola poi irundhuchu...Jan fulla apdiye poguthu...Feb starting la romba close aiten 🥰Un advice romba helpful...Nila vishyam la kutty fight la pottom 🤭Feb 3, first time un kaiya pudichen ✋❤️Enakku theriyala...Un kai pudicha pothu support maari feel aachu 🫂
Feb 21 — Nila birthday 🎂That day, en life la never marakamatten 🙏Mrng 10.30 ku ni en room vantha...Periods time vera 🙈Na: “Unna paka venam venam” sonnaNi convince pannitu vantha 🤗
Room la kiss keten 😘Ni "no" sonnathum door lock pannitten 🚪Apram mudincha mudinja sonna...
“Seri” nu bus stop ku ponomAnga bus illa...Enakku un mela kovam 😤Na tittu tittu irundhenAana ni porumaiya irundha 😔❤️
10.00 ku apram forum mall ponom 🛍️Next day movie ponom 🎬Antha movie enakku epovum special 🌟
Daily morning try pannitu irundhom...Apram PRL la oru periya fight vanthuchu 💔Na night 76 bus la irukumbothu...Kovam la unna vituten 😢Antha na panra periya thapu...Apram tan namakulla break aachu 💔Na pudikkama pona maathiri irunthaalum...Ni nalla avoid pannina...
Daily sanda... 😖Evening la 104 la poga arambichom 🚌Na avalo kenjinen...
Because enakku unna romba pudikum 💕Important person nee...So ego pakama kenjinen...Alauthen... 😭Un kitaye poi poi irunthuchu...One day, May month la, D k insta ID kandupidichen 🔍
Request kuduthen...Athuketathu full ahh odanjuten 💔En emotions control panna mudiyala
Un kai pidichen 🙏Un mela romba sorry... 😞Bus la kuda pesa try pannina,
Na pressure la irundhen 😣Un kitaye avlo kovam 😖Room ku vanthu aluthen 😭
Yar kitayum solla mudiyala...Unna miss panren nu theriyuthu...
Call pannitu pesuna,Ni romba pannina...Vini kuda senthu...Aparam ni D ah pakurathu enaku romba hurt aachu 💔Apo tan purinjudhu...Ni thapu pannala...Na dhan thapu pannen...Karma enaku venumnu nenachen...Romba hurt aachu...Unna yarukum vitu kuduka maten 😭Un life la amma, appa, tambi, akka, apram na dhan erukenApdiyea iruppen...
Because:You are my caretaker, my soul, my comfort zone, my happy place. 💞💫
''';
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
  const CardPlanet({
    required this.data,
    Key? key,
  }) : super(key: key);

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
                  style: TextStyle(
                    color: data.subtitleColor,
                    fontSize: 14,
                  ),
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

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter something";
    }
    if (value != "sathish@254595") {
      return "Value must be 'sathish@254595'";
    }
    return null;
  }

  bool checkAndNavigate(BuildContext context) {
    if (nameController.text == "sathish@254595") {
      return true; // ✅ Means success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect value—it must be '@'")),
      );
      return false;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}







