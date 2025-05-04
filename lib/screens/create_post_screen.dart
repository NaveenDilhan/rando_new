import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'completed_achievements_screen.dart'; // Import the new screen

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Request permissions for gallery, camera, and storage
  Future<bool> _requestPermissions() async {
    PermissionStatus galleryAndStorageStatus = await Permission.storage.request();
    PermissionStatus cameraStatus = await Permission.camera.request();

    if (Platform.isAndroid && !(await Permission.manageExternalStorage.isGranted)) {
      await Permission.manageExternalStorage.request();
    }

    print('Storage (Gallery) Permission: ${galleryAndStorageStatus.isGranted ? "Granted" : "Denied"}');
    print('Camera Permission: ${cameraStatus.isGranted ? "Granted" : "Denied"}');
    if (Platform.isAndroid) {
      print('Manage External Storage Permission: ${await Permission.manageExternalStorage.isGranted ? "Granted" : "Denied"}');
    }

    if (galleryAndStorageStatus.isGranted && cameraStatus.isGranted) {
      return true;
    } else {
      String errorMessage = '';
      if (galleryAndStorageStatus.isDenied) errorMessage += 'Storage (Gallery) permission denied. ';
      if (cameraStatus.isDenied) errorMessage += 'Camera permission denied. ';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage.isEmpty ? 'Permissions denied.' : errorMessage),
      ));
      await openAppSettings();
      return false;
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permissions denied. Cannot pick image.')),
      );
      return;
    }

    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image selected successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No image selected.')),
        );
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image. Please try again.')),
      );
    }
  }

  // Upload image to Firebase Storage and get the URL
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('post_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageRef.putFile(imageFile);

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        setState(() {
          _uploadProgress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        });
      });

      final snapshot = await uploadTask.whenComplete(() {});
      final imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image. Please try again.')),
      );
      return null;
    }
  }

  // Create a new post
  Future<void> _createPost() async {
    final title = _titleController.text;
    final content = _contentController.text;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You need to be logged in to create a post.')),
      );
      return;
    }

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill out both fields.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await _uploadImage(_image!);
        print('Image uploaded, URL: $imageUrl');
      }

      final postData = {
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      };

      await FirebaseFirestore.instance.collection('posts').add(postData);
      print('Post created successfully');

      _titleController.clear();
      _contentController.clear();
      setState(() {
        _image = null;
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post created successfully!')),
      );
    } catch (e) {
      print("Error creating post: $e");
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Post"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Create a New Post", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Post Title"),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: "What's happening?"),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.image),
                  label: Text("Pick Image"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CompletedAchievementsScreen()),
                    );
                  },
                  icon: Icon(Icons.emoji_events),
                  label: Text("Achievements"),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_image != null)
              Image.file(_image!, height: 200, fit: BoxFit.cover),
            SizedBox(height: 20),
            _isUploading
                ? Column(
                    children: [
                      LinearProgressIndicator(value: _uploadProgress),
                      SizedBox(height: 10),
                      Text("${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded"),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _createPost,
                    child: Text("Create Post"),
                  ),
          ],
        ),
      ),
    );
  }
}