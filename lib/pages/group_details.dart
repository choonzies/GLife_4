import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glife/pages/user_details.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupDetails extends StatefulWidget {
  final String groupName;
  final String username;
  final VoidCallback onLeave;

  const GroupDetails(this.groupName, this.username, this.onLeave, {super.key});

  @override
  State<GroupDetails> createState() =>
      _GroupDetailsState(groupName, username, onLeave);
}

class _GroupDetailsState extends State<GroupDetails> {
  String groupName;
  String username;
  VoidCallback onLeave;

  _GroupDetailsState(this.groupName, this.username, this.onLeave);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<dynamic> members = [];
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _getUsername();
  }

  Future<void> _initializeData() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('groups').doc(groupName).get();
      if (userDoc.exists) {
        setState(() {
          members = userDoc.get('members') ?? [];
        });
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error retrieving document: $e');
    }
  }

  String getDescription() {
    return 'Let\'s get fit together! Join us!';
  }

  void _confirmLeaveGroup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure you want to leave $groupName?',
              style: TextStyle(fontSize: 20)),
          actions: <Widget>[
            TextButton(
              child: const Text('Leave'),
              onPressed: () {
                onLeave();
                _leaveGroup(groupName);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _leaveGroup(String groupName) async {
    DocumentSnapshot groupDoc =
        await _firestore.collection('groups').doc(groupName).get();
    List<dynamic> currentMembers = groupDoc.get('members');
    currentMembers.remove(username);
    await _firestore.collection('groups').doc(groupName).update({
      'members': currentMembers,
    });

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user!.uid).get();
    List<dynamic> currentGroups = userDoc.get('groups');
    currentGroups.remove(groupName);
    await _firestore.collection('users').doc(user!.uid).update({
      'groups': currentGroups,
    });
  }

  Future<void> _getUsername() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user!.uid).get();
        if (userDoc.exists) {
          setState(() {
            username = userDoc.get('username');
          });
        }
      } catch (e) {
        print('Error fetching username: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(groupName),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Colors.green, Colors.blue],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              Text(
                groupName,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                getDescription(),
                style: TextStyle(color: Colors.black54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 5,
                          color: Colors.black12,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Members',
                          style: TextStyle(
                              color: Color(0xFF101213),
                              fontSize: 24,
                              fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 16),
                        ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            String member = members[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            UserDetails(member)));
                              },
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                margin: EdgeInsets.only(bottom: 16),
                                child: ListTile(
                                  title: Text(
                                    member,
                                    style: TextStyle(
                                        color: Color(0xFF101213),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.exit_to_app),
        backgroundColor: Color.fromARGB(255, 204, 81, 72),
        onPressed: () {
          _confirmLeaveGroup(context);
        },
      ),
    );
  }
}
