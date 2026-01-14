# Battaglia Navale Online

Progetto di **Battaglia Navale multiplayer** realizzato con **Dart** (server) e **Flutter** (client).  
Il gioco permette a due giocatori di sfidarsi in tempo reale tramite WebSocket.

## Indice

- [Struttura del progetto](#struttura-del-progetto)  
- [Server](#server)  
- [Client](#client)  
- [Funzionamento](#funzionamento)
- [Griglia e navi](#griglia-e-navi)
- [Comunicazione WebSocket](#comunicazione-websocket)
- [Note](#note)
- [Requisiti dell app](#requisiti-dell-app)
- [Avvio del gioco](#avvio-del-gioco)  
- [Autore](#autore)  

## Struttura del progetto
Il progetto è suddiviso in due directories contenenti vari file. 
La prima directory è `Remote_Game` e contiene tutti i file relativi al server dart per il gioco.
La seconda directory è `remote_game_client` e contiene i file del client battaglia navale.

Ora li osserviamo nel dettaglio.

## Server (`Remote_Game`)

Il server è responsabile della gestione delle partite, dei giocatori e della logica di gioco.  

- **remote_game.dart**: punto di ingresso per avviare il server (`dart run`).
- **server_gioco.dart**: gestisce le connessioni WebSocket, mette i giocatori in coda e avvia le partite.
- **partita.dart**: gestisce la partita tra due giocatori, turni, colpi, affondamenti, vittoria.
- **giocatore.dart**: rappresenta ogni giocatore con la propria griglia e il socket.
- **griglia.dart**: logica della griglia 10x10, posizionamento navi casuale, gestione colpi.
- **cella.dart**: rappresenta una cella della griglia.
- **nave.dart**: rappresenta una nave con lunghezza, posizioni e colpi subiti.
- **coordinate.dart**: rappresenta le coordinate `(x, y)` di una cella.
- **enums.dart**: contiene gli enum `StatoPartita` e `EsitoColpo`.

## Client (`remote_game_client`)

Il client Flutter gestisce l’interfaccia utente e la comunicazione con il server.

- **main.dart**: entry point Flutter. Avvia la `HomePage`.
- **home_page.dart**: schermata principale con pulsante “Ricerca partita”.
- **waiting_page.dart**: schermata in attesa di avversario; invia messaggio `pronto` al server.
- **gioco_page.dart**: UI della partita, mostra la griglia propria e quella dell’avversario, gestisce colpi e notifiche.
- **websocket_service.dart**: gestisce la connessione WebSocket al server, invio/ricezione messaggi, callback.
- **cella_ui.dart**: rappresenta una cella della UI: stato colpita o nave presente.
- **game_state.dart**: stato corrente del gioco per il client.

## Funzionamento

1. Il client si connette al server tramite WebSocket.
2. Il server mette i giocatori in coda.
3. Quando due giocatori sono pronti, viene creata la partita tra loro.
4. Le navi sono posizionate in modo randomico e a turno, i giocatori sparano 1 colpo alla griglia nemica.
5. I colpi vengono gestiti dal server, con i conseguenti affondamenti e buchi nell'acqua.
6. Quando tutte le navi di un giocatore vengono affondate, il server dichiara il vincitore e termina la partita.

## Griglia e navi

La griglia assume dimensioni di 10 celle per 10.
Le navi presenti nel gioco sono:
- 1 portaerei (lunghezza 5)
- 1 corazzata (lunghezza 4)
- 2 incrociatori (lunghezza 3)
- 1 cacciatorpediniere (lunghezza 2)
Il posizionamento avviene in maniera casuale.

## Comunicazione WebSocket

I messaggi client-server utilizzano *JSON* e i principali sono:
- `pronto`: il client segnala di essere pronto per la partita.
- `stato_griglia`: invia la griglia aggiornata di un giocatore.
- `colpo`: messaggio con le coordinate di un colpo sparato (`x` e `y`).
- `vittoria`: indica la fine della partita e determina il vincitore.
- `turno`: indica a quale giocatore tocca sparare.

## Note
Il server può gestire più partite contemporaneamente tramite liste separate di `Partita`.
Le logiche dietro la griglia e le navi sono implementate in Dart nel server.
La UI mostra:
- griglia propria: navi, colpi subiti, acqua.
- griglia avversaria: acqua e colpi.
- notifiche di affondamento e vittoria/sconfitta.

## Requisiti dell app

I requisiti per poter eseguire il progetto sono i seguenti: 
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installato (cliccarlo per essere reindirizzati al sito per l'installazione),
- **Dart SDK** incluso con Flutter,
- Un editor (es. **Android Studio**),
- Un emulatore o dispositivo fisico per testare l’applicazione.

## Avvio del gioco

### Server

1. Scaricare ed aprire la cartella `Remote_Game` con un IDE compatibile con Dart/Flutter (es. Android Studio).
2. Avviare il server dal terminale con il comando:
   ```bash
   dart run bin/remote_game.dart
3. Il server si mette in ascolto sulla porta 8080.

### Client

1. Scaricare ed aprire la cartella `remote_game_client` con un IDE compatibile con Dart/Flutter (es. Android Studio).
2. Avviare il client su un emulatore e/o dispositivo reale con il seguente comando (da terminale):
   ```bash
   flutter run
3. Cliccare su "Ricerca partita" per connettersi al server.

Per poter avviare la partita bisogna far connettere al server un altro dispositivo (o emulatore).

## Autore

Sviluppo del progetto a cura di *Jacopo Olivo*, 5IB ITIS C. Zuccante - TPSIT 2025/26
