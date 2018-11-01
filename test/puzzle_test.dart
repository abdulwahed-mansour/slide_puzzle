import 'dart:math' as math;

import 'package:slide_puzzle/src/puzzle.dart';
import 'package:test/test.dart';

final _rnd = math.Random();

Puzzle _ordered(int width, int height, {int offset = 0}) {
  final length = width * height;
  final list = List<int>.generate(length, (i) {
    return (i - offset) % length;
  });
  return Puzzle.raw(width, list);
}

// printOnFailure trims input – which is weird – so adding a leading line
void _printPuzzleOnFailure(Puzzle puzzle) {
  printOnFailure('* here is the puzzle\n$puzzle');
}

void main() {
  test('must be at least 3 x 3', () {
    expect(() => Puzzle.raw(3, []), throwsArgumentError);
    expect(() => Puzzle.raw(3, [0, 1, 2]), throwsArgumentError);
    expect(() => Puzzle.raw(3, [0, 1, 2, 3, 4, 5]), throwsArgumentError);
  });

  test('initial values must be correct', () {
    expect(
        () => Puzzle.raw(3, [0, 1, 2, 3, 4, 5, 6, 7, 7]), throwsArgumentError);

    final width = 3, height = 3;

    final puzzle = _ordered(width, height);
    expect(puzzle.width, width);
    expect(puzzle.height, height);
    expect(puzzle.length, width * height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        expect(puzzle.value(x, y), x + y * width);
      }
    }
  });

  test('toString', () {
    final puzzle = _ordered(4, 4);
    _printPuzzleOnFailure(puzzle);
    expect(puzzle.toString(), '''
 0  1  2  3
 4  5  6  7
 8  9 10 11
12 13 14 15''');
  });

  group('click', () {
    bool doClick(Puzzle puzzle, int x, int y) {
      final startCount = puzzle.clickCount;
      final startString = puzzle.toString();
      final clickResult = puzzle.click(x, y);
      if (clickResult) {
        expect(puzzle.clickCount, startCount + 1);
        expect(puzzle.toString(), isNot(startString));
      } else {
        expect(puzzle.clickCount, startCount);
        expect(puzzle.toString(), startString);
      }
      return clickResult;
    }

    test('click on last tile is a noop', () {
      var puzzle = _ordered(4, 4);
      expect(puzzle.value(0, 0), 0);
      expect(doClick(puzzle, 0, 0), isFalse);

      puzzle = _ordered(3, 3, offset: 2);
      expect(puzzle.toString(), '''
7 8 0
1 2 3
4 5 6''');

      expect(puzzle.value(2, 0), 0);
      expect(doClick(puzzle, 1, 0), isFalse);

      for (var i = 0; i < 10; i++) {
        puzzle = Puzzle(5, 5);
        final zeroLocation = puzzle.coordinatesOf(24);
        expect(doClick(puzzle, zeroLocation.x, zeroLocation.y), isFalse);
      }
    });

    test('click on a cell not aligned with zero is a noop', () {
      var puzzle = _ordered(4, 4);
      expect(puzzle.value(1, 1), 5);
      expect(doClick(puzzle, 1, 1), isFalse);

      puzzle = _ordered(3, 3, offset: 2);
      expect(puzzle.value(0, 1), 1);
      expect(doClick(puzzle, 0, 1), isFalse);

      for (var i = 0; i < 10; i++) {
        puzzle = Puzzle(5, 5);
        final zeroLocation = puzzle.coordinatesOf(24);

        for (var j = 0; j < 10; j++) {
          math.Point<int> randomPoint;
          do {
            randomPoint = math.Point(
                _rnd.nextInt(puzzle.width), _rnd.nextInt(puzzle.height));
          } while (randomPoint.x == zeroLocation.x ||
              randomPoint.y == zeroLocation.y);

          expect(doClick(puzzle, randomPoint.x, randomPoint.y), isFalse);
        }
      }
    });

    test('click to shift', () {
      final puzzle = _ordered(4, 4, offset: 1);
      expect(puzzle.incorrectTiles, 15);
      expect(puzzle.toString(), '''
15  0  1  2
 3  4  5  6
 7  8  9 10
11 12 13 14''');

      expect(puzzle.value(1, 0), 0);
      expect(doClick(puzzle, 1, 0), isTrue);
      expect(puzzle.toString(), '''
 0 15  1  2
 3  4  5  6
 7  8  9 10
11 12 13 14''');

      expect(doClick(puzzle, 1, 0), isFalse);
      expect(doClick(puzzle, 0, 0), isTrue);
      expect(puzzle.toString(), '''
15  0  1  2
 3  4  5  6
 7  8  9 10
11 12 13 14''');

      expect(doClick(puzzle, 0, 0), isFalse);
      expect(doClick(puzzle, 0, 1), isTrue);
      expect(puzzle.toString(), '''
 3  0  1  2
15  4  5  6
 7  8  9 10
11 12 13 14''');

      expect(doClick(puzzle, 0, 1), isFalse);
      expect(doClick(puzzle, 0, 0), isTrue);
      expect(puzzle.toString(), '''
15  0  1  2
 3  4  5  6
 7  8  9 10
11 12 13 14''');

      expect(doClick(puzzle, 0, 0), isFalse);
      expect(doClick(puzzle, 3, 0), isTrue);
      expect(puzzle.toString(), '''
 0  1  2 15
 3  4  5  6
 7  8  9 10
11 12 13 14''');

      expect(puzzle.incorrectTiles, 12);
      expect(doClick(puzzle, 3, 0), isFalse);
      expect(doClick(puzzle, 3, 3), isTrue);
      expect(puzzle.toString(), '''
 0  1  2  6
 3  4  5 10
 7  8  9 14
11 12 13 15''');

      expect(doClick(puzzle, 3, 3), isFalse);
      expect(doClick(puzzle, 0, 3), isTrue);
      expect(puzzle.toString(), '''
 0  1  2  6
 3  4  5 10
 7  8  9 14
15 11 12 13''');

      expect(doClick(puzzle, 0, 3), isFalse);
      expect(doClick(puzzle, 0, 0), isTrue);
      expect(puzzle.toString(), '''
15  1  2  6
 0  4  5 10
 3  8  9 14
 7 11 12 13''');

      expect(puzzle.incorrectTiles, 13);
      expect(puzzle.clickCount, 8);
    });
  });

  test('new puzzles should have all tiles in incorrect positions', () {
    for (var i = 0; i < 100; i++) {
      final puzzle = Puzzle(4, 4);
      expect(puzzle.incorrectTiles, 15);
      expect(puzzle.fitness, greaterThanOrEqualTo(15));
    }
  });

  test('reset', () {
    final puzzle = Puzzle(4, 4);
    expect(puzzle.incorrectTiles, puzzle.tileCount);
    expect(puzzle.fitness, greaterThanOrEqualTo(puzzle.tileCount));

    do {
      // click around until one tile is in the right location
      puzzle.click(_rnd.nextInt(puzzle.width), _rnd.nextInt(puzzle.height));
    } while (puzzle.incorrectTiles == puzzle.tileCount);

    expect(puzzle.incorrectTiles, lessThan(puzzle.tileCount));
    expect(puzzle.clickCount, greaterThan(0));

    puzzle.reset();

    expect(puzzle.incorrectTiles, puzzle.tileCount);
    expect(puzzle.fitness, greaterThanOrEqualTo(puzzle.tileCount));
    expect(puzzle.clickCount, 0);
  });

  test('fitness', () {
    final puzzle = Puzzle.raw(3, [0, 1, 2, 3, 4, 5, 6, 7, 8]);
    expect(puzzle.incorrectTiles, 0);
    expect(puzzle.fitness, 0);
    expect(puzzle.toString(), '''
0 1 2
3 4 5
6 7 8''');

    expect(puzzle.clickValue(7), isTrue);
    expect(puzzle.incorrectTiles, 1);
    expect(puzzle.fitness, 1);
    expect(puzzle.toString(), '''
0 1 2
3 4 5
6 8 7''');

    expect(puzzle.clickValue(6), isTrue);
    expect(puzzle.clickValue(3), isTrue);
    expect(puzzle.clickValue(4), isTrue);
    expect(puzzle.clickValue(6), isTrue);
    expect(puzzle.toString(), '''
0 1 2
4 6 5
3 8 7''');
    expect(puzzle.incorrectTiles, 4);
    expect(puzzle.fitness, 7);

    final puzzle2 = Puzzle.raw(3, [8, 1, 2, 3, 4, 5, 6, 7, 0]);
    expect(puzzle2.incorrectTiles, 1);
    expect(puzzle2.toString(), '''
8 1 2
3 4 5
6 7 0''');
    expect(puzzle2.fitness, 16);

    final puzzle3 = Puzzle.raw(3, [3, 0, 1, 4, 5, 2, 7, 6, 8]);
    expect(puzzle3.incorrectTiles, 8);
    expect(puzzle3.fitness, 8);
  });

  test('click random', () {
    final puzzle = Puzzle(4, 4);
    final moves = puzzle.clickRandom(5);
    expect(moves.length, 5);
    expect(puzzle.clickCount, 5);
  });

  test('clone', () {
    final puzzle = Puzzle(4, 4);
    expect(puzzle.clickRandom(5), hasLength(5));
    expect(puzzle.clickCount, 5);
    final clone = puzzle.clone();
    expect(clone, isNot(same(puzzle)));
    expect(clone.toString(), puzzle.toString());
    expect(clone.incorrectTiles, puzzle.incorrectTiles);
    expect(clone.clickCount, 0);

    expect(puzzle.clickRandom(1), hasLength(1));
    expect(clone.toString(), isNot(puzzle.toString()));
    expect(puzzle.clickCount, 6);
    expect(clone.clickCount, 0);
  });

  test('bad self play', () {
    int _score(Puzzle p) => p.incorrectTiles + p.fitness;
    final puzzle = Puzzle(4, 4);

    while (puzzle.incorrectTiles > 0) {
      print(['*', puzzle.incorrectTiles, puzzle.fitness, _score(puzzle)]);
      final options = Iterable.generate(puzzle.tileCount * 10, (i) {
        final p = puzzle.clone();
        return MapEntry(p, p.clickRandom(puzzle.tileCount));
      }).toList();

      options.sort((a, b) {
        return _score(a.key).compareTo(_score(b.key));
      });

      //if (_score(options.first.key) <= _score(puzzle)) {
      options.first.value.forEach(puzzle.clickValue);
      expect(options.first.key.toString(), puzzle.toString());
      print('using! - now with ${puzzle.incorrectTiles} - ${_score(puzzle)}');
      //} else {
      print(puzzle);
    }
    print(puzzle.clickCount);
  }, skip: true);
}
