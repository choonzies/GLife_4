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
    'Hat 1': 'assets/images/helmet.jpg',
    'Chest 1': 'assets/images/testchest.jpg',
    'Leggings 1': 'assets/images/leggings1.jpg',
    'Boots 1': 'assets/images/boots1.jpg',
  };

  Map<String, List<String>> _accessoryOptions = {
    'Hat': ['None', 'Hat 1'],
    'Chest': ['None', 'Chest 1'],
    'Leggings': ['None', 'Leggings 1'],
    'Boots': ['None', 'Boots 1'],
  };

  @override
  void initState() {
    super.initState();
    _loadSelections();
  }

  Future<void> _loadSelections() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedHat = _validateSelection(prefs.getString('Hat'), 'Hat');
      _selectedChest = _validateSelection(prefs.getString('Chest'), 'Chest');
      _selectedLeggings = _validateSelection(prefs.getString('Leggings'), 'Leggings');
      _selectedBoots = _validateSelection(prefs.getString('Boots'), 'Boots');
    });
  }

  String? _validateSelection(String? selection, String type) {
    if (selection != null && _accessoryOptions[type]?.contains(selection) == true) {
      return selection;
    } else {
      return 'None';
    }
  }

  Future<void> _saveSelection(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
       title: Text('Accessories'),
      backgroundColor: Colors.green,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Colors.green, Colors.blue],
          )
      ))),
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
            Stack(
              children: [
                Image.asset(
                  _baseCharacterImage,
                  width: 200,
                  height: 300,
                  fit: BoxFit.contain,
                ),
                if (_selectedHat != null && _selectedHat != 'None' && _accessoryImages.containsKey(_selectedHat))
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
                if (_selectedChest != null && _selectedChest != 'None' && _accessoryImages.containsKey(_selectedChest))
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
                if (_selectedLeggings != null && _selectedLeggings != 'None' && _accessoryImages.containsKey(_selectedLeggings))
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
                if (_selectedBoots != null && _selectedBoots != 'None' && _accessoryImages.containsKey(_selectedBoots))
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
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      buildAccessoryCard('Hat', _selectedHat, _accessoryOptions['Hat']!, (String? newValue) {
                        setState(() {
                          _selectedHat = newValue!;
                        });
                        _saveSelection('Hat', newValue!);
                        _updateCharacter();
                      }),
                      Divider(),
                      buildAccessoryCard('Chest', _selectedChest, _accessoryOptions['Chest']!, (String? newValue) {
                        setState(() {
                          _selectedChest = newValue!;
                        });
                        _saveSelection('Chest', newValue!);
                        _updateCharacter();
                      }),
                      Divider(),
                      buildAccessoryCard('Leggings', _selectedLeggings, _accessoryOptions['Leggings']!, (String? newValue) {
                        setState(() {
                          _selectedLeggings = newValue!;
                        });
                        _saveSelection('Leggings', newValue!);
                        _updateCharacter();
                      }),
                      Divider(),
                      buildAccessoryCard('Boots', _selectedBoots, _accessoryOptions['Boots']!, (String? newValue) {
                        setState(() {
                          _selectedBoots = newValue!;
                        });
                        _saveSelection('Boots', newValue!);
                        _updateCharacter();
                      }),
                      Divider(),
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

  Widget buildAccessoryCard(String title, String? selectedValue, List<String> options, ValueChanged<String?> onChanged) {
    return Card(
      elevation: 5,
      color: const Color.fromARGB(137, 255, 255, 255),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Text(
                '$title',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              CarouselSlider(
                options: CarouselOptions(
                  height: 150,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
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
                          color: Color.fromARGB(221, 255, 255, 255),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: accessory != 'None'
                              ? Image.asset(
                                  _accessoryImages[accessory]!,
                                  fit: BoxFit.contain,
                                )
                              : Text(
                                  'None',
                                  style: TextStyle(fontSize: 16.0, color: Colors.white),
                                ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              Text(
                selectedValue != null && selectedValue.isNotEmpty && selectedValue != 'None'
                    ? 'Equipped: $selectedValue'
                    : 'Not equipped',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateCharacter() {
    widget.onUpdateCharacter({
      'Hat': _selectedHat != null && _selectedHat!.isNotEmpty && _selectedHat != 'None'
          ? _accessoryImages[_selectedHat!] ?? ''
          : '',
      'Chest': _selectedChest != null && _selectedChest!.isNotEmpty && _selectedChest != 'None'
          ? _accessoryImages[_selectedChest!] ?? ''
          : '',
      'Leggings': _selectedLeggings != null && _selectedLeggings!.isNotEmpty && _selectedLeggings != 'None'
          ? _accessoryImages[_selectedLeggings!] ?? ''
          : '',
      'Boots': _selectedBoots != null && _selectedBoots!.isNotEmpty && _selectedBoots != 'None'
          ? _accessoryImages[_selectedBoots!] ?? ''
          : '',
    });
  }
}
