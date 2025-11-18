import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> getGelirGiderVerileri() async {
  final snapshot = await FirebaseFirestore.instance.collection('users').get();
  return snapshot.docs.map((doc) => doc.data()).toList();
}
