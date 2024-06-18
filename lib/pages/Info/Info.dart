import 'package:flutter/material.dart';

class Info extends StatelessWidget {
  const Info({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'My Health Information',
          style: TextStyle(
            fontFamily: 'Readex Pro',
            letterSpacing: 0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                'Timmy',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.black,
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Text(
                'DOB: 12 June 2002',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Color(0xFF57636C),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Divider(
              height: 32,
              thickness: 1,
              color: Color(0xFFE0E3E7),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Text(
                'Health Information',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Text(
                'Blood Type',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Text(
                'O+',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Color(0xFF57636C),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Text(
                'More Health information...',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}