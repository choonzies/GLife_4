import 'package:flutter/material.dart';
import 'package:glife/auth.dart';
import 'Info/Info.dart';
import 'Me/Me.dart';
import 'Social/Friends.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // this is to default the ME tab
  Future<void> signOut() async {
    await Auth().signOut();
  }

  List<Widget> _widgetOptions() {
    return <Widget>[
      Info(),
      Me(),
      Friends(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions().elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_sharp),
            label: 'Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.face),
            label: 'Me',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Socials',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: _onItemTapped,
      ),
    );
  }
}
