import 'package:flutter/material.dart';
import 'websocket_service.dart';
import 'gioco_page.dart';
import 'dart:convert';

// classe che gestisce l'UI della pagina di waiting
class WaitingPage extends StatefulWidget {
  const WaitingPage({super.key});

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  final WebSocketService ws = WebSocketService();
  String status = 'In attesa di un avversario...';

  @override
  void initState() {
    super.initState();
    print('=== WAITING PAGE INIT ===');
    ws.connetti(onMessaggioRicevuto);
  }

  void onMessaggioRicevuto(String messaggio) {
    print('=== WAITING PAGE: Messaggio ricevuto ===');

    try {
      var data = jsonDecode(messaggio);

      print('Stato ricevuto: ${data['stato']}');
      print('MioTurno: ${data['mioTurno']}');

      if (data['stato'] == 'posizionamento') {
        if (mounted) {
          setState(() {
            status = 'Avversario trovato! Preparazione...';
          });
        }

        print('Invio messaggio PRONTO al server');
        ws.invia(jsonEncode({'azione': 'pronto'}));

      } else if (data['stato'] == 'inGioco') {
        print('=== PARTITA INIZIATA ===');
        print('Lunghezza grigliaPropria: ${data['grigliaPropria']?.length}');

        if (!mounted) {
          print('Widget non più montato, ignoro navigazione');
          return;
        }

        if (data['grigliaPropria'] == null) {
          print('ERRORE: grigliaPropria è null');
          return;
        }

        print('Navigazione a GamePage...');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GamePage(
              ws: ws,
              grigliaPropria: data['grigliaPropria'],
              mioTurno: data['mioTurno'] ?? false,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('=== ERRORE parsing JSON in WaitingPage ===');
      print('Errore: $e');
      print('StackTrace: $stackTrace');
    }
  }

  @override
  void dispose() {
    print('=== WAITING PAGE DISPOSE ===');
    // NON disconnettere! Il WebSocket viene passato a GamePage
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              status,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
