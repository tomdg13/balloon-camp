import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AppProvider>().login(_userCtrl.text.trim(), _passCtrl.text);
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const MainScreen()));
      }
    } catch (e) {
      setState(() => _error = 'ຊື່ຜູ້ໃຊ້ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 24),
              const Text('Balloon Camp',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('ລະບົບຮັບອໍເດີ',
                  style: TextStyle(color: Colors.white54, fontSize: 16)),
              const SizedBox(height: 48),

              // Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _userCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDeco('ຊື່ຜູ້ໃຊ້', Icons.person),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDeco('ລະຫັດຜ່ານ', Icons.lock).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white54),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Color(0xFFE94560))),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE94560),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('ເຂົ້າສູ່ລະບົບ',
                                style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
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

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE94560)),
        ),
      );
}
