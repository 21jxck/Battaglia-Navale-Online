import 'package:web_socket_channel/io.dart';
import 'dart:async';

// classe che gestisce la comunicazione websocket
class WebSocketService {
  final String indirizzo = 'ws://192.168.1.10:8080';

  IOWebSocketChannel? _channel;
  void Function(String messaggio)? _onMessaggio;   // callback per messaggio da server
  StreamSubscription? _subscription;
  bool _connected = false;

  // indica se la connessione e' attiva
  bool get isConnected => _connected;

  // connessione al server
  void connetti(void Function(String) onMsg) {
    _onMessaggio = onMsg;

    try {
      print('[WS] Tentativo di connessione al server...');
      _channel = IOWebSocketChannel.connect(indirizzo);

      _subscription?.cancel();

      // ascoltiamo i messaggi in arrivo
      _subscription = _channel!.stream.listen(
        _handleMessaggio,
        onDone: _handleDisconnessione,
        onError: _handleErrore,
        cancelOnError: false,
      );

      _connected = true;
      print('[WS] Connesso al server!');
    } catch (e) {
      print('[WS] ERRORE connessione: $e');
      _connected = false;
    }
  }

  // gestione messaggi
  void _handleMessaggio(dynamic messaggio) {
    final messaggioStr = messaggio.toString();
    final preview = messaggioStr.length > 100
        ? '${messaggioStr.substring(0, 100)}...'
        : messaggioStr;

    print('[WS] Messaggio: $preview');


    _onMessaggio?.call(messaggioStr);
  }

  // gestione disconnessione
  void _handleDisconnessione() {
    print('[WS] Connessione chiusa');
    _connected = false;
  }

  // gestione errori
  void _handleErrore(dynamic errore) {
    print('[WS] Errore: $errore');
    _connected = false;
  }

  // usato al cambio di page
  void aggiornaCallback(void Function(String) nuovoCallback) {
    print('[WS] Aggiornamento callback');
    _onMessaggio = nuovoCallback;
  }

  // invia messaggio al server
  void invia(String messaggio) {
    if (!_connected || _channel == null) {
      print('[WS] ERRORE: Tentativo di invio ma connessione non attiva!');
      return;
    }

    try {
      _channel!.sink.add(messaggio);
      print('[WS] >>>> Messaggio inviato: $messaggio');
    } catch (e) {
      print('[WS] ERRORE invio messaggio: $e');
      _connected = false;
    }
  }

  void disconnetti() {
    print('[WS] Disconnessione manuale...');
    _connected = false;
    _subscription?.cancel();
    _channel?.sink.close();
  }
}