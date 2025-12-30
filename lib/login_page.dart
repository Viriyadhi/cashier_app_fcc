import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cashier_app/widget/admin_navigation.dart';
import 'package:cashier_app/cashier/cashier_page.dart';
import 'package:cashier_app/api/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final result = await AuthService.instance.login(
        name: _nameController.text.trim(),
        password: _passwordController.text,
      );

      if (!context.mounted) return;

      if (result == '1') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminNavigation()),
        );
      } else if (result == '0') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CashierPage()),
        );
      } else {
        setState(() {
          _errorText = 'Invalid username or password.';
        });
      }
    } catch (error) {
      setState(() {
        _errorText = 'Login failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.topLeft,
              child: SvgPicture.asset(
                'assets/Login.svg',
                width: 600,
                height: 600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(64.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LOGIN',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(
                    width: 400,
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      cursorColor: Color(0xFF778873),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person),
                        suffixIcon: Icon(Icons.clear),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF778873),
                            width: 2,
                          ),
                        ),
                        labelText: 'ID',
                        floatingLabelStyle: TextStyle(color: Color(0xFF778873)),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 400,
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      cursorColor: Color(0xFF778873),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: Icon(Icons.remove_red_eye_outlined),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF778873),
                            width: 2,
                          ),
                        ),
                        labelText: 'Password',
                        floatingLabelStyle: TextStyle(color: Color(0xFF778873)),
                      ),
                    ),
                  ),
                  if (_errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _errorText!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  SizedBox(
                    width: 400,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CE3A1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          onPressed: _isLoading ? null : () => _login(context),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 8.0,
                              left: 12.0,
                              right: 12.0,
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                    : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
