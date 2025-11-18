import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  Future<bool> kaydet() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Firestore'a kullanıcı bilgilerini kaydetme kısmı
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': nameController.text.trim(),
        'surname': surnameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
      });

      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Şifre çok zayıf. Daha güçlü bir şifre giriniz.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Bu e-posta adresi zaten kullanımda.';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz e-posta adresi.';
          break;
        default:
          errorMessage = 'Bir hata oluştu: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Beklenmeyen bir hata oluştu: $e')),
      );
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void kayit_basarili() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Kayıt başarılı! Giriş yapabilirsiniz.")),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 15),
                 Text(
                  "Kayıt Ol",
                  style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                _textfield_olustur(controller: nameController, hintText: "İsim", icon: Icons.person),
                const SizedBox(height: 15),

                _textfield_olustur(controller: surnameController, hintText: "Soyisim", icon: Icons.person_outline),
                const SizedBox(height: 15),

                _textfield_olustur(
                  controller: phoneController,
                  hintText: "500 000 00 00",
                  icon: Icons.phone,
                  inputType: TextInputType.number,
                  prefixText: "+90 ",
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 15),

                _textfield_olustur(
                    controller: emailController,
                    hintText: "E-posta",
                    icon: Icons.email,
                    inputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),

                _textfield_olustur(
                    controller: passwordController,
                    hintText: "Şifre",
                    icon: Icons.lock,
                    obscureText: true
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                      bool success = await kaydet();
                      if (success) {
                        kayit_basarili();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        :  Text(
                      "KAYIT OL",
                      style: GoogleFonts.montserrat(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child:  Text(
                      "GERİ ÇIK",
                      style: GoogleFonts.montserrat(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textfield_olustur({
    required TextEditingController controller,  //required zorunlu karakter
    required String hintText,
    required IconData icon,
    bool obscureText = false,  
    String? prefixText,
    TextInputType inputType = TextInputType.text, 
    List<TextInputFormatter>? inputFormatters, //sadece sayı girişi
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          style: GoogleFonts.montserrat(),
          controller: controller,
          keyboardType: inputType,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            icon: Icon(icon, color: Colors.blueAccent),
            hintText: hintText,
            prefixText: prefixText,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}