import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'groups.dart';
import 'package:glife/pages/user_details.dart';

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
     _getUsername();
    fetchFriends();
    fetchFriendReqs();
  }

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
          if (mounted) {
            setState(() {
              username = userDoc.get('username');
            });
          }

        } else {
          print('User document does not exist');
        }
      } catch (e) {
        print('Error fetching username from friends.dart: $e');
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
        if (mounted) {
          setState(() {
            friends = userDoc.get('friends') ?? [];
            filteredFriends.addAll(friends);
          });
        }
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

        if (mounted) {
          setState(() {
            friendReqs = userDoc.get('friendReqs') ?? [];
          });
        }

      } else {
        print('Document does not exist for username: $username');
      }
    } catch (e) {
      print('Error retrieving friend requests: $e');
    }
  }

  Future<void> deleteFieldListItem(String collection, String document, String field, String item) async {
    try {
       _firestore.collection(collection).doc(document).update({
        field: FieldValue.arrayRemove([item]),
      });
      print('Item removed from ListField successfully');
    } catch (e) {
      print('Error removing item: $e');
    }
  }

  Future<void> addFieldListItem(String collection, String document, String field, String item) async {
    try {
       _firestore.collection(collection).doc(document).update({
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
                      
                    String? name = await getUidByUsername(friendUsername);
                      if (name != null) {
                        // Send friend request to the friend
                          addFieldListItem(
                            'users', name, 'friendReqs', username!);
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


 void _showFriendRequestsDialog() {
    final scaffold = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                              // Firebase stuff - delete from friendReqs, add to Friends

                                // Add friend to your friends list
                          await addFieldListItem(
                              'users', user!.uid, 'friends', friendReqs[index]);


                          // Add yourself to friend's friends list
                          String? friendUID =
                              await getUidByUsername(friendReqs[index]);


                          if (friendUID != null) {
                            await addFieldListItem(
                                'users', friendUID, 'friends', username!);
                          }

                          // Remove friend request from your list
                          await deleteFieldListItem(
                              'users', user!.uid, 'friendReqs', friendReqs[index]);

                            
                              // Handle accept friend request
                              scaffold.showSnackBar(
                                SnackBar(
                                  content: Text('Added ${friendReqs[index]} as friend'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                              setState(() {
                                friends.add(friendReqs[index]);
                                filteredFriends.add(friendReqs[index]);
                                friendReqs.remove(friendReqs[index]);
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () async {
                              // Firebase stuff - delete from friendReqs
                              await deleteFieldListItem('users', user!.uid, 'friendReqs', friendReqs[index]);


                              // Handle reject friend request
                              scaffold.showSnackBar(
                                SnackBar(
                                  content: Text('Rejected ${friendReqs[index]}'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                              setState(() {
                                friendReqs.remove(friendReqs[index]);
                              });
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        // View user profile
                        print('Tapped on ${friendReqs[index]}');
                      },
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
          String member = filteredFriends[index]; // Get the friend's username

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserDetails(member)),
              );
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showAddFriendDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showFriendRequestsDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Groups()),
              );
            },
          ),
        ],
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
    );
  }
}
