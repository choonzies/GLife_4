import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Friends extends StatefulWidget {
  Friends({Key? key}) : super(key: key);

  @override
  State<Friends> createState() => _FriendsState();
}

class _FriendsState extends State<Friends> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String? username;
  List<dynamic> friends = [];
  List<dynamic> filteredFriends = [];
  List<dynamic> friendReqs = [];
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getUsername();
    fetchFriends();
    fetchFriendReqs();
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
          filteredFriends.addAll(friends);
        });
      } else {
        print('Document does not exist for username: $username');
      }
    } catch (e) {
      print('Error retrieving friends: $e');
    }
  }

  Future<void> fetchFriendReqs() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          friendReqs = userDoc.get('friendReqs') ?? [];
        });
      } else {
        print('Document does not exist for username: $username');
      }
    } catch (e) {
      print('Error retrieving friend requests: $e');
    }
  }

  Future<void> deleteFieldListItem(
      String collection, String document, String field, String item) async {
    try {
      await _firestore.collection(collection).doc(document).update({
        field: FieldValue.arrayRemove([item]),
      });
      print('Item removed from ListField successfully');
    } catch (e) {
      print('Error removing item: $e');
    }
  }

  Future<void> addFieldListItem(
      String collection, String document, String field, String item) async {
    try {
      await _firestore.collection(collection).doc(document).update({
        field: FieldValue.arrayUnion([item]),
      });
      print('Item added to ListField successfully');
    } catch (e) {
      print('Error adding item: $e');
    }
  }

  void filterFriends(String query) {
    if (query.isNotEmpty) {
      List<String> temp = [];
      friends.forEach((friend) {
        if (friend.toLowerCase().contains(query.toLowerCase())) {
          temp.add(friend);
        }
      });
      setState(() {
        filteredFriends.clear();
        filteredFriends.addAll(temp);
      });
    } else {
      setState(() {
        filteredFriends.clear();
        filteredFriends.addAll(friends);
      });
    }
  }

  void showAddFriendDialog(BuildContext context) {
  TextEditingController textFieldController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Add Friend'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              TextField(
                controller: textFieldController,
                decoration: const InputDecoration(
                  hintText: 'Friend username',
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Add'),
            onPressed: () async {
              String friendUsername = textFieldController.text.trim();

              if (friendUsername.isNotEmpty) {
                // Check if already friends
                if (friends.contains(friendUsername)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Already friends!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                } else {
                  try {
                    DocumentSnapshot userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .get();

                    if (userDoc.exists) {
                      // Send friend request to the friend
                      await addFieldListItem(
                          'users', user!.uid, 'friendReqs', friendUsername);
                      Navigator.of(context).pop(); // Close the dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Friend request sent!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Username not found!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error adding friend request: $e');
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid username!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      );
    },
  );
}


  void showFriendRequestsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Friend Requests'),
        content: Container(
          width: double.minPositive,
          height: 300.0,
          child: ListView.builder(
            itemCount: friendReqs.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text(friendReqs[index]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () async {
                        String friendUsername = friendReqs[index];

                        // Add friend to your friends list
                        await addFieldListItem(
                          'users', user!.uid, 'friends', friendUsername);

                        // Add yourself to friend's friends list
                        DocumentSnapshot friendDoc = await _firestore
                            .collection('users')
                            .where('username', isEqualTo: friendUsername)
                            .get()
                            .then((querySnapshot) => querySnapshot.docs.first);

                        if (friendDoc.exists) {
                          await addFieldListItem(
                            'users', friendDoc.id, 'friends', username!);
                        } else {
                          print('Friend document not found');
                        }

                        // Remove friend request from your list
                        await deleteFieldListItem(
                          'users', user!.uid, 'friendReqs', friendUsername);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added $friendUsername as friend'),
                            duration: const Duration(seconds: 1),
                          ),
                        );

                        // Update local lists
                        setState(() {
                          friends.add(friendUsername);
                          filteredFriends.add(friendUsername);
                          friendReqs.remove(friendUsername);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        // Remove friend request
                        await deleteFieldListItem(
                          'users', user!.uid, 'friendReqs', friendReqs[index]);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Rejected ${friendReqs[index]}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );

                        // Update local list
                        setState(() {
                          friendReqs.remove(friendReqs[index]);
                        });
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
  ).then((_) {
    // After dialog is closed, trigger a rebuild of the friends list
    setState(() {});
  });
}


  Widget _buildFriendsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: filteredFriends.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(filteredFriends[index]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => filterFriends(value),
              decoration: InputDecoration(
                hintText: 'Search Friends',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          _buildFriendsList(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () {
              showAddFriendDialog(context);
            },
            label: const Text('Add Friend'),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(height: 16.0),
          FloatingActionButton.extended(
            onPressed: () {
              showFriendRequestsDialog(context);
            },
            label: const Text('Requests'),
            icon: const Icon(Icons.notifications),
          ),
        ],
      )
    );
  }
}
