import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
                    child: const TextField(
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
                    child: const TextField(
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
                          onPressed: () {
                            // Handle login action
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 8.0,
                              left: 12.0,
                              right: 12.0,
                            ),
                            child: const Text(
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
