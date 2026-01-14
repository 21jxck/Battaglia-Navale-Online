import 'dart:convert';
import 'giocatore.dart';
import 'enums.dart';
import 'nave.dart';

// classe che gestisce la partita tra due giocatori
class Partita {
  final Giocatore giocatore1;
  final Giocatore giocatore2;
  Giocatore turnoCorrente;
  StatoPartita stato = StatoPartita.posizionamento;
  Giocatore? vincitore;

  Partita(this.giocatore1, this.giocatore2)
      : turnoCorrente = giocatore1;

  // avvia la partita
  void avvia() {
    _inizializzaGriglie();
    _configuraListener();
    inviaStato();
  }

  void _inizializzaGriglie() {
    giocatore1.griglia.posizionaNaviCasuali();
    giocatore2.griglia.posizionaNaviCasuali();

    print('=== PARTITA AVVIATA ===');
    print('Navi giocatore 1: ${giocatore1.griglia.navi.length}');
    print('Navi giocatore 2: ${giocatore2.griglia.navi.length}');
  }

  // configura i listener websocket
  void _configuraListener() {
    giocatore1.socket.listen(
      (msg) => gestisciMessaggio(giocatore1, msg),
      onDone: () => print('Giocatore 1 disconnesso'),
      onError: (err) => print('Errore giocatore 1: $err'),
    );

    giocatore2.socket.listen(
      (msg) => gestisciMessaggio(giocatore2, msg),
      onDone: () => print('Giocatore 2 disconnesso'),
      onError: (err) => print('Errore giocatore 2: $err'),
    );

    print('Configurazione listener terminata, invio stato iniziale...');
  }

  // gestisce i messaggi dei client
  void gestisciMessaggio(Giocatore g, dynamic msg) {
    try {
      Map<String, dynamic> dati = jsonDecode(msg);
      print('Messaggio ricevuto da giocatore: ${dati['azione']}');

      switch (dati['azione']) {
        case 'pronto':
          _gestisciPronto(g);
          break;
        case 'colpo':
          _gestisciColpo(g, dati);
          break;
        default:
          print('Azione sconosciuta: ${dati['azione']}');
      }
    } catch (e) {
      print('Errore parsing messaggio: $e');
    }
  }

  void _gestisciPronto(Giocatore g) {
      g.pronto = true;
    print('Giocatore pronto. G1: ${giocatore1.pronto}, G2: ${giocatore2.pronto}');
    if (giocatore1.pronto && giocatore2.pronto) {
      stato = StatoPartita.inGioco;
      print('Entrambi pronti! Partita iniziata.');
      inviaStato();
    }
  }

  void _gestisciColpo(Giocatore g, Map<String, dynamic> dati) {
      if (stato != StatoPartita.inGioco) {
        print('Partita non in corso.');
        return;
      }

      if (g != turnoCorrente) {
        print('Non è il turno di questo giocatore');
        return;
      }

      // colpisce
      Giocatore avversario = _getAvversario(g);

      int x = dati['x'] as int;
      int y = dati['y'] as int;

      print('=== COLPO A ($x, $y) ===');

      // trova la nave prima di colpire
      Nave? naveColpita;
      for (Nave nave in avversario.griglia.navi) {
        for (var pos in nave.posizioni) {
          if (pos.x == x && pos.y == y) {
            naveColpita = nave;
            break;
          }
        }
        if (naveColpita != null) break;
      }

      var esito = avversario.griglia.riceviColpo(x, y);
      print('Esito: $esito');

      Map<String, dynamic>? infoAffondamento;
      if (esito == EsitoColpo.affondato && naveColpita != null) {
        infoAffondamento = {
          'lunghezza': naveColpita.lunghezza,
          'nome': _getNomeNave(naveColpita.lunghezza),
        };
        print('NAVE AFFONDATA: ${infoAffondamento['nome']} (${infoAffondamento['lunghezza']})');
      }

      //checkwin
      if (avversario.griglia.tutteNaviAffondate()) {
        _terminaPartita(g);
      } else {
        cambiaTurno();
      }

      _inviaStatoConAffondamento(g, infoAffondamento);
  }

  // restituisce il nome della nave per lunghezza
  String _getNomeNave(int lunghezza) {
    switch (lunghezza) {
      case 5:
        return 'Portaerei';
      case 4:
        return 'Corazzata';
      case 3:
        return 'Incrociatore';
      case 2:
        return 'Cacciatorpediniere';
      default:
        return 'Nave';
    }
  }

  void _inviaStatoConAffondamento(Giocatore? giocatoreAffondante, Map<String, dynamic>? infoAffondamento) {
    // stato per chi ha affondato
    if (giocatoreAffondante != null && infoAffondamento != null) {
      Map<String, dynamic> statoConNotifica = statoPartita(giocatoreAffondante);
      statoConNotifica['naveAffondata'] = infoAffondamento;
      giocatoreAffondante.invia(statoConNotifica);

      // stato normale per l'avversario
      Giocatore altro = _getAvversario(giocatoreAffondante);
      altro.invia(statoPartita(altro));
    } else {
      inviaStato();
    }
  }

  // imposta il vincitore
  void _terminaPartita(Giocatore vincitore) {
    stato = StatoPartita.finita;
    this.vincitore = vincitore;

    print('=== PARTITA FINITA! ===');
    print('VINCITORE: ${vincitore == giocatore1 ? "Giocatore 1" : "Giocatore 2"}');
  }

  // ritorna l'avversario del giocatore g
  Giocatore _getAvversario(Giocatore g) {
    return g == giocatore1 ? giocatore2 : giocatore1;
  }

  // swappa il turno tra i giocatori
  void cambiaTurno() {
    turnoCorrente = _getAvversario(turnoCorrente);
    print('Turno cambiato: ora tocca a ${turnoCorrente == giocatore1 ? "Giocatore 1" : "Giocatore 2"}');
  }

  // invia lo stato per tutti i giocatori
  void inviaStato() {
    giocatore1.invia(statoPartita(giocatore1));
    giocatore2.invia(statoPartita(giocatore2));
  }

  // genera lo stato partita di un giocatore
  Map<String, dynamic> statoPartita(Giocatore g) {
    Giocatore avversario = _getAvversario(g);

    return {
      'stato': stato.name,
      'mioTurno': g == turnoCorrente,
      'vincitore': vincitore != null ? (g == vincitore ? 'io' : 'avversario') : null,
      'grigliaPropria': g.griglia.serializza(true),
      'grigliaNemica': avversario.griglia.serializza(false),
    };
  }
}