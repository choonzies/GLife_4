import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glife/pages/group_details.dart';

class Groups extends StatefulWidget {
  Groups({super.key});

  @override
  State<Groups> createState() => _GroupsState();
}

class _GroupsState extends State<Groups> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String username = '';
  String groupName = '';

  List<dynamic> friends = [];
  List<dynamic> selectedFriends = [];

  List<dynamic> groups = [];
  List<dynamic> filteredGroups = [];
  List<dynamic> groupReqs = [];
  User? user = FirebaseAuth.instance.currentUser;

  Future<String?> getUidByUsername(String username) async {
    String? uid;

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1) // Assuming there is only one user with the given username
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        uid = querySnapshot.docs.first.id; // Get the document ID (UID)
      }
    } catch (e) {
      print('Error getting UID by username: $e');
    }

    return uid;
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
        } else {
          print('User document does not exist');
        }
      } catch (e) {
        print('Error fetching username: $e');
      }
    } else {
      print('No user signed in');
    }
  }

  Future<void> fetchFriends() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          friends = userDoc.get('friends') ?? [];
        });
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error retrieving document: $e');
    }
  }

  Future<void> fetchGroups() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          groups = userDoc.get('groups') ?? [];
          filteredGroups.addAll(groups);
        });
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error retrieving document: $e');
    }
  }

  Future<void> fetchGroupReqs() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          groupReqs = userDoc.get('groupReqs') ?? [];
        });
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error retrieving document: $e');
    }
  }

  Future<void> deleteFieldListItem(
      String collection, String document, String field, String item) async {
    try {
       _firestore.collection(collection).doc(user!.uid).update({
        field: FieldValue.arrayRemove([item]),
      });
      print('Item removed from ListField successfully');
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> addFieldListItem(
      String collection, String document, String field, String item) async {
    try {
       _firestore.collection(collection).doc(document).update({
        field: FieldValue.arrayUnion([item]),
      });
      print('Item added to ListField successfully');
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
     _getUsername();
    fetchGroups();
    fetchGroupReqs();
    fetchFriends();
  }

  void _filterGroups(String query) {
    if (query.isNotEmpty) {
      List<String> temp = [];
      groups.forEach((group) {
        if (group.toLowerCase().contains(query.toLowerCase())) {
          temp.add(group);
        }
      });
      setState(() {
        filteredGroups.clear();
        filteredGroups.addAll(temp);
      });
    } else {
      setState(() {
        filteredGroups.clear();
        filteredGroups.addAll(groups);
      });
    }
  }

  void _showAddGroupDialog(BuildContext context) {
    selectedFriends = [];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Group'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    String friend = friends[index];
                    return CheckboxListTile(
                      title: Text(friend),
                      value: selectedFriends.contains(friend),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value!) {
                            selectedFriends.add(friend);
                          } else {
                            selectedFriends.remove(friend);
                          }
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Next'),
              onPressed: () {
                Navigator.of(context).pop();
                _getGroupName(context);
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

  void _getGroupName(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Enter Group Name'),
            content: TextField(
              onChanged: (value) {
                groupName = value;
              },
              decoration: InputDecoration(
                hintText: 'Group Name',
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Next'),
                onPressed: () {
                  Navigator.of(context).pop(groupName);
                  _showConfirmationDialog(context, groupName);
                },
              ),
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  void _showConfirmationDialog(BuildContext context, String groupName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Group Creation'),
          content: Text(
              'Are you sure you want to create $groupName with ${selectedFriends.length} friends?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                _createGroup(groupName);
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
    ).then((_) {
      setState(() {});
    });
  }

  void _createGroup(String groupName) async {
    for (String friend in selectedFriends) {
      String? uid = await getUidByUsername(friend);
       addFieldListItem('users', uid!, 'groupReqs', groupName);
    }
     _firestore.collection('groups').doc(groupName).set({
      'leader': username,
      'admin': [],
      'members': [username],
    });
     addFieldListItem('users', user!.uid, 'groups', groupName);
    setState(() {
      groups.add(groupName);
    });
  }

  void _showGroupRequestsDialog() {
    final scaffold = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Group Requests'),
              content: Container(
                width: double.minPositive,
                height: 300.0,
                child: ListView.builder(
                  itemCount: groupReqs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(groupReqs[index]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () async {

                              await addFieldListItem('users', user!.uid,
                                  'groups', groupReqs[index]);
                              await deleteFieldListItem('users', user!.uid,
                                  'groupReqs', groupReqs[index]);

                              await addFieldListItem('groups', groupReqs[index],
                                  'members', username);

                              setState(() {
                                groups.add(groupReqs[index]);
                                filteredGroups.add(groupReqs[index]);
                                groupReqs.removeAt(index);
                              });
                              scaffold.showSnackBar(
                                SnackBar(
                                  content: Text('Request accepted'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () async {

                              await deleteFieldListItem('users', user!.uid,
                                  'groupReqs', groupReqs[index]);

                              setState(() {
                                groupReqs.removeAt(index);
                              });
                              scaffold.showSnackBar(
                                SnackBar(
                                  content: Text('Request denied'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          String group = groups[index];
          return GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GroupDetails(group, username, () {
                              setState(() {
                                groups.remove(group);
                              });
                            })));
              },
              child: Container(
                  margin: EdgeInsets.fromLTRB(10, 5, 10, 5),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F4F8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    group,
                    style: TextStyle(
                      color: Color(0xFF101213),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  )));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Colors.green, Colors.blue],
            ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
              _showAddGroupDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showGroupRequestsDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                _filterGroups(value);
              },
              decoration: const InputDecoration(
                labelText: 'Search Groups',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          _buildGroupsList(),
        ],
      ),
    );
  }
}
