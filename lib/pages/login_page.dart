import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glife/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage = '';
  bool isLogin = true;
  bool isPasswordVisible = false;

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerUsername = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> checkFirstLogin(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      // Store user email and username
      await _firestore.collection('users').doc(userId).set({
        'email': _controllerEmail.text,
        'username': _controllerUsername.text,
        'friends': [],
        'friendReqs': [],
        "groups": [],
        "groupReqs": [],
      });
    }
  }

  Future<bool> isUsernameTaken(String username) async {
    QuerySnapshot result = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<void> signInWithEmailAndPassword() async {
    try {
      UserCredential userCredential = await Auth().signInWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
      await checkFirstLogin(userCredential.user!.uid);
      // Navigate to HomePage or any other page
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'invalid-email') {
          errorMessage = 'Please provide a valid email';
        } else {
          errorMessage = 'Incorrect Email or Password';
        }
      });
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    try {
      // Check if the username is taken
      bool usernameTaken = await isUsernameTaken(_controllerUsername.text);
      if (usernameTaken) {
        setState(() {
          errorMessage = 'Username is already taken';
        });
        return;
      }

      UserCredential userCredential =
          await Auth().createUserWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
      await checkFirstLogin(userCredential.user!.uid);
      // Navigate to HomePage or any other page
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
    return const Text('GLife',
        style: TextStyle(
            color: Colors.green, fontSize: 28, fontWeight: FontWeight.bold));
  }

  Widget _logo() {
    return Image.asset('assets/images/logo.jpeg', height: 150);
  }

  Widget _entryField(
      String title, TextEditingController controller, bool isPassword) {
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
                icon: Icon(isPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off),
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
    return Text(errorMessage == '' ? '' : errorMessage!,
        style: TextStyle(color: Colors.red));
  }

  Widget _submitButton() {
    return ElevatedButton(
      onPressed:
          isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword,
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
              _entryField('Email', _controllerEmail, false),
              const SizedBox(height: 20),
              _entryField('Password', _controllerPassword, true),
              const SizedBox(height: 20),
              if (!isLogin) _entryField('Username', _controllerUsername, false),
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
