import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notification_helper.dart';
import 'homePage.dart';
import 'package:intl/intl.dart';
class HatirlatmalarPage extends StatefulWidget {
  const HatirlatmalarPage({super.key});

  @override
  State<HatirlatmalarPage> createState() => _HatirlatmalarSayfasiState();
}

class _HatirlatmalarSayfasiState extends State<HatirlatmalarPage> {
  final TextEditingController _aciklamaKontrol = TextEditingController();
  DateTime _seciliTarih = DateTime.now();
  TimeOfDay _seciliSaat = TimeOfDay.now();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String isim = "";
  List<Map<String, dynamic>> _hatirlatmalar = [];

  @override
  void initState() {
    super.initState();
    _hatirlatmalariGetir();
    GetIsim();
  }

  void bildirim_getir()async{


  }

  Future<void> GetIsim() async {
    final kullanici = _auth.currentUser;
    final name = await firestore.collection("users").doc(kullanici?.uid).get();
    setState(() {
      isim = name.get("name").toString();
    });
  }

  Future<void> _hatirlatmalariGetir() async {
    final kullanici = _auth.currentUser;
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(kullanici!.uid)
          .collection("reminders")
          .get();

      setState(() {
        _hatirlatmalar = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            "id": doc.id,
            "description": data['description'] as String? ?? 'Açıklama yok',
            "date": (data['date'] as Timestamp).toDate().toLocal(),
          };
        }).toList();
      });

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate().toLocal();

        if (date.isAfter(DateTime.now().toLocal())) {
          await NotificationHelper.scheduleNotification(
            title: 'Hatırlatma',
            body: data['description'] ?? 'Hatırlatma',
            scheduledDateTime: date,
          );
        }
      }
    } catch (e) {
      print('Hata: $e');
    }
  }

  Future<void> _yeniHatirlatmaDialogu(BuildContext context) async {
    // State resetleme
    _resetDialogState();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: _buildDialogTitle(),
              content: _buildDialogContent(setDialogState),
              actions: _buildDialogActions(context),
            );
          },
        );
      },
    );
  }

  void _resetDialogState() {
    _aciklamaKontrol.clear();
    _seciliTarih = DateTime.now();
    _seciliSaat = TimeOfDay.now();
  }

  Widget _buildDialogTitle() {
    return const Text(
      'Yeni Hatırlatma',
      style: TextStyle(
        color: Colors.blueAccent,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDialogContent(StateSetter setDialogState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDescriptionField(),
        const SizedBox(height: 16),
        _buildDateSelector(setDialogState),
        const SizedBox(height: 8),
        _buildTimeSelector(setDialogState),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _aciklamaKontrol,
      decoration: const InputDecoration(
        labelText: 'Açıklama',
        labelStyle: TextStyle(color: Colors.blueAccent),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
      maxLines: 2,
    );
  }

  Widget _buildDateSelector(StateSetter setDialogState) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 8),
        Text(
          DateFormat('dd/MM/yyyy').format(_seciliTarih),
          style: const TextStyle(color: Colors.blueAccent),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => _selectDate(context, setDialogState),
          child: const Text('Değiştir'),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(StateSetter setDialogState) {
    return Row(
      children: [
        const Icon(Icons.access_time, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 8),
        Text(
          _seciliSaat.format(context),
          style: const TextStyle(color: Colors.blueAccent),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => _selectTime(context, setDialogState),
          child: const Text('Değiştir'),
        ),
      ],
    );
  }

  List<Widget> _buildDialogActions(BuildContext context) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('İptal', style: TextStyle(color: Colors.red)),
      ),
      ElevatedButton(
        onPressed: () => _saveReminder(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
        ),
        child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
      ),
    ];
  }

  Future<void> _selectDate(BuildContext context, StateSetter setDialogState) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _seciliTarih,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _seciliTarih) {
      setDialogState(() => _seciliTarih = picked);
    }
  }

  Future<void> _selectTime(BuildContext context, StateSetter setDialogState) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _seciliSaat,
    );

    if (picked != null && picked != _seciliSaat) {
      setDialogState(() => _seciliSaat = picked);
    }
  }

  Future<void> _saveReminder(BuildContext context) async {
    if (_aciklamaKontrol.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir açıklama giriniz')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    final reminderDateTime = DateTime(
      _seciliTarih.year,
      _seciliTarih.month,
      _seciliTarih.day,
      _seciliSaat.hour,
      _seciliSaat.minute,
    );

    try {
      await firestore
          .collection("users")
          .doc(user.uid)
          .collection("reminders")
          .add({
        "description": _aciklamaKontrol.text,
        "date": reminderDateTime,
        "createdAt": FieldValue.serverTimestamp(),
      });

      await _hatirlatmalariGetir();
      Navigator.pop(context);

      // Bildirimi ayarla
      await NotificationHelper.scheduleNotification(
        title: 'Hatırlatma',
        body: _aciklamaKontrol.text,
        scheduledDateTime: reminderDateTime,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: ${e.toString()}')),
      );
    }
  }
  Future<void> _hatirlatmaSil(String docId) async {
    try {
      final kullanici = _auth.currentUser;
      await firestore.collection('users').doc(kullanici!.uid).collection("reminders").doc(docId).delete();
      await _hatirlatmalariGetir();
    } catch (e) {
      print('Silme hatası: $e');
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
          title: const Text('Hatırlatmalar & Planlama', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueAccent,
          elevation: 10,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage(username: isim)));
              },
              icon: Icon(Icons.close),
            )
          ],
          shadowColor: Colors.blueAccent.withOpacity(0.5),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () => _yeniHatirlatmaDialogu(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Yeni Hatırlatma Ekle', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 20),
              const Text('Hatırlatmalarınız',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _hatirlatmalar.length,
                  itemBuilder: (context, index) {
                    final hatirlatma = _hatirlatmalar[index];
                    final date = hatirlatma['date'] as DateTime;
                    final formattedDate =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(Icons.notifications, color: Colors.blueAccent),
                        title: Text(hatirlatma['description'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Tarih: $formattedDate',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _hatirlatmaSil(hatirlatma['id']);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _aciklamaKontrol.dispose();
    super.dispose();
  }
}