import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        children: [
          Text("Satheesh Kumar", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Spacer(),
          TextButton(onPressed: () {}, child: Text("Home")),
          TextButton(onPressed: () {}, child: Text("Projects")),
          TextButton(onPressed: () {}, child: Text("Contact")),
          TextButton(
            onPressed: () {
              // Open your PDF resume
            },
            child: Text("Resume"),
          ),
        ],
      ),
    );
  }
}




// // main.dart
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:video_player/video_player.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:path_provider/path_provider.dart';

// void main() => runApp(BirthdayApp());

// class BirthdayApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Birthday Memories',
//       theme: ThemeData.dark(),
//       debugShowCheckedModeBanner: false,
//       home: MemoryHomePage(),
//     );
//   }
// }

// class MemoryHomePage extends StatefulWidget {
//   @override
//   _MemoryHomePageState createState() => _MemoryHomePageState();
// }

// class _MemoryHomePageState extends State<MemoryHomePage> with SingleTickerProviderStateMixin {
//   List<String> imagePaths = [];
//   List<String> videoPaths = [];

//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     loadMedia();
//   }

//   Future<void> loadMedia() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       imagePaths = prefs.getStringList('images') ?? [];
//       videoPaths = prefs.getStringList('videos') ?? [];
//     });
//   }

//   Future<void> saveMedia() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setStringList('images', imagePaths);
//     await prefs.setStringList('videos', videoPaths);
//   }

//   Future<void> pickImage() async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() {
//         imagePaths.add(picked.path);
//       });
//       saveMedia();
//     }
//   }

//   Future<void> pickVideo() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
//     if (result != null) {
//       setState(() {
//         videoPaths.add(result.files.single.path!);
//       });
//       saveMedia();
//     }
//   }

//   void deleteImage(int index) {
//     setState(() {
//       imagePaths.removeAt(index);
//     });
//     saveMedia();
//   }

//   void deleteVideo(int index) {
//     setState(() {
//       videoPaths.removeAt(index);
//     });
//     saveMedia();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text("Birthday Memories"),
//           bottom: TabBar(
//             controller: _tabController,
//             tabs: [
//               Tab(text: "Images"),
//               Tab(text: "Videos"),
//             ],
//           ),
//         ),
//         body: TabBarView(
//           controller: _tabController,
//           children: [
//             buildImageTab(),
//             buildVideoTab(),
//           ],
//         ),
//         floatingActionButton: FloatingActionButton.extended(
//           label: Text("Add Memory"),
//           icon: Icon(Icons.add),
//           onPressed: () {
//             showModalBottomSheet(
//               context: context,
//               builder: (context) => Wrap(
//                 children: [
//                   ListTile(
//                     leading: Icon(Icons.photo),
//                     title: Text("Pick Image"),
//                     onTap: () {
//                       Navigator.pop(context);
//                       pickImage();
//                     },
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.videocam),
//                     title: Text("Pick Video"),
//                     onTap: () {
//                       Navigator.pop(context);
//                       pickVideo();
//                     },
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget buildImageTab() {
//     return GridView.builder(
//       padding: EdgeInsets.all(10),
//       itemCount: imagePaths.length,
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         mainAxisSpacing: 10,
//         crossAxisSpacing: 10,
//       ),
//       itemBuilder: (context, index) => GestureDetector(
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => Scaffold(
//               appBar: AppBar(title: Text("View Image")),
//               body: Center(
//                 child: PhotoView(
//                   imageProvider: FileImage(File(imagePaths[index])),
//                 ),
//               ),
//             ),
//           ),
//         ),
//         onLongPress: () => deleteImage(index),
//         child: Image.file(File(imagePaths[index]), fit: BoxFit.cover),
//       ),
//     );
//   }

//   Widget buildVideoTab() {
//     return ListView.builder(
//       itemCount: videoPaths.length,
//       itemBuilder: (context, index) => ListTile(
//         leading: Icon(Icons.play_circle_fill),
//         title: Text("Video ${index + 1}"),
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => VideoPlayerScreen(videoPath: videoPaths[index]),
//           ),
//         ),
//         onLongPress: () => deleteVideo(index),
//       ),
//     );
//   }
// }

// class VideoPlayerScreen extends StatefulWidget {
//   final String videoPath;
//   VideoPlayerScreen({required this.videoPath});

//   @override
//   _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
// }

// class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
//   late VideoPlayerController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.file(File(widget.videoPath))
//       ..initialize().then((_) {
//         setState(() {});
//         _controller.play();
//       });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Play Video")),
//       body: Center(
//         child: _controller.value.isInitialized
//             ? AspectRatio(
//                 aspectRatio: _controller.value.aspectRatio,
//                 child: VideoPlayer(_controller),
//               )
//             : CircularProgressIndicator(),
//       ),
//     );
//   }
// }
