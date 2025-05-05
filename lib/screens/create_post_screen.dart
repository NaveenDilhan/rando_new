import 'dart:io';
import 'dart:convert'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http; 
import 'completed_achievements_screen.dart'; 

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
  // ignore: unused_field
  double _uploadProgress = 0.0;

 
  final String cloudinaryCloudName = 'dmajyc1zr'; 
  final String cloudinaryUploadPreset = 'flutter_preset'; 

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

 
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = cloudinaryUploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url'];
      } else {
        print('Cloudinary upload failed: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed.')),
        );
        return null;
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image. Please try again.')),
      );
      return null;
    }
  }

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
        imageUrl = await _uploadImageToCloudinary(_image!);
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 0, 163, 255),
                  Color.fromARGB(255, 0, 123, 200),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: const Text("Create Post"),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Create a New Post",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Post Title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: "What's happening?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
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
                      LinearProgressIndicator(),
                      SizedBox(height: 10),
                      Text("Uploading..."),
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