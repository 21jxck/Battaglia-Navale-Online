import 'package:flutter/material.dart';
import 'waiting_page.dart';

//classe che gestisce l'ui della home page
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  //UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'BATTAGLIA NAVALE',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.directions_boat, size: 25),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WaitingPage()),
                );
              },
              child: const Text('Ricerca una partita'),
            ),
          ],
        ),
      ),
    );
  }
}
