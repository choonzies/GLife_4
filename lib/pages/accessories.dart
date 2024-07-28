import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';

class AccessoriesPage extends StatefulWidget {
  final Function(Map<String, String>) onUpdateCharacter;

  AccessoriesPage({required this.onUpdateCharacter});

  @override
  _AccessoriesPageState createState() => _AccessoriesPageState();
}

class _AccessoriesPageState extends State<AccessoriesPage> {
  String? _selectedHat;
  String? _selectedChest;
  String? _selectedLeggings;
  String? _selectedBoots;

  String _baseCharacterImage = 'assets/images/c2.jpg';

  Map<String, String> _accessoryImages = {
    'THE OG HELMET': 'assets/images/helmet.jpg',
    'THE OG CHESTPLATE': 'assets/images/testchest.jpg',
  };

  Map<String, List<String>> _accessoryOptions = {
    'Hat': ['None'],
    'Chest': ['None'],
    'Leggings': ['None'],
    'Boots': ['None'],
  };

  Map<String, int> _selectedIndices = {
    'Hat': 0,
    'Chest': 0,
    'Leggings': 0,
    'Boots': 0,
  };

  int coins = 100; // Example initial value

  @override
  void initState() {
    super.initState();
    _loadSelections();
    _loadCoins();
    _loadOwnedItems();
  }

  Future<void> _loadSelections() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedHat = prefs.getString('Hat');
      _selectedChest = prefs.getString('Chest');
      _selectedLeggings = prefs.getString('Leggings');
      _selectedBoots = prefs.getString('Boots');

      _selectedIndices['Hat'] =
          _accessoryOptions['Hat']!.indexOf(_selectedHat ?? 'None');
      _selectedIndices['Chest'] =
          _accessoryOptions['Chest']!.indexOf(_selectedChest ?? 'None');
      _selectedIndices['Leggings'] =
          _accessoryOptions['Leggings']!.indexOf(_selectedLeggings ?? 'None');
      _selectedIndices['Boots'] =
          _accessoryOptions['Boots']!.indexOf(_selectedBoots ?? 'None');
    });
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
      _accessoryOptions['Hat'] =
          ['None'] + (prefs.getStringList('ownedHelmets') ?? []);
      _accessoryOptions['Chest'] =
          ['None'] + (prefs.getStringList('ownedChestplates') ?? []);
      _accessoryOptions['Leggings'] =
          ['None'] + (prefs.getStringList('ownedLeggings') ?? []);
      _accessoryOptions['Boots'] =
          ['None'] + (prefs.getStringList('ownedBoots') ?? []);
    });
  }

  Future<void> _saveSelection(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Widget buildAccessoryCard(String title, String? selectedValue,
      List<String> options, ValueChanged<String?> onChanged, int initialIndex) {
    return Card(
      elevation: 5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.lightBlueAccent.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Text(
                '$title',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Raleway'),
              ),
              CarouselSlider(
                options: CarouselOptions(
                  height: 150,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                  initialPage: initialIndex,
                  onPageChanged: (index, reason) {
                    String selectedOption = options[index];
                    onChanged(selectedOption);
                  },
                ),
                items: options.map((String accessory) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 3,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: accessory != 'None'
                              ? Image.asset(
                                  _accessoryImages[accessory]!,
                                  fit: BoxFit.contain,
                                )
                              : Text(
                                  'None',
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.black,
                                      fontFamily: 'Raleway'),
                                ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              Text(
                selectedValue != null &&
                        selectedValue.isNotEmpty &&
                        selectedValue != 'None'
                    ? 'Equipped: $selectedValue'
                    : 'Not equipped',
                style: TextStyle(
                    fontSize: 14, color: Colors.black, fontFamily: 'Raleway'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accessories',
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
            Stack(
              children: [
                Image.asset(
                  _baseCharacterImage,
                  width: 200,
                  height: 300,
                  fit: BoxFit.contain,
                ),
                if (_selectedHat != null &&
                    _selectedHat != 'None' &&
                    _accessoryImages.containsKey(_selectedHat))
                  Positioned(
                    top: -40,
                    left: -50,
                    child: Image.asset(
                      _accessoryImages[_selectedHat]!,
                      width: 300,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (_selectedChest != null &&
                    _selectedChest != 'None' &&
                    _accessoryImages.containsKey(_selectedChest))
                  Positioned(
                    top: -40,
                    left: -50,
                    child: Image.asset(
                      _accessoryImages[_selectedChest]!,
                      width: 300,
                      height: 320,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (_selectedLeggings != null &&
                    _selectedLeggings != 'None' &&
                    _accessoryImages.containsKey(_selectedLeggings))
                  Positioned(
                    top: 190,
                    left: 50,
                    child: Image.asset(
                      _accessoryImages[_selectedLeggings]!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (_selectedBoots != null &&
                    _selectedBoots != 'None' &&
                    _accessoryImages.containsKey(_selectedBoots))
                  Positioned(
                    top: 280,
                    left: 50,
                    child: Image.asset(
                      _accessoryImages[_selectedBoots]!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
              ],
            ),
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
                  child: Column(
                    children: [
                      buildAccessoryCard(
                          'Hat', _selectedHat, _accessoryOptions['Hat']!,
                          (String? newValue) {
                        setState(() {
                          _selectedHat = newValue!;
                          _selectedIndices['Hat'] =
                              _accessoryOptions['Hat']!.indexOf(newValue);
                        });
                        _saveSelection('Hat', newValue!);
                        _updateCharacter();
                      }, _selectedIndices['Hat']!),
                      Divider(),
                      buildAccessoryCard(
                          'Chest', _selectedChest, _accessoryOptions['Chest']!,
                          (String? newValue) {
                        setState(() {
                          _selectedChest = newValue!;
                          _selectedIndices['Chest'] =
                              _accessoryOptions['Chest']!.indexOf(newValue);
                        });
                        _saveSelection('Chest', newValue!);
                        _updateCharacter();
                      }, _selectedIndices['Chest']!),
                      Divider(),
                      buildAccessoryCard('Leggings', _selectedLeggings,
                          _accessoryOptions['Leggings']!, (String? newValue) {
                        setState(() {
                          _selectedLeggings = newValue!;
                          _selectedIndices['Leggings'] =
                              _accessoryOptions['Leggings']!.indexOf(newValue);
                        });
                        _saveSelection('Leggings', newValue!);
                        _updateCharacter();
                      }, _selectedIndices['Leggings']!),
                      Divider(),
                      buildAccessoryCard(
                          'Boots', _selectedBoots, _accessoryOptions['Boots']!,
                          (String? newValue) {
                        setState(() {
                          _selectedBoots = newValue!;
                          _selectedIndices['Boots'] =
                              _accessoryOptions['Boots']!.indexOf(newValue);
                        });
                        _saveSelection('Boots', newValue!);
                        _updateCharacter();
                      }, _selectedIndices['Boots']!),
                      Divider(),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateCharacter() {
    widget.onUpdateCharacter({
      'Hat': _selectedHat != null &&
              _selectedHat!.isNotEmpty &&
              _selectedHat != 'None'
          ? _accessoryImages[_selectedHat!] ?? ''
          : '',
      'Chest': _selectedChest != null &&
              _selectedChest!.isNotEmpty &&
              _selectedChest != 'None'
          ? _accessoryImages[_selectedChest!] ?? ''
          : '',
      'Leggings': _selectedLeggings != null &&
              _selectedLeggings!.isNotEmpty &&
              _selectedLeggings != 'None'
          ? _accessoryImages[_selectedLeggings!] ?? ''
          : '',
      'Boots': _selectedBoots != null &&
              _selectedBoots!.isNotEmpty &&
              _selectedBoots != 'None'
          ? _accessoryImages[_selectedBoots!] ?? ''
          : '',
    });
  }
}
