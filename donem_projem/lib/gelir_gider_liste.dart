import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'homePage.dart';

class GelirGiderPage extends StatefulWidget {

  GelirGiderPage({super.key});

  @override
  State<GelirGiderPage> createState() => _GelirGiderPageState();
}

class _GelirGiderPageState extends State<GelirGiderPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
String isim="";
  Future<void> GetIsim() async {
    final kullanici=_auth.currentUser;
    final name=await _firestore
        .collection("users")
        .doc(kullanici?.uid)
        .get();
    setState(() {
      isim=name.get("name").toString();
    });

  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text("Giriş yapılmamış."));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          textTheme: GoogleFonts.montserratTextTheme()
      ),
      home: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Gelir & Gider Listesi",style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.blueAccent,
          actions: [IconButton(onPressed: (){
            Navigator.push(context,MaterialPageRoute(builder: (context)=>HomePage(username: isim)));},
              icon: Icon(Icons.close))
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(

          stream: _firestore
              .collection("users")
              .doc(user.uid)
              .collection("transactions")
              .orderBy("date", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;

            Map<String, List<QueryDocumentSnapshot>> ayGrubu = {};

            for (var doc in docs) {
              final tarih = DateTime.parse(doc['date']);
              final ay = DateFormat.yMMM().format(tarih);
              if (!ayGrubu.containsKey(ay)) {
                ayGrubu[ay] = [];
              }
              ayGrubu[ay]!.add(doc);
            }

            return ListView(
              children: ayGrubu.entries.map((entry) {
                return ExpansionTile(
                  title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                  backgroundColor: Colors.black12,
                  children: entry.value.map((doc) {
                    final tutar = doc['amount'];
                    final aciklama = doc['description'];
                    final tur = doc['type'];
                    final kategori = doc['category'];
                    final tarih = DateFormat("dd MMM yyyy").format(DateTime.parse(doc['date']));
                    final renk = tur == "income" ? Colors.green : Colors.red;

                    return ListTile(
                      leading: Icon(tur == 'income' ? Icons.arrow_downward : Icons.arrow_upward, color: renk),
                      title: Text("$kategori - $tutar₺"),
                      subtitle: Text("$aciklama • $tarih"),
                    );
                  }).toList(),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
