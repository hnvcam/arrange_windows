part of 'ExecutorBloc.dart';

enum Arrangement {
  almostMaximize,
  makeLarger,
  makeSmaller,
  leftHalf,
  rightHalf,
  topHalf,
  bottomHalf,
  firstThird,
  lastThird,
  firstTwoThirds,
  lastTwoThirds,
  prevDisplay,
  nextDisplay;

  String get assetPath => 'assets/arrange/${name}Template.png';
  String get label {
    final words = name.split(RegExp(r'(?=[A-Z])'));
    words[0] = words[0].substring(0, 1).toUpperCase() +
        words[0].substring(1).toLowerCase();
    return words.join(' ');
  }
}
