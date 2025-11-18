import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'döviz_hesaplama.dart';
import 'homePage.dart';

class CanliDovizSayfasi extends StatefulWidget {
  final double toplamButce;
  final double toplamHarcama;

  const CanliDovizSayfasi({
    super.key,
    required this.toplamButce,
    required this.toplamHarcama,
  });

  @override
  State<CanliDovizSayfasi> createState() => _CanliDovizSayfasiState();
}

class _CanliDovizSayfasiState extends State<CanliDovizSayfasi> {
  Map<String, dynamic>? dovizKurlari;
  bool yukleniyor = true;
final FirebaseFirestore _firestore=FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;
String isim="";
  @override
  void initState() {
    super.initState();
    _dovizVerileriniGetir();
  }

  Future<void> _dovizVerileriniGetir() async {
    final apiKey = '80135d16d6f5ed107e4a2c49';
    final url = Uri.parse('https://v6.exchangerate-api.com/v6/$apiKey/latest/USD');

    try {
      final yanit = await http.get(url);
      if (yanit.statusCode == 200) {
        final data = json.decode(yanit.body);

        setState(() {
          dovizKurlari = data['conversion_rates'];
          yukleniyor = false;
        });
      } else {
        setState(() {
          yukleniyor = false;
        });
        throw Exception('Döviz verileri alınamadı.');
      }
    } catch (e) {
      setState(() {
        yukleniyor = false;
      });
      print('Hata: $e');
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
          backgroundColor: Colors.blueAccent,
          title: const Text("Canlı Döviz Kurları",style: TextStyle(color: Colors.white),),
          actions: [IconButton(onPressed: (){
            Navigator.push(context,MaterialPageRoute(builder: (context)=>HomePage(username: isim)));},
              icon: Icon(Icons.close))
          ],
        ),
        body: yukleniyor
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _kurTile("USD - Türk Lirası", dovizKurlari?['TRY']),
              _kurTile("USD - Euro", dovizKurlari?['EUR']),
              _kurTile("USD - GBP", dovizKurlari?['GBP']),
              _kurTile("USD - JPY", dovizKurlari?['JPY']),
              const Divider(height: 30, thickness: 1),
              _tabloDovizKurlari(),
              const SizedBox(height: 20),
              _butceHarcamaDovizTablosu(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DovizHesaplamaSayfasi()),
                  );
                },              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Döviz Hesabı Yap", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              SizedBox(height: 10,)
            ],
          ),
        ),
      ),
    );
  }

  Widget _kurTile(String baslik, dynamic kur) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        title: Text(baslik, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          kur != null ? kur.toStringAsFixed(2) : "N/A",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _tabloDovizKurlari() {
    if (dovizKurlari == null) {
      return const Center(child: Text("Döviz verileri alınamadı."));
    }

    double tryKur = dovizKurlari!['TRY'] ?? 1.0;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Türk Lirası'na Göre Döviz Kurları",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: Colors.grey.withOpacity(0.5)),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("DÖVİZ TÜRÜ", style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("USD", style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("TL", style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              _tabloSatir("Euro", 'EUR', tryKur),
              _tabloSatir("GBP (İngiliz Sterlini)", 'GBP', tryKur),
              _tabloSatir("JPY (Japon Yeni)", 'JPY', tryKur),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _tabloSatir(String kurAdi, String kurKodu, double tryKur) {
    final double kurDegeri = dovizKurlari?[kurKodu] ?? 1.0;
    final double tlDegeri = tryKur / kurDegeri;

    return TableRow(
      decoration: BoxDecoration(
        color: (dovizKurlari?.values.toList().indexOf(kurDegeri) ?? 0) % 2 == 0
            ? Colors.grey.withOpacity(0.1)
            : Colors.white,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(kurAdi, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(kurDegeri.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(tlDegeri.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _butceHarcamaDovizTablosu() {
    if (dovizKurlari == null) return const SizedBox();

    final Map<String, String> birimler = {
      'USD': 'Amerikan Doları',
      'EUR': 'Euro',
      'GBP': 'İngiliz Sterlini',
      'JPY': 'Japon Yeni',
    };

    final double usdToTry = dovizKurlari?['TRY']?.toDouble() ?? 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TL'ye Göre Verilerim",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: Colors.grey.withOpacity(0.5)),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                ),
                children: const [
                  Padding(padding: EdgeInsets.all(8), child: Text("DÖVİZ TÜRÜ", style: TextStyle(fontWeight: FontWeight.w500))),
                  Padding(padding: EdgeInsets.all(8), child: Text("Toplam Bütçe", style: TextStyle(fontWeight: FontWeight.w500))),
                  Padding(padding: EdgeInsets.all(8), child: Text("Toplam Harcama", style: TextStyle(fontWeight: FontWeight.w500))),
                  Padding(padding: EdgeInsets.all(8), child: Text("Gelir", style: TextStyle(fontWeight: FontWeight.w500))),
                ],
              ),
              ...birimler.entries.map((entry) {
                final double usdKur = (dovizKurlari?[entry.key] ?? 1.0).toDouble();

                final double butceUSD = widget.toplamButce / usdToTry;
                final double harcamaUSD = widget.toplamHarcama / usdToTry;
                final double gelirUSD = (widget.toplamButce - widget.toplamHarcama) / usdToTry;

                final double butceDoviz = butceUSD * usdKur;
                final double harcamaDoviz = harcamaUSD * usdKur;
                final double gelirDoviz = gelirUSD * usdKur;

                return TableRow(
                  decoration: BoxDecoration(
                    color: (birimler.entries.toList().indexOf(entry) % 2 == 0)
                        ? Colors.grey.withOpacity(0.1)
                        : Colors.white,
                  ),
                  children: [
                    Padding(padding: const EdgeInsets.all(8.0), child: Text(entry.value)),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text(butceDoviz.toStringAsFixed(2))),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text(harcamaDoviz.toStringAsFixed(2))),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text(gelirDoviz.toStringAsFixed(2))),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}
