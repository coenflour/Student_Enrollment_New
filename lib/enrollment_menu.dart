import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'enrollment_summary.dart';

// Select Subject Page
class SelectSubjectPage extends StatefulWidget {
  const SelectSubjectPage({super.key});

  @override
  SelectSubjectPageState createState() => SelectSubjectPageState();
}

class SelectSubjectPageState extends State<SelectSubjectPage> {
  final CollectionReference _subjectsRef =
      FirebaseFirestore.instance.collection('subjects');
  final List<Map<String, dynamic>> _selectedSubjects = [];
  int _totalCredits = 0;
  final int _maxCredits = 24;

  Future<void> _saveSubjects() async {
    if (_totalCredits > _maxCredits) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credit limit exceeded')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'enrolledSubjects': _selectedSubjects,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrollment success!')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EnrollmentSummaryPage(
                  subjects: _selectedSubjects,
                  totalCredits: _totalCredits,
                )),
      );
    }
  }

  void _selectSubject(Map<String, dynamic> subject, String docId) {
    setState(() {
      if (_selectedSubjects.any((selected) => selected['docId'] == docId)) {
        // Remove the subject
        _selectedSubjects.removeWhere((selected) => selected['docId'] == docId);
        _totalCredits -= subject['credits'] as int;
      } else if (_totalCredits + subject['credits'] <= _maxCredits) {
        // Add the subject
        _selectedSubjects.add({...subject, 'docId': docId});
        _totalCredits += subject['credits'] as int;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot add ${subject['name']}! Max limit is $_maxCredits credits.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Subjects'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _subjectsRef.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading subjects'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No subjects available'));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final isSelected = _selectedSubjects.any((selected) => selected['docId'] == docId);

                    return ListTile(
                      tileColor: isSelected ? Colors.blue[100] : null,
                      title: Text(data['name']),
                      subtitle: Text('Credits: ${data['credits']}'),
                      trailing: ElevatedButton(
                        onPressed: () => _selectSubject(data, docId),
                        child: Text(isSelected ? 'Selected' : 'Select'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Text('Total Credits: $_totalCredits / $_maxCredits'),
          ElevatedButton(
            onPressed: _saveSubjects,
            child: const Text('Save and Continue'),
          ),
        ],
      ),
    );
  }
}