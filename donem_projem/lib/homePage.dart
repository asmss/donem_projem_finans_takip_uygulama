import 'package:donem_projem/ayarlar_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:donem_projem/analiz_rapor.dart';
import 'package:donem_projem/bütçe_yönetimi.dart';
import 'package:donem_projem/gelir_gider_ekle.dart';
import 'package:donem_projem/hatırlatmalar_planlamalar.dart';
import 'package:donem_projem/login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'canli_doviz_page.dart';
import 'filtreleme.dart';
import 'gelir_gider_liste.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.username});
  final String username;

  @override
  State<HomePage> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<HomePage> {
  int _seciliIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
String isim="";
  double toplamGelir = 0;
  double toplamGider = 0;
  double netBakiye =0;
  double toplambutce=0;
  double toplam=0;
String _username="";
  void initState() {
    super.initState();
    _finansalVeriCek();
    veri_dinle();
    GetIsim();
  }

  void veri_dinle()
  {    final kullanici = _auth.currentUser;
  if (kullanici == null) return;
  _firestore
    .collection("users")
    .doc(kullanici.uid)
     .collection("transactions")
     .snapshots()
  .listen((snapshots){
    _finansalVeriCek();
  });
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
  Future<void> _finansalVeriCek() async {
    final kullanici = _auth.currentUser;
    if (kullanici != null) {
      final gelirSnapshot = await _firestore
          .collection('users')
          .doc(kullanici.uid)
          .collection('transactions')
          .where('type', isEqualTo: 'income')
          .get();
     final butceSnapshot  = await _firestore
         .collection("users")
         .doc(kullanici.uid)
         .collection("budgets")
         .get();
      
      final giderSnapshot = await _firestore
          .collection('users')
          .doc(kullanici.uid)
          .collection('transactions')
          .where('type', isEqualTo: 'expense')
          .get();

      double toplamGelirVerisi = gelirSnapshot.docs.fold(0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
      double toplamGiderVerisi = giderSnapshot.docs.fold(0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
      double toplambutceverisi = butceSnapshot.docs.fold(0, (sum,doc) => sum + (doc['limit'] as num).toDouble());
      setState(() {
        toplamGelir = toplamGelirVerisi;
        toplamGider = toplamGiderVerisi;
        toplambutce = toplambutceverisi;
        toplam= (toplamGelir + toplambutce);
        netBakiye = toplamGelir + toplambutce - toplamGider;
      });
    }
  }
  void _itemSecildi(int index) {
    if (index == 0) {
      _finansalVeriCek();
    }
    setState(() {
      _seciliIndex = index;
    });
  }

  Widget _anaSayfa() {

    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme()
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bolumBasligi("Finansal Durum Özeti"),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _kart("Toplam Gelir", "$toplamGelir", Colors.green),
                    _kart("Toplam Gider", "$toplamGider", Colors.red),
                    _kart("Net Bakiye", "$netBakiye", Colors.blue),
                  ],
                ),
                const SizedBox(height: 30),
                _bolumBasligi("Bütçe Durumu"),
                const SizedBox(height: 16),
                _butceBilgisi("Bütçeniz: ₺${toplamGelir+toplambutce}\nKalan: ₺${toplamGelir +toplambutce - toplamGider}"),
                const SizedBox(height: 30),
                _bolumBasligi("Hızlı Eylemler"),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _hizliEylemButonu("Gelir Ekle", Icons.add, Colors.green, () {
                      _itemSecildi(2);
                    }),
                    _hizliEylemButonu("Gider Ekle", Icons.remove, Colors.red, () {
                      _itemSecildi(2);
                    }),
                    _hizliEylemButonu("Raporlar", Icons.bar_chart, Colors.blue, () {
                      _itemSecildi(1);
                    }),
                  ],
                ),

              ],
            ),
          ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title, style: GoogleFonts.montserrat(fontSize: 18)),
      onTap: () {
        _itemSecildi(index);
        Navigator.pop(context);
      },
    );
  }

  Widget _bolumBasligi(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    );
  }

  Widget _kart(String title, String amount, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 8),
              Text(amount, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _butceBilgisi(String info) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            info,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.blueGrey),
          ),
        ),
      ),
    );
  }

  Widget _hizliEylemButonu(String title, IconData icon, Color color, VoidCallback onPressed) {
    return Column(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: InkWell(
            onTap: onPressed,
            child: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 45,
              child: Icon(icon, size: 30, color: color),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final List<Widget> _sayfalar=[
      _anaSayfa(),
      const AnalizRaporlarPage(),
      const GelirGiderEklePage(),
      const ButceYonetimiPage(),
      const HatirlatmalarPage(),
      CanliDovizSayfasi(toplamButce: toplam,toplamHarcama: toplamGider,),
      GelirGiderPage(),
      FiltrelemePage(),
      const ayarlar_page(),

    ];

    return Scaffold(
      appBar: AppBar(
        title:  Text("", style: GoogleFonts.montserrat(color: Colors.white, fontSize: 24)),
        backgroundColor: Colors.lightBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.lightBlue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: 10),
                  Text("HOSGELDIN\n ${isim}",
                    style: GoogleFonts.montserrat(fontSize: 30,color: Colors.white),
                  ),
                ],
              ),
            ),
            _drawerItem(Icons.home, "Ana Sayfa", 0),
            _drawerItem(Icons.pie_chart, "Analiz & Raporlar", 1),
            _drawerItem(Icons.add_circle, "Gelir & Gider Ekle", 2),
            _drawerItem(Icons.flag, "Bütçe Yönetimi", 3),
            _drawerItem(Icons.notifications, "Hatırlatmalar & Planlama", 4),
            _drawerItem(Icons.insert_chart_outlined_sharp, "Canlı Döviz Takibi & Hesabı", 5),
            _drawerItem(Icons.list_alt, "Gelir Gider liste", 6),
            _drawerItem(Icons.filter_alt, "Filtreleme", 7),
            _drawerItem(Icons.settings, "Ayarlar", 8),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.blueGrey),
              title:  Text("Çıkış Yap", style: GoogleFonts.montserrat(fontSize: 18)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: _sayfalar[_seciliIndex],
    );
  }
}
