import 'dart:math';
import 'cella.dart';
import 'nave.dart';
import 'enums.dart';
import 'coordinate.dart';

// classe per la griglia 10x10 con le navi
class Griglia {
  static const int dimensione = 10;

  List<List<Cella>> celle = List.generate(
      dimensione,
      (_) => List.generate(dimensione, (_) => Cella())
  );
  List<Nave> navi = [];

  void posizionaNaviCasuali() {
    // lista con lunghezze delle navi. navi utilizzate: 1x portaerei(5), 1x corazzata(4), 2x incrociatori(3), 1x cacciatorpediniere(2)
    List<int> configurazione = [5, 4, 3, 3, 2];

    Random random = Random();

    for (int lunghezza in configurazione) {
      bool posizionata = false;
      int tentativi = 0;

      while (!posizionata && tentativi < 100) {
        tentativi++;

        bool orizzontale = random.nextBool();
        int startX = random.nextInt(10);
        int startY = random.nextInt(10);

        if (_puoPosizionare(startX, startY, lunghezza, orizzontale)) {
          _posizionaNave(startX, startY, lunghezza, orizzontale);
          posizionata = true;
        }
      }

      if (!posizionata) {
        print('ATTENZIONE: Impossibile posizionare nave di lunghezza $lunghezza');
      }
    }

    print('Navi posizionate: ${navi.length}');
  }

  // controlla se la nave puo' essere posizionata
  bool _puoPosizionare(int x, int y, int lunghezza, bool orizzontale) {
    // controlla se esce dal 10x10
    if (orizzontale) {
      if (y + lunghezza > 10) return false;
    } else {
      if (x + lunghezza > 10) return false;
    }

    // controlla sovrapposizioni
    for (int i = 0; i < lunghezza; i++) {
      int checkX = orizzontale ? x : x + i;
      int checkY = orizzontale ? y + i : y;

      if (celle[checkX][checkY].haNave) {
        return false;
      }
    }

    return true;
  }

  void _posizionaNave(int x, int y, int lunghezza, bool orizzontale) {
    Nave nave = Nave(lunghezza);

    for (int i = 0; i < lunghezza; i++) {
      int posX = orizzontale ? x : x + i;
      int posY = orizzontale ? y + i : y;

      celle[posX][posY].haNave = true;
      nave.posizioni.add(Coordinate(posX, posY));
    }

    navi.add(nave);
  }

  // gestisce il colpo ricevuto
  EsitoColpo riceviColpo(int x, int y) {
    print('Ricevo colpo in ($x, $y)');

    Cella cella = celle[x][y];
    if (cella.colpita) {
      print('-> Già colpita!');
      return EsitoColpo.mancato;
    }

    cella.colpita = true;

    if (cella.haNave) {
      print('-> Colpito!');

      // cerca quale nave è stata colpita
      for (Nave nave in navi) {
        for (var pos in nave.posizioni) {
          if (pos.x == x && pos.y == y) {
            nave.colpiSubiti++;
            print('-> Nave colpita ${nave.colpiSubiti}/${nave.lunghezza}');

            if (nave.eAffondata()) {
              print('-> Nave affondata!');
              return EsitoColpo.affondato;
            }
            return EsitoColpo.colpito;
          }
        }
      }
      return EsitoColpo.colpito;
    }

    print('-> Mancato (acqua)');
    return EsitoColpo.mancato;
  }

  // check win
  bool tutteNaviAffondate() {
    if (navi.isEmpty) {
      print('ERRORE: Nessuna nave presente!');
      return false;
    }

    int naviAffondate = navi.where((n) => n.eAffondata()).length;
    bool tutte = navi.every((nave) => nave.eAffondata());

    print('Check vittoria: $naviAffondate/${navi.length} navi affondate');
    return tutte;
  }

  // serializza la griglia in json
  List serializza(bool mostraNavi) {
    return celle
        .map((riga) => riga
          .map((c) => {
              'colpita': c.colpita,
              'haNave': mostraNavi ? c.haNave : false // se true include la posizione navi
            })
        .toList())
      .toList();
  }
}