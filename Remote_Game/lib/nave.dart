import 'coordinate.dart';

// classe per le navi presenti nel 10x10
class Nave {
  int lunghezza;
  List<Coordinate> posizioni = [];
  int colpiSubiti = 0;

  Nave(this.lunghezza);

  bool eAffondata() {
    return colpiSubiti >= lunghezza;
  }
}
