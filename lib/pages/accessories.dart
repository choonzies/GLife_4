import 'package:flutter/material.dart';

class AccessoriesPage extends StatefulWidget {
  @override
  _AccessoriesPageState createState() => _AccessoriesPageState();
}

class _AccessoriesPageState extends State<AccessoriesPage> {
  String _selectedHat = ''; // Example: Track selected accessories
  String _selectedSword = '';
  String _selectedBreastplate = '';
  String _selectedBoots = '';
  String _selectedLeggings = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accessories'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Character image in the middle
            Container(
              width: 200,
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/character.png'), // Placeholder character image
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: 20),

            // List of accessories
            ListTile(
              leading: Icon(Icons.add_circle_outline), // Example icon for a hat
              title: Text('Hat'),
              subtitle: Text(_selectedHat.isNotEmpty ? 'Equipped: $_selectedHat' : 'Not equipped'),
              trailing: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedHat = 'Hat Name'; // Replace with logic to select hat
                  });
                },
                child: Text(_selectedHat.isNotEmpty ? 'Change' : 'Equip'),
              ),
            ),
            Divider(),

            ListTile(
              leading: Icon(Icons.add_circle_outline), // Example icon for a sword
              title: Text('Sword'),
              subtitle: Text(_selectedSword.isNotEmpty ? 'Equipped: $_selectedSword' : 'Not equipped'),
              trailing: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedSword = 'Sword Name'; // Replace with logic to select sword
                  });
                },
                child: Text(_selectedSword.isNotEmpty ? 'Change' : 'Equip'),
              ),
            ),
            Divider(),

            ListTile(
              leading: Icon(Icons.add_circle_outline), // Example icon for a breastplate
              title: Text('Breastplate'),
              subtitle:
                  Text(_selectedBreastplate.isNotEmpty ? 'Equipped: $_selectedBreastplate' : 'Not equipped'),
              trailing: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedBreastplate = 'Breastplate Name'; // Replace with logic to select breastplate
                  });
                },
                child: Text(_selectedBreastplate.isNotEmpty ? 'Change' : 'Equip'),
              ),
            ),
            Divider(),

            ListTile(
              leading: Icon(Icons.add_circle_outline), // Example icon for boots
              title: Text('Boots'),
              subtitle: Text(_selectedBoots.isNotEmpty ? 'Equipped: $_selectedBoots' : 'Not equipped'),
              trailing: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedBoots = 'Boots Name'; // Replace with logic to select boots
                  });
                },
                child: Text(_selectedBoots.isNotEmpty ? 'Change' : 'Equip'),
              ),
            ),
            Divider(),

            ListTile(
              leading: Icon(Icons.add_circle_outline), // Example icon for leggings
              title: Text('Leggings'),
              subtitle: Text(_selectedLeggings.isNotEmpty ? 'Equipped: $_selectedLeggings' : 'Not equipped'),
              trailing: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedLeggings = 'Leggings Name'; // Replace with logic to select leggings
                  });
                },
                child: Text(_selectedLeggings.isNotEmpty ? 'Change' : 'Equip'),
              ),
            ),
            Divider(),
          ],
        ),
      ),
    );
  }
}
