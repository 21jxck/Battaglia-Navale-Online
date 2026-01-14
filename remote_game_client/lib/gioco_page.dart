import 'package:flutter/material.dart';
import 'websocket_service.dart';
import 'dart:convert';

// classe per la ui del gioco
class GamePage extends StatefulWidget {
  final WebSocketService ws;
  final List<dynamic> grigliaPropria;
  final bool mioTurno;

  const GamePage({
    super.key,
    required this.ws,
    required this.grigliaPropria,
    required this.mioTurno,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const int dimensione = 10;

  late List<List<bool>> _mieNavi;
  late List<List<bool>> _mieNaviColpite;
  late List<List<bool>> _nemicoTiri;
  late bool _mioTurno;
  bool _partitaFinita = false;
  String? _vincitore;

  @override
  void initState() {
    super.initState();
    print('=== GAME PAGE INIT ===');

    _inizializzaGriglie();
    _mioTurno = widget.mioTurno;
    widget.ws.aggiornaCallback(_onMessaggioRicevuto);
  }

  void _inizializzaGriglie() {
    // inizializza la griglia con le mie navi
    _mieNavi = List.generate(
        dimensione,
        (x) => List.generate(
            dimensione,
            (y) => widget.grigliaPropria[x][y]['haNave'] ?? false,
        ),
    );

    // 0 navi colpite
    _mieNaviColpite = List.generate(
        dimensione,
        (_) => List.generate(dimensione, (_) => false),
    );

    // 0 colpi ai nemici
    _nemicoTiri = List.generate(
        dimensione,
        (_) => List.generate(dimensione, (_) => false),
    );
  }

  // metodo gestione messaggi server
  void _onMessaggioRicevuto(String messaggio) {
    if(!mounted) return;

    try {
      final data = jsonDecode(messaggio) as Map<String, dynamic>;
      final stato = data['stato'] as String?;

      print('Stato: $stato, MioTurno: ${data['mioTurno']}');

      if (stato == 'inGioco') {
        _aggiornaStatoPartita(data);
      } else if (stato == 'finita') {
        _terminaPartita(data);
      }
    } catch (e, stackTrace) {
      print('ERRORE parsing JSON: $e\n$stackTrace');
    }
  }

  // aggiorna lo stato partita corrente
  void _aggiornaStatoPartita(Map<String, dynamic> data) {
    setState(() {
      _mioTurno = data['mioTurno'] as bool? ?? false;
      _aggiornaGriglie(data);
    });

    // notifica di affondamento nave
    final naveAffondata = data['naveAffondata'] as Map<String, dynamic>?;
    if (naveAffondata != null) {
      _mostraNotificaAffondamento(
        naveAffondata['nome'] as String,
        naveAffondata['lunghezza'] as int,
      );
    }
  }

  void _aggiornaGriglie(Map<String, dynamic> data) {
    final grigliaPropria = data['grigliaPropria'] as List;
    final grigliaNemica = data['grigliaNemica'] as List;

    for (int x = 0; x < dimensione; x++) {
      for (int y = 0; y < dimensione; y++) {
        _mieNavi[x][y] = grigliaPropria[x][y]['haNave'] as bool? ?? false;
        _mieNaviColpite[x][y] = grigliaPropria[x][y]['colpita'] as bool? ?? false;
        _nemicoTiri[x][y] = grigliaNemica[x][y]['colpita'] as bool? ?? false;
      }
    }
  }

  // termina la partita e mostra il risultato
  void _terminaPartita(Map<String, dynamic> data) {
    print('=== PARTITA FINITA ===');

    setState(() {
      _partitaFinita = true;
      _vincitore = data['vincitore'] as String?;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _mostraDialogoFine();
    });
  }

  // viene visualizzato quando si affonda una nave nemica
  void _mostraNotificaAffondamento(String nomeNave, int lunghezza) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.whatshot, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'Hai affondato: $nomeNave ($lunghezza)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // dialog fine partita
  void _mostraDialogoFine() {
    final hoVinto = _vincitore == 'io';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: hoVinto ? Colors.green.shade50 : Colors.red.shade50,
        title: Row(
          children: [
            Icon(
              hoVinto ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 40,
              color: hoVinto ? Colors.amber : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hoVinto ? 'VITTORIA!' : 'SCONFITTA',
                style: TextStyle(
                  color: hoVinto ? Colors.green.shade900 : Colors.red.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hoVinto
                  ? 'Complimenti!\nHai affondato tutte le navi nemiche!'
                  : 'Peccato!\nTutte le tue navi sono state affondate.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              hoVinto ? ':D GG' : ';( SFORTUNA',
              style: const TextStyle(fontSize: 32),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: hoVinto ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Torna al menu', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // invio del colpo al server
  void inviaColpo(int x, int y) {
    if (!widget.ws.isConnected) {
      print('ERRORE: WebSocket non connesso!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connessione persa!')),
      );
      return;
    }

    if (!_mioTurno) {
      print('Non è il tuo turno!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Non è il tuo turno!')),
      );
      return;
    }

    if (_partitaFinita) {
      print('Partita già finita!');
      return;
    }

    if (_nemicoTiri[x][y]) {
      print('Cella già colpita!');
      return;
    }

    print('=== INVIO COLPO: ($x, $y) ===');
    widget.ws.invia(jsonEncode({
      'azione': 'colpo',
      'x': x,
      'y': y,
    }));
  }

  // chiusura pagina
  @override
  void dispose() {
    print('=== GAME PAGE DISPOSE ===');
    widget.ws.disconnetti();
    super.dispose();
  }

  // UI GRIGLIE
  Widget _buildGrigliaNemica() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cellSize = (constraints.maxWidth - (dimensione + 1) * 2) / dimensione;
        cellSize = cellSize.clamp(20.0, 35.0);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: dimensione,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemCount: dimensione * dimensione,
          itemBuilder: (context, index) {
            int x = index ~/ dimensione;
            int y = index % dimensione;
            bool colpito = _nemicoTiri[x][y];

            return GestureDetector(
              onTap: () {
                print('Tap su griglia nemica: ($x, $y)');
                inviaColpo(x, y);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: colpito ? Colors.red.shade400 : Colors.blue.shade300,
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Center(
                  child: colpito
                      ? Icon(Icons.close, color: Colors.white, size: cellSize * 0.6)
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGrigliaPropria() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cellSize = (constraints.maxWidth - (dimensione + 1) * 2) / dimensione;
        cellSize = cellSize.clamp(20.0, 35.0);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: dimensione,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemCount: dimensione * dimensione,
          itemBuilder: (context, index) {
            int x = index ~/ dimensione;
            int y = index % dimensione;

            bool haNave = _mieNavi[x][y];
            bool colpito = _mieNaviColpite[x][y];

            Color coloreCella;
            Widget? icona;

            if (colpito && haNave) {
              coloreCella = Colors.red.shade700;
              icona = Icon(Icons.close, color: Colors.white, size: cellSize * 0.6);
            } else if (colpito) {
              coloreCella = Colors.blue.shade200;
              icona = Icon(Icons.circle, color: Colors.white, size: cellSize * 0.3);
            } else if (haNave) {
              coloreCella = Colors.green.shade600;
            } else {
              coloreCella = Colors.blue.shade100;
            }

            return Container(
              decoration: BoxDecoration(
                color: coloreCella,
                border: Border.all(color: Colors.white70, width: 1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Center(child: icona),
            );
          },
        );
      },
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _mioTurno ? "Tuo turno :)" : "Turno avversario :|",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: _mioTurno ? Colors.green : Colors.red,
        centerTitle: true,
        elevation: 4,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                color: _mioTurno ? Colors.green.shade100 : Colors.red.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _mioTurno ? Icons.touch_app : Icons.hourglass_empty,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _mioTurno ? "Tocca per sparare" : "Aspetta...",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              // griglia nemica
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.my_location, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "GRIGLIA AVVERSARIO",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildGrigliaNemica(),
                  ],
                ),
              ),

              // divisore
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
                child: Divider(thickness: 2, color: Colors.grey.shade400),
              ),

              // griglia propria
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.directions_boat, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "LE TUE NAVI",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "🟢 Nave | 🔴 Colpita | 🔵 Acqua",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    _buildGrigliaPropria(),
                  ],
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}