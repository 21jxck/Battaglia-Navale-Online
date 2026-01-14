import '../lib/server_gioco.dart';

// classe che permette l'avvio del server (comando dart run nel terminale)
void main() {
  ServerGioco server = ServerGioco();
  server.avvia();
}