import 'dart:io';
import 'giocatore.dart';
import 'partita.dart';

// classe che gestisce il server e le connessioni
class ServerGioco {
  static const String indirizzo = '0.0.0.0';
  static const int porta = 8080;

  final List<Giocatore> _giocatoriInAttesa = [];
  final List<Partita> _partiteAttive = [];

  // avvia il server e ascolta per nuove connessioni
  Future<void> avvia() async {
    final server = await HttpServer.bind(indirizzo, porta);
    //print('Server avviato sulla porta 8080');
    //print('In attesa di giocatori...');

    print('╔════════════════════════════════════════╗');
    print('║  Server Battaglia Navale avviato!      ║');
    print('║  Porta: $porta                           ║');
    print('║  In attesa di giocatori...             ║');
    print('╚════════════════════════════════════════╝');

    await for (HttpRequest richiesta in server) {
      if (WebSocketTransformer.isUpgradeRequest(richiesta)) {
        try {
          WebSocket socket = await WebSocketTransformer.upgrade(richiesta);
          _gestisciConnessione(socket);
        } catch (e) {
          print('Errore upgrade websocket: $e');
        }
      }
    }
  }

  // per le connessioni websocket
  void _gestisciConnessione(WebSocket socket) {
    print('Nuovo client connesso: ${socket.hashCode}');
    print('Giocatori in attesa: ${_giocatoriInAttesa.length}');

    Giocatore giocatore = Giocatore(socket);
    _giocatoriInAttesa.add(giocatore);

    socket.done.then((_) {
      _gestisciDisconnessione(giocatore);
    }).catchError((e) {
      print('Errore socket: $e');
      _gestisciDisconnessione(giocatore);
    });

    if (_giocatoriInAttesa.length >= 2) {
      _creaPartita();
    }
  }

  void _creaPartita() {
    Giocatore g1 = _giocatoriInAttesa.removeAt(0);
    Giocatore g2 = _giocatoriInAttesa.removeAt(0);

    Partita partita = Partita(g1, g2);
    _partiteAttive.add(partita);

    partita.avvia();
  }

  void _gestisciDisconnessione(Giocatore giocatore) {
    if (_giocatoriInAttesa.remove(giocatore)) {
      print('Giocatore disconnesso dalla coda. ');
      return;
    }

    // termina le partite in cui si disconnette un giocatore
    _partiteAttive.removeWhere((partita) {
      if (partita.giocatore1 == giocatore || partita.giocatore2 == giocatore) {
        print('Giocatore disconnesso durante la partita');
        print('Partita terminata.');

        Giocatore? altro = partita.giocatore1 == giocatore
            ? partita.giocatore2
            : partita.giocatore1;

        try {
          altro.socket.close();
        } catch (e) {}

        return true;
      }
      return false;
    });

    print('Partite attive: ${_partiteAttive.length}');
  }
}
