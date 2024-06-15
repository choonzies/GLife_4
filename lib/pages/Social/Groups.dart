import 'package:flutter/material.dart';

class GroupsWidget extends StatefulWidget {
  const GroupsWidget({Key? key}) : super(key: key);

  @override
  State<GroupsWidget> createState() => _GroupsWidgetState();
}

class _GroupsWidgetState extends State<GroupsWidget> {
  late TextEditingController _textController;
  late FocusNode _textFieldFocusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _textFieldFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_textFieldFocusNode.canRequestFocus) {
          FocusScope.of(context).requestFocus(_textFieldFocusNode);
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'My Groups',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.swap_horiz_sharp),
              onPressed: () {
                Navigator.of(context).pushNamed('Friends');
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 4,
                      color: Color(0x33000000),
                      offset: Offset(0, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _textController,
                      focusNode: _textFieldFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Search users...',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          'https://via.placeholder.com/150',
                        ),
                      ),
                      title: Text('Group 1'),
                    ),
                    Divider(height: 1, color: Colors.grey),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          'https://via.placeholder.com/150',
                        ),
                      ),
                      title: Text('Group 2'),
                    ),
                    Divider(height: 1, color: Colors.grey),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          'https://via.placeholder.com/150',
                        ),
                      ),
                      title: Text('Group 3'),
                    ),
                    Divider(height: 1, color: Colors.grey),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          'https://via.placeholder.com/150',
                        ),
                      ),
                      title: Text('Group 4'),
                    ),
                    Divider(height: 1, color: Colors.grey),
                    TextButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.person_add_rounded),
                      label: Text('Add User'),
                    ),
                  ],
                ),
              ),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.home),
                  onPressed: () {
                    Navigator.of(context).pushNamed('HomePage');
                  },
                ),
                IconButton(
                  icon: Icon(Icons.groups_sharp),
                  onPressed: () {
                    print('Groups icon pressed');
                  },
                ),
                IconButton(
                  icon: Icon(Icons.library_books_sharp),
                  onPressed: () {
                    Navigator.of(context).pushNamed('Info');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
