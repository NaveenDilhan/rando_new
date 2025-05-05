import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsultantPage extends StatelessWidget {
  const ConsultantPage({super.key});

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch $emailUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Career Consultation'),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('consultants').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No consultants found.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final consultants = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Meet Our Experts',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Schedule a session with a professional career advisor.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ...consultants.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  color: Colors.grey[850],
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundImage: NetworkImage(data['imageUrl']),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                data['title'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _launchEmail(data['email']),
                                    icon: const Icon(Icons.email),
                                    label: const Text('Contact'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BookingScreen(
                                            consultantName: data['name'],
                                            consultantId: doc.id,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.schedule),
                                    label: const Text('Schedule'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.tealAccent,
                                      side:
                                          const BorderSide(color: Colors.teal),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }).toList()
            ],
          );
        },
      ),
    );
  }
}

class BookingScreen extends StatelessWidget {
  final String consultantName;
  final String consultantId;

  const BookingScreen({
    super.key,
    required this.consultantName,
    required this.consultantId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Book $consultantName'),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          'Booking screen coming soon...',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
