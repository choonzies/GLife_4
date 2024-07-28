import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorePage extends StatefulWidget {
  final Function() onItemsPurchased;
  final Function() onCoinsChanged;

  StorePage({required this.onItemsPurchased, required this.onCoinsChanged});

  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  int coins = 0;
  List<String> ownedHelmets = [];
  List<String> ownedChestplates = [];
  List<String> ownedLeggings = [];
  List<String> ownedBoots = [];

  Map<String, List<Map<String, dynamic>>> _accessoryOptions = {
    'Helmets': [
      {'name': 'THE OG HELMET', 'image': 'assets/images/helmet.jpg'},
    ],
    'Chestplates': [
      {'name': 'THE OG CHESTPLATE', 'image': 'assets/images/testchest.jpg'},
    ],
    'Leggings': [],
    'Boots': [],
  };

  Map<String, int> _itemPrices = {
    'THE OG HELMET': 10,
    'Helmet 2': 30,
    'Helmet 3': 25,
    'THE OG CHESTPLATE': 50,
    'Chestplate 1': 35,
    'Chestplate 2': 40,
    'Leggings 1': 25,
    'Leggings 2': 30,
    'Boots 1': 15,
    'Boots 2': 20,
  };

  @override
  void initState() {
    super.initState();
    _loadCoins();
    _loadOwnedItems();
  }

  Future<void> _loadCoins() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      coins = prefs.getInt('coins') ?? 0;
    });
  }

  Future<void> _loadOwnedItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ownedHelmets = prefs.getStringList('ownedHelmets') ?? [];
      ownedChestplates = prefs.getStringList('ownedChestplates') ?? [];
      ownedLeggings = prefs.getStringList('ownedLeggings') ?? [];
      ownedBoots = prefs.getStringList('ownedBoots') ?? [];
    });
  }

  Future<void> _saveCoins(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', value);
  }

  Future<void> _saveOwnedItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ownedHelmets', ownedHelmets);
    await prefs.setStringList('ownedChestplates', ownedChestplates);
    await prefs.setStringList('ownedLeggings', ownedLeggings);
    await prefs.setStringList('ownedBoots', ownedBoots);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Store',
            style:
                TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 16),
            Text(
              'Coins: $coins',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Raleway'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildStore(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStore() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _accessoryOptions.keys.map((String category) {
        return ExpansionTile(
          title: Text(
            category,
            style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          children: _accessoryOptions[category]!
              .map((Map<String, dynamic> accessory) {
            String name = accessory['name'];
            String image = accessory['image'];
            int price = _itemPrices[name] ?? 0;
            bool alreadyOwned = _isItemOwned(category, name);

            return ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage(image),
              ),
              title: Text(
                name,
                style: TextStyle(fontFamily: 'Raleway', fontSize: 16),
              ),
              subtitle: Text(
                alreadyOwned ? 'Owned' : 'Price: $price coins',
                style: TextStyle(
                    fontFamily: 'Raleway',
                    color: alreadyOwned ? Colors.green : Colors.black),
              ),
              trailing: !alreadyOwned
                  ? TextButton(
                      onPressed: () {
                        if (coins >= price) {
                          setState(() {
                            _addOwnedItem(category, name);
                            coins -= price;
                            _saveOwnedItems();
                            _saveCoins(coins);
                            widget.onItemsPurchased();
                            widget.onCoinsChanged();
                          });
                        } else {
                          // Show dialog when coins are insufficient
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Insufficient Coins!"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text("OK"),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      child: Text(
                        'Buy for $price coins',
                        style: TextStyle(
                            color: Colors.green, fontFamily: 'Raleway'),
                      ),
                    )
                  : null,
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  bool _isItemOwned(String category, String name) {
    switch (category) {
      case 'Helmets':
        return ownedHelmets.contains(name);
      case 'Chestplates':
        return ownedChestplates.contains(name);
      case 'Leggings':
        return ownedLeggings.contains(name);
      case 'Boots':
        return ownedBoots.contains(name);
      default:
        return false;
    }
  }

  void _addOwnedItem(String category, String name) {
    switch (category) {
      case 'Helmets':
        ownedHelmets.add(name);
        break;
      case 'Chestplates':
        ownedChestplates.add(name);
        break;
      case 'Leggings':
        ownedLeggings.add(name);
        break;
      case 'Boots':
        ownedBoots.add(name);
        break;
    }
  }
}
