import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'homePage.dart';

class FiltrelemePage extends StatefulWidget {
  const FiltrelemePage({Key? key}) : super(key: key);

  @override
  State<FiltrelemePage> createState() => _FiltrelemePageState();
}

class _FiltrelemePageState extends State<FiltrelemePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }
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
          title: const Text('Filtreleme',style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.blueAccent,
          actions: [IconButton(onPressed: (){
            Navigator.push(context,MaterialPageRoute(builder: (context)=>HomePage(username: isim)));},
              icon: Icon(Icons.close))
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Başlangıç tarihi
                      Column(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 30),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _selectStartDate(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              backgroundColor: Colors.blueAccent.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              _startDate == null
                                  ? "Başlangıç Tarihi"
                                  : DateFormat('dd.MM.yyyy').format(_startDate!),
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 16),
                            ),
                          ),
                        ],
                      ),

                      // Bitiş tarihi
                      Column(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: Colors.redAccent, size: 30),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _startDate == null ? null : () => _selectEndDate(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              backgroundColor: _startDate == null
                                  ? Colors.grey.shade300
                                  : Colors.redAccent.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              _endDate == null
                                  ? "Bitiş Tarihi"
                                  : DateFormat('dd.MM.yyyy').format(_endDate!),
                              style: TextStyle(
                                color: _startDate == null ? Colors.grey : Colors.redAccent,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tarihler seçildiyse verileri listele
              if (_startDate != null && _endDate != null)
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection("users")
                        .doc(user.uid)
                        .collection("transactions")
                        .where("date", isGreaterThanOrEqualTo: _startDate!.toIso8601String())
                        .where("date", isLessThanOrEqualTo: _endDate!.toIso8601String())
                        .orderBy("date", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Center(child: Text("Bu tarih aralığında veri yok."));
                      }

                      // Toplam gelir ve gider hesapla
                      double totalIncome = 0;
                      double totalExpense = 0;

                      for (var doc in docs) {
                        if (doc['type'] == 'income') {
                          totalIncome += (doc['amount'] as num).toDouble();
                        } else {
                          totalExpense += (doc['amount'] as num).toDouble();
                        }
                      }

                      return Column(
                        children: [
                          // Toplam gelir gider kutuları
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSummaryCard(
                                  title: "Toplam Gelir",
                                  amount: totalIncome,
                                  color: Colors.green,
                                  icon: Icons.arrow_downward,
                                ),
                                _buildSummaryCard(
                                  title: "Toplam Gider",
                                  amount: totalExpense,
                                  color: Colors.red,
                                  icon: Icons.arrow_upward,
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: ListView.separated(
                              itemCount: docs.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final date = DateFormat('dd MMM yyyy').format(DateTime.parse(doc['date']));
                                final amount = doc['amount'];
                                final description = doc['description'];
                                final category = doc['category'];
                                final type = doc['type'];
                                final color = type == 'income' ? Colors.green : Colors.red;
                                final icon = type == 'income' ? Icons.arrow_downward : Icons.arrow_upward;

                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: color.withOpacity(0.2),
                                      child: Icon(icon, color: color),
                                    ),
                                    title: Text("$category - $amount₺",
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text("$description • $date"),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text("Lütfen tarih aralığını seçiniz.",
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 3,
      shadowColor: color.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        width: 150,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color.withOpacity(0.9))),
                  const SizedBox(height: 4),
                  Text("${amount.toStringAsFixed(2)}₺",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
