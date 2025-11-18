import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'homePage.dart';

class GelirGiderEklePage extends StatefulWidget {
  const GelirGiderEklePage({super.key});

  @override
  State<GelirGiderEklePage> createState() => _GelirGiderEkleSayfasiState();
}

class _GelirGiderEkleSayfasiState extends State<GelirGiderEklePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _tutarKontrol = TextEditingController();
  final TextEditingController _aciklamaKontrol = TextEditingController();
  String _seciliTip = 'Gelir';
  String _seciliKategori = 'Diğer';
String  isim="";
  final List<String> _kategoriler = ['Yemek', 'Ulaşım', 'Fatura', 'Eğlence', 'Diğer'];

  Future<void> _islemKaydet() async {
    final user = _auth.currentUser;
    if (user != null) {
      String type = _seciliTip == 'Gelir' ? 'income' : 'expense';

      await _firestore.collection('users').doc(user.uid).collection('transactions').add({
        'amount': double.parse(_tutarKontrol.text),
        'description': _aciklamaKontrol.text,
        'type': type,
        'category': _seciliKategori,
        'date': DateTime.now().toIso8601String(),
      });

      _tutarKontrol.clear();
      _aciklamaKontrol.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem başarıyla kaydedildi!')),
      );
    }
  }
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          textTheme: GoogleFonts.montserratTextTheme()
      ),
      home: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Gelir & Gider Ekle', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueAccent,
          elevation: 10,
          actions: [IconButton(onPressed: (){
            Navigator.push(context,MaterialPageRoute(builder: (context)=>HomePage(username: isim)));},
              icon: Icon(Icons.close))
          ],
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _tutarKontrol,
                decoration: InputDecoration(
                  labelText: 'Tutar',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _aciklamaKontrol,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _seciliTip,
                items: ['Gelir', 'Gider']
                    .map((label) => DropdownMenuItem<String>(
                  value: label,
                  child: Text(label),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _seciliTip = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Tür',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _seciliKategori,
                items: _kategoriler
                    .map((label) => DropdownMenuItem<String>(
                  value: label,
                  child: Text(label),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _seciliKategori = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _islemKaydet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
