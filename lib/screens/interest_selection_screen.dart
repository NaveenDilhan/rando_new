import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InterestSelectionScreen extends StatefulWidget {
  final String userId;

  InterestSelectionScreen(this.userId);

  @override
  _InterestSelectionScreenState createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  List<String> interests = [];
  List<String> selectedInterests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInterests();
  }

  Future<void> _fetchInterests() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('categories').get();
      final fetchedInterests = snapshot.docs.map((doc) => doc['name'].toString()).toList();

      setState(() {
        interests = fetchedInterests;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching interests: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveInterests() async {
    await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
      'interestField': selectedInterests,
    });

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Interests')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Select your interests from the list below:'),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: interests.map((interest) {
                        return CheckboxListTile(
                          title: Text(interest),
                          value: selectedInterests.contains(interest),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedInterests.add(interest);
                              } else {
                                selectedInterests.remove(interest);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _saveInterests,
                    child: const Text('Save Interests'),
                  ),
                ],
              ),
            ),
    );
  }
}
