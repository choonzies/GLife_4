import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User? _user;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _isUpdatingEmail = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _emailController.text = _user!.email ?? '';
  }

  Future<void> _changeEmail(String newEmail, String password) async {
    setState(() {
      _isUpdatingEmail = true;
    });

    try {
      // Step 1: Reauthenticate user with current password
      AuthCredential credential = EmailAuthProvider.credential(email: _user!.email!, password: password);
      await _user!.reauthenticateWithCredential(credential);

      // Step 2: Update email
      await _user!.updateEmail(newEmail);
      
      // Step 3: Clear email controller and set loading state to false
      setState(() {
        _emailController.text = newEmail;
        _isUpdatingEmail = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email updated successfully'),
        ),
      );
    } catch (error) {
      print('Error updating email: $error');
      setState(() {
        _isUpdatingEmail = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update email'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Email:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Enter your new email',
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Current Password:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter current password',
              ),
            ),
            SizedBox(height: 10),
            _isUpdatingEmail
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter both new email and current password'),
                          ),
                        );
                      } else {
                        _changeEmail(_emailController.text.trim(), _passwordController.text.trim());
                      }
                    },
                    child: Text('Change Email'),
                  ),
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _auth.signOut();
                },
                icon: Icon(Icons.logout),
                label: Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
