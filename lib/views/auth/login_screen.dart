// lib/views/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/auth_repository.dart';
import '../../utils/validators.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;
  bool _remember = true;
  String? _error;

  late final AnimationController _anim;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repo = context.read<AuthRepository>();
    setState(() { _error = null; });

    if (!_formKey.currentState!.validate()) return;

    setState(() { _submitting = true; });

    // helper to produce friendly message from exceptions
    String _friendlyError(Object e) {
      final s = e.toString();
      if (s.startsWith('Exception: ')) return s.substring(11);
      return s;
    }

    try {
      // enforce timeout so UI never hangs forever
      final signInFuture = repo.signIn(_emailCtl.text.trim(), _passCtl.text);
      await signInFuture.timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Sign-in timed out. Check your device and try again.');
      });

      // If reached here, sign-in succeeded
      debugPrint('[login] signIn completed successfully for ${_emailCtl.text.trim()}');

      // Optional: you could navigate manually here, but AuthRepository notifies listeners so AppEntryPoint will react.
    } on Exception catch (e, st) {
      final msg = _friendlyError(e);
      debugPrint('[login] signIn error: $msg\n$st');
      if (mounted) setState(() { _error = msg; });
    } catch (e, st) {
      debugPrint('[login] Unknown signIn error: $e\n$st');
      if (mounted) setState(() { _error = 'Unexpected error. Try again.'; });
    } finally {
      if (mounted) setState(() { _submitting = false; });
    }
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ScaleTransition(
          scale: _logoScale,
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4B6EF6), Color(0xFF7C4DFF)]),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0,6))],
            ),
            child: const Center(child: Icon(Icons.gavel, color: Colors.white, size: 36)),
          ),
        ),
        const SizedBox(height: 14),
        Text('Welcome back', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('Sign in to continue — your private legal assistant', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildForm() {
    final theme = Theme.of(context);
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Email
              TextFormField(
                controller: _emailCtl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: Validators.email,
                autofillHints: const [AutofillHints.username, AutofillHints.email],
              ),
              const SizedBox(height: 12),
              // Password
              TextFormField(
                controller: _passCtl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v==null || v.isEmpty) ? 'Password required' : null,
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(value: _remember, onChanged: (v) => setState(() => _remember = v ?? true)),
                  const SizedBox(width: 6),
                  const Text('Remember me'),
                  const Spacer(),
                  TextButton(onPressed: () {
                    // TODO: implement forgot password flow
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Forgot password — demo')));
                  }, child: const Text('Forgot?')),
                ],
              ),
              if (_error != null) Padding(padding: const EdgeInsets.only(bottom:8.0), child: Text(_error!, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign in'),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or continue with', style: theme.textTheme.bodySmall),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialBtn(Icons.apple, 'Apple'),
                  const SizedBox(width: 12),
                  _socialBtn(Icons.g_mobiledata, 'Google'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialBtn(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label sign-in (demo)')));
      },
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // gradient bg
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFf6f8ff), Color(0xFFeef6ff), Color(0xFFFFFFFF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildForm(),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())), child: const Text('Create account'))
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
