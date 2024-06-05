import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glife/auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage = '';
  bool isLogin = true;
  bool isPasswordVisible = false;

  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  Future<void> signInWithEmailAndPassword() async {
    try {
      await Auth().signInWithEmailAndPassword(
        email: _controllerEmail.text, // Use username as email
        password: _controllerPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'invalid-email') {
          errorMessage = 'Please provide a valid username';
        } else {
          errorMessage = 'Incorrect Username or Password';
        }
      });
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    try {
      await Auth().createUserWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
      // Update user profile with username
      User? user = FirebaseAuth.instance.currentUser;
      await user?.updateProfile(displayName: _controllerUsername.text);
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'invalid-email') {
          errorMessage = 'Please provide a valid email';
        } else {
          errorMessage = e.message;
        }
      });
    }
  }

  Widget _title() {
    return const Text('GLife', style: TextStyle(color: Colors.green, fontSize: 28, fontWeight: FontWeight.bold));
  }

  Widget _logo() {
    return Image.asset('assets/images/logo.jpeg', height: 150);
  }

  Widget _entryField(String title, TextEditingController controller, bool isPassword) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      decoration: InputDecoration(
        labelText: title,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: Colors.green[50],
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                },
              )
            : null,
      ),
    );
  }

  Widget _errorMessage() {
    return Text(errorMessage == '' ? '' : errorMessage!, style: TextStyle(color: Colors.red));
  }

  Widget _submitButton() {
    return ElevatedButton(
      onPressed: isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword,
      child: Text(isLogin ? 'Login' : 'Register'),
    );
  }

  Widget _loginOrRegisterButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          isLogin = !isLogin;
          errorMessage = '';
        });
      },
      child: Text(isLogin ? 'Register instead' : 'Login instead'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _logo(),
              const SizedBox(height: 20),
              if (!isLogin) _entryField('Username', _controllerUsername, false),
              // if (!isLogin) const SizedBox(height: 20),
              if (isLogin) _entryField('Email', _controllerEmail, false),
              const SizedBox(height: 20),
              if (!isLogin) _entryField('Email', _controllerEmail, false),
              if (!isLogin) const SizedBox(height: 20),
              _entryField('Password', _controllerPassword, true),
              const SizedBox(height: 20),
              _errorMessage(),
              const SizedBox(height: 20),
              _submitButton(),
              const SizedBox(height: 10),
              _loginOrRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }
}
