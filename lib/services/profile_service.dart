import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileService {
  Future<Map<String, dynamic>?> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data();
    }
    return null;
  }

  Future<File?> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    return picked != null ? File(picked.path) : null;
  }

  Future<String?> uploadImageToCloudinary(File image) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/dmajyc1zr/image/upload'); // Replace 'your_cloud_name'
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'flutter_preset' // Replace 'your_upload_preset'
        ..files.add(await http.MultipartFile.fromPath('file', image.path));
      
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseData);
        return jsonData['secure_url'];
      } else {
        throw Exception('Failed to upload image to Cloudinary');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    String? bio,
    required String address,
    required String birthdate,
    String? profileImageUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'bio': bio ?? '',
        'address': address,
        'birthdate': birthdate,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      });
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
      });
    }
  }
}