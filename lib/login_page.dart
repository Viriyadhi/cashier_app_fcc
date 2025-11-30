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
              width: 300,
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center, // Centers elements vertically within the Column (optional, but good practice)
                crossAxisAlignment:
                    CrossAxisAlignment
                        .center, // Centers elements horizontally within the Column
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      suffixIcon: Icon(Icons.clear),
                      labelText: 'ID',
                    ),
                  ),
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: Icon(Icons.clear),
                      labelText: 'Password',
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
