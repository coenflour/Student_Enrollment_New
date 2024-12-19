import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'enrollment_menu.dart';
import 'login.dart';

class EnrollmentSummaryPage extends StatelessWidget {
  final List<Map<String, dynamic>> subjects;
  final int totalCredits;

  const EnrollmentSummaryPage(
      {super.key, required this.subjects, required this.totalCredits});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrollment Summary'),
        backgroundColor: const Color.fromARGB(255, 92, 114, 255),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.purple),
              child: Text(
                'Student Information System',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              title: const Text('Student Enrollment'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SelectSubjectPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Log Out'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Error loading user data'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Name: ${userData['name']}\nStudent ID: ${userData['studentId']}\nTotal Credits: $totalCredits',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Here is the list of all subjects you have chosen for this semester:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color:Colors.blue),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DataTable(
                    columnSpacing: 16.0,
                    columns: const [
                      DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Subject Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Credits', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: subjects
                        .asMap()
                        .entries
                        .map(
                          (entry) => DataRow(cells: [
                            DataCell(Text('${entry.key + 1}')), // Numbered index
                            DataCell(Text(entry.value['name'])),
                            DataCell(Text(entry.value['code'])),
                            DataCell(Text('${entry.value['credits']}')),
                          ]),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}