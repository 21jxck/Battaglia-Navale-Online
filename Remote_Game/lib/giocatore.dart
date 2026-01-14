import 'dart:io';
import 'dart:convert';
import 'griglia.dart';

// classe che rappresenta ogni giocatore che si collega al server (con la propria griglia)
class Giocatore {
  WebSocket socket;
  Griglia griglia = Griglia();
  bool pronto = false;

  Giocatore(this.socket);

  void invia(Map messaggio) {
    socket.add(jsonEncode(messaggio));
  }
}
