import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'homePage.dart';
import 'sign_up.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _girisYap() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

// Giriş başarılıysa ana sayfaya yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(username: userCredential.user!.email ?? "Kullanıcı"),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Giriş başarısız. Lütfen bilgilerinizi kontrol edin.";
      if (e.code == 'user-not-found') {
        errorMessage = "Kullanıcı bulunamadı.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Yanlış şifre.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: ${e.toString()}")),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _sifresifirlama() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen email adresinizi girin.")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifre sıfırlama bağlantısı email adresinize gönderildi.")),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Şifre sıfırlama bağlantısı gönderilemedi.";
      if (e.code == 'user-not-found') {
        errorMessage = "Bu email adresiyle kayıtlı bir kullanıcı bulunamadı.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          textTheme: GoogleFonts.montserratTextTheme()
      ),
      home: Scaffold(
        backgroundColor: Colors.blue[50],
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 80, color: Colors.blueAccent),
                  const SizedBox(height: 20),
                  const Text(
                    "Giriş Yap",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // E-posta alanı
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.email, color: Colors.blueAccent),
                          hintText: "E-posta",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Şifre alanı
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.lock, color: Colors.blueAccent),
                          hintText: "Şifre",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Giriş butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _girisYap,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "GİRİŞ YAP",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Kayıt Ol butonu
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUp(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: const BorderSide(color: Colors.blueAccent),
                      ),
                      child: const Text(
                        "KAYIT OL",
                        style: TextStyle(fontSize: 18, color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                   // Şifremi Unuttum butonu
                  TextButton(
                    onPressed: _sifresifirlama,
                    child: const Text(
                      "Şifremi Unuttum",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
