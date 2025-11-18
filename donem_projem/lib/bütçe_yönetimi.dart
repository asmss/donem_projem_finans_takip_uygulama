import 'package:donem_projem/homePage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ButceYonetimiPage extends StatefulWidget {
  const ButceYonetimiPage({super.key});

  @override
  State<ButceYonetimiPage> createState() => _ButceYonetimiSayfasiState();
}

class _ButceYonetimiSayfasiState extends State<ButceYonetimiPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _butceController = TextEditingController();
  final TextEditingController _kategoriController = TextEditingController();
  String isim="";
  double _toplamButce = 0;
  double _toplamHarcama = 0;
  double kalan=0;
  double _toplamgelir=0;
  List<Map<String, dynamic>> _islemler = [];
  Map<String, double> _kategoriHarcamalari = {};

  @override
  void initState() {
    super.initState();
    veriOku();
    GetIsim();
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
  Future<void> veriOku() async {
    final user = _auth.currentUser;
    if (user != null) {
      final butceeSnapshot = await _firestore.collection('users').doc(user.uid).collection('budgets').get();
    final islemSnapshot = await _firestore.collection('users').doc(user.uid).collection('transactions').get();

    setState(() {
    _toplamButce = butceeSnapshot.docs.fold(0, (sum, doc) => sum + (doc['limit'] as num).toDouble());
    _toplamHarcama = islemSnapshot.docs
        .where((doc) => doc['type'] == 'expense')
        .fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());

    double toplamGelir = islemSnapshot.docs
        .where((doc) => doc['type'] == 'income')
        .fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble())+_toplamButce;
    _toplamgelir=toplamGelir-_toplamButce;
    _islemler = islemSnapshot.docs.map((doc) => doc.data()).toList();
    kalan=(_toplamButce+_toplamgelir) - _toplamHarcama;
    _kategoriHarcamalari = {};
    for (var islem in _islemler) {
    final kategori = islem['category'] ?? 'Diğer';
    final tutar = (islem['amount'] as num).toDouble();
    _kategoriHarcamalari[kategori] = (_kategoriHarcamalari[kategori] ?? 0) + tutar;
    }
    });
  }
  }

  Future<void> _butceEkle() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).collection('budgets').add({
        'category': _kategoriController.text,
        'limit': double.parse(_butceController.text),
        'spent': 0,
        'year':DateTime.now().year,
      });
      _butceController.clear();
      _kategoriController.clear();
      veriOku();
    }
  }

  void _butceEklemeDialogunuGoster(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Bütçe Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _kategoriController,
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              TextField(
                controller: _butceController,
                decoration: const InputDecoration(labelText: 'Bütçe Limiti'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                _butceEkle();
                Navigator.pop(context);
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
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
          title: const Text('Bütçe Yönetimi', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueAccent,
          elevation: 10,
          actions: [IconButton(onPressed: (){
            Navigator.push(context,MaterialPageRoute(builder: (context)=>HomePage(username: isim)));},
              icon: Icon(Icons.close))
          ],
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: RefreshIndicator(
          onRefresh: veriOku,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
              Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Toplam Bütçe', style: TextStyle(fontSize: 18, color: Colors.blueGrey)),
                    Text('₺$_toplamButce', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const Text('Toplam gelir', style: TextStyle(fontSize: 18, color: Colors.blueGrey)),
                    Text('₺$_toplamgelir', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 10),
                    const Text('Toplam Harcama', style: TextStyle(fontSize: 18, color: Colors.blueGrey)),
                    Text('₺$_toplamHarcama', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _toplamButce > 0 ? _toplamHarcama / _toplamButce : 0,
                      backgroundColor: Colors.grey[300],
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Kalan: ₺${kalan}',
                      style: const TextStyle(fontSize: 18, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () => _butceEklemeDialogunuGoster(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Bütçe Ekle', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(height: 20),
          const Text('Kategorilere Göre Harcamalar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: _kategoriHarcamalari.entries.map((entry) {
                final kategori = entry.key;
                final tutar = entry.value;
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.category, color: Colors.blueAccent),
                    title: Text(kategori, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    subtitle: Text('₺$tutar', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    trailing: const Icon(Icons.arrow_forward, color: Colors.blueGrey),
                  ),
                );
              }).toList(),
            ),
          ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}
