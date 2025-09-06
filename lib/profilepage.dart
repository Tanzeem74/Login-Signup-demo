import 'package:flutter/material.dart';
import 'package:login_signup/auth/auth_service.dart';

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  final authservice = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentEmail = authservice.currentUserEmail();
    return Scaffold(body: Text(currentEmail.toString()));
  }
}
