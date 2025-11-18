import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class DovizHesaplamaSayfasi extends StatefulWidget {
  @override
  _DovizHesaplamaSayfasiState createState() => _DovizHesaplamaSayfasiState();
}

class _DovizHesaplamaSayfasiState extends State<DovizHesaplamaSayfasi> {
  final TextEditingController _miktarController = TextEditingController();
  String _seciliDoviz = 'USD';
  double _sonuc = 0.0;
  Map<String, dynamic>? dovizKurlari;
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _dovizKurlariGetir();
  }

  Future<void> _dovizKurlariGetir() async {
    final apiKey = '80135d16d6f5ed107e4a2c49';
    final url = Uri.parse('https://v6.exchangerate-api.com/v6/$apiKey/latest/TRY');
    try {
      final yanit = await http.get(url);
      if (yanit.statusCode == 200) {
        final data = json.decode(yanit.body);
        setState(() {
          dovizKurlari = data['conversion_rates'];
          yukleniyor = false;
        });
      } else {
        throw Exception("Döviz verisi alınamadı.");
      }
    } catch (e) {
      print("Hata: $e");
      setState(() {
        yukleniyor = false;
      });
    }
  }

  void _hesapla() {
    final double miktar = double.tryParse(_miktarController.text) ?? 0.0;
    if (miktar > 0 && dovizKurlari != null) {
      setState(() {
        _sonuc = miktar * (1 / dovizKurlari![_seciliDoviz]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme(),
      ),
      home: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.lightBlue,
          title: const Text("Döviz Hesaplama", style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(onPressed: () {
              Navigator.pop(context);
            }, icon: Icon(Icons.close_fullscreen))
          ],
        ),
        body: yukleniyor
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _miktarController,
                decoration: const InputDecoration(
                  labelText: " Miktarı Girin",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: _seciliDoviz,
                onChanged: (String? newValue) {
                  setState(() {
                    _seciliDoviz = newValue!;
                  });
                },
                items: dovizKurlari!.keys.map<DropdownMenuItem<String>>((String key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _hesapla,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('HESAPLA', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 16),
              Text(
                "${_miktarController.text} $_seciliDoviz ${_sonuc.toStringAsFixed(2)}TL",
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
