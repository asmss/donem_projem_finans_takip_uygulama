import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'homePage.dart';

class AnalizRaporlarPage extends StatefulWidget {
  const AnalizRaporlarPage({super.key});

  @override
  State<AnalizRaporlarPage> createState() => _AnalizRaporlarPageState();
}

class _AnalizRaporlarPageState extends State<AnalizRaporlarPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double toplamGelir = 0;
  double toplamGider = 0;
  double toplamButce = 0;
  List<Map<String, dynamic>> tumIslemler = [];
  List<Map<String, dynamic>> butceListesi = [];
  String isim = "";

  int secilenYil = DateTime.now().year;

  List<String> aylar = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
  ];

  List<AylikVeri> aylikGelir = [];
  List<AylikVeri> aylikGider = [];

  Future<void> _verileriYukle() async {
    final kullanici = _auth.currentUser;
    if (kullanici != null) {
      final gelirler = await _firestore
          .collection('users')
          .doc(kullanici.uid)
          .collection('transactions')
          .where('type', isEqualTo: 'income')
          .get();

      final butceler = await _firestore
          .collection('users')
          .doc(kullanici.uid)
          .collection('budgets')
          .get();

      final giderler = await _firestore
          .collection('users')
          .doc(kullanici.uid)
          .collection('transactions')
          .where('type', isEqualTo: 'expense')
          .get();

      tumIslemler = [
        ...gelirler.docs.map((doc) => doc.data()),
        ...giderler.docs.map((doc) => doc.data()),
      ];

      butceListesi = butceler.docs.map((doc) => doc.data()).toList();

      // Toplamlar
      toplamGelir = gelirler.docs.fold(0, (toplam, doc) => toplam + (doc['amount'] as num).toDouble());
      toplamGider = giderler.docs.fold(0, (toplam, doc) => toplam + (doc['amount'] as num).toDouble());
      toplamButce = butceler.docs.fold(0, (toplam, doc) => toplam + (doc['limit'] as num).toDouble());

      _aylikVerileriHesapla(secilenYil, gelirler.docs, giderler.docs);

      setState(() {});
    }
  }

  void _aylikVerileriHesapla(int yil, List<QueryDocumentSnapshot> gelirler,
      List<QueryDocumentSnapshot> giderler) {

    aylikGelir = List.generate(12, (index) => AylikVeri(aylar[index], 0));
    aylikGider = List.generate(12, (index) => AylikVeri(aylar[index], 0));

    for (var doc in gelirler) {
      final tarih = DateTime.parse(doc['date']);
      if (tarih.year == yil) {
        aylikGelir[tarih.month - 1].deger += (doc['amount'] as num).toDouble();
      }
    }

    for (var doc in giderler) {
      final tarih = DateTime.parse(doc['date']);
      if (tarih.year == yil) {
        aylikGider[tarih.month - 1].deger += (doc['amount'] as num).toDouble();
      }
    }

  }

  Future<void> GetIsim() async {
    final kullanici = _auth.currentUser;
    final name = await _firestore.collection("users").doc(kullanici?.uid).get();
    setState(() {
      isim = name.get("name").toString();
    });
  }

  @override
  void initState() {
    super.initState();
    _verileriYukle();
    GetIsim();
  }

  List<GrafikVerisi> _pastaGrafikDatalari() {
    return [
      GrafikVerisi('Gelir', toplamGelir ),
      GrafikVerisi('Gider', toplamGider),
      if (toplamButce > 0) GrafikVerisi('Bütçe', toplamButce),
    ];
  }

  Future<void> _verileriYenidenYukle(int yil) async {
    final kullanici = _auth.currentUser;
    if (kullanici != null) {
      final gelirler = await _firestore
          .collection('users')
          .doc(kullanici.uid)
          .collection('transactions')
          .where('type', isEqualTo: 'income')
          .get();

      final giderler = await _firestore
          .collection('users')
          .doc(kullanici.uid)
          .collection('transactions')
          .where('type', isEqualTo: 'expense')
          .get();

      final butceler = await _firestore
          .collection('users')
          .doc(kullanici.uid)
          .collection('budgets')
          .get();

      setState(() {
        toplamGelir = gelirler.docs.fold(0, (toplam, doc) => toplam + (doc['amount'] as num).toDouble());
        toplamGider = giderler.docs.fold(0, (toplam, doc) => toplam + (doc['amount'] as num).toDouble());
        toplamButce = butceler.docs.fold(0, (toplam, doc) => toplam + (doc['limit'] as num).toDouble());

        _aylikVerileriHesapla(yil, gelirler.docs, giderler.docs);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(textTheme: GoogleFonts.montserratTextTheme()),
      home: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Analiz & Raporlar',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => HomePage(username: isim)));
              },
              icon: const Icon(Icons.close),
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Pasta Grafik
              SfCircularChart(
                title: ChartTitle(text: 'Gelir-Gider Dengesi'),
                legend: Legend(isVisible: true),
                series: <CircularSeries>[
                  PieSeries<GrafikVerisi, String>(
                    dataSource: _pastaGrafikDatalari(),
                    xValueMapper: (GrafikVerisi data, _) => data.isim,
                    yValueMapper: (GrafikVerisi data, _) => data.deger,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),

              // Yıl seçimi dropdown
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<int>(
                  value: secilenYil,
                  items: List.generate(20, (index) {
                    int yil = DateTime.now().year - 10 + index;
                    return DropdownMenuItem(
                      value: yil,
                      child: Text('$yil'),
                    );
                  }),
                  onChanged: (yil) async {
                    if (yil != null) {
                      setState(() {
                        secilenYil = yil;
                      });
                      await _verileriYenidenYukle(yil);
                    }
                  },
                  hint: const Text('Yıl Seçiniz'),
                ),
              ),

              // Çubuk Grafik
              SizedBox(
                height: 350,
                child: SfCartesianChart(
                  title: ChartTitle(text: '$secilenYil Yılı Gelir-Gider'),
                  legend: Legend(isVisible: true, position: LegendPosition.bottom),
                  primaryXAxis: CategoryAxis(),
                  primaryYAxis: NumericAxis(
                    labelFormat: '{value}₺',
                  ),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  series: <ChartSeries>[
                    ColumnSeries<AylikVeri, String>(
                      name: 'Gelir',
                      dataSource: aylikGelir,
                      xValueMapper: (data, _) => data.ay,
                      yValueMapper: (data, _) => data.deger,
                      color: Colors.green,
                      dataLabelSettings: const DataLabelSettings(isVisible: true),
                    ),
                    ColumnSeries<AylikVeri, String>(
                      name: 'Gider',
                      dataSource: aylikGider,
                      xValueMapper: (data, _) => data.ay,
                      yValueMapper: (data, _) => data.deger,
                      color: Colors.red,
                      dataLabelSettings: const DataLabelSettings(isVisible: true),
                    ),
                  ],
                ),
              ),

              // Bilgi kartları
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _bilgiKartiOlustur('Toplam Gelir', toplamGelir, Colors.green),
                    _bilgiKartiOlustur('Toplam Gider', toplamGider, Colors.red),
                    if (toplamButce > 0)
                      _bilgiKartiOlustur('Toplam Bütçe', toplamButce, Colors.blue),
                    _bilgiKartiOlustur(
                      'Net Bakiye',
                      toplamGelir + toplamButce - toplamGider,
                      (toplamGelir + toplamButce - toplamGider) >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bilgiKartiOlustur(String baslik, double miktar, Color renk) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(baslik, style: const TextStyle(fontSize: 16)),
            Text(
              '${miktar.toStringAsFixed(2)} ₺',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: renk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Grafik veri modeli
class GrafikVerisi {
  final String isim;
  final double deger;
  GrafikVerisi(this.isim, this.deger);
}

// Aylık veri modeli
class AylikVeri {
  final String ay;
  double deger;
  AylikVeri(this.ay, this.deger);
}
