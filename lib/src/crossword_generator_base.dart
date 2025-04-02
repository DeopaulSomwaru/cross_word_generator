import 'dart:math';

class CrosswordGenerator {
  // Add dependency injection
  final CrosswordConfig config;

  CrosswordGenerator({this.config = const CrosswordConfig()});

  // Convert to pure mathematical operation
  static double weightedAverage(List<double> weights, List<double> values) {
    assert(weights.length == values.length, "Weights/values mismatch");
    final sum = List.generate(weights.length, (i) => weights[i] * values[i])
        .reduce((a, b) => a + b);
    return sum.clamp(0, 1); // Ensures valid range
  }

  // // Improved placement logic
  // void attemptPlacement({/* ... */}) {
  //   // Implement spatial partitioning checks
  // }

  // Math functions
  int distance(int x1, int y1, int x2, int y2) {
    return (x1 - x2).abs() + (y1 - y2).abs();
  }

  // double weightedAverage(List<double> weights, List<double> values) {
  //   double temp = 0;
  //   for (int k = 0; k < weights.length; k++) {
  //     temp += weights[k] * values[k];
  //   }

  //   if (temp < 0 || temp > 1) {
  //     print("Error: $values");
  //   }

  //   return temp;
  // }

  // Component scores
  // 1. Number of connections
  double computeScore1(int connections, String word) {
    return connections / (word.length / 2);
  }

  // 2. Distance from center
  double computeScore2(int rows, int cols, int i, int j) {
    return 1 -
        (distance(rows ~/ 2, cols ~/ 2, i, j) / ((rows / 2) + (cols / 2)));
  }

  // 3. Vertical versus horizontal orientation
  double computeScore3(double a, double b, int verticalCount, int totalCount) {
    if (verticalCount > totalCount / 2) {
      return a;
    } else if (verticalCount < totalCount / 2) {
      return b;
    } else {
      return 0.5;
    }
  }

  // 4. Word length
  double computeScore4(int val, String word) {
    return word.length / val;
  }

  // Word functions
  void addWord(List<dynamic> best, List<Map<String, dynamic>> words,
      List<List<String>> table) {
    double bestScore =
        best[0].runtimeType == String ? double.parse(best[0]) : best[0];
    String word = best[1];
    int index = best[2].runtimeType == String ? int.parse(best[2]) : best[2];
    int bestI = best[3].runtimeType == String ? int.parse(best[3]) : best[3];
    int bestJ = best[4].runtimeType == String ? int.parse(best[4]) : best[4];
    int bestO = best[5].runtimeType == String ? int.parse(best[5]) : best[5];

    // Ensure the map contains the necessary keys
    if (!words[index].containsKey('startx')) {
      words[index]['startx'] = 0;
    }
    if (!words[index].containsKey('starty')) {
      words[index]['starty'] = 0;
    }

    words[index]['startx'] = bestJ + 1;
    words[index]['starty'] = bestI + 1;

    if (bestO == 0) {
      for (int k = 0; k < word.length; k++) {
        table[bestI][bestJ + k] = word[k];
      }
      words[index]['orientation'] = "across";
    } else {
      for (int k = 0; k < word.length; k++) {
        table[bestI + k][bestJ] = word[k];
      }
      words[index]['orientation'] = "down";
    }
    print("$word, $bestScore");
  }

  void assignPositions(List<Map<String, dynamic>> words) {
    Map<String, int> positions = {};
    for (int index = 0; index < words.length; index++) {
      var word = words[index];
      if (word['orientation'] != "none") {
        String tempStr = "${word['starty']},${word['startx']}";
        if (positions.containsKey(tempStr)) {
          word['position'] = positions[tempStr];
        } else {
          positions[tempStr] = positions.length + 1;
          word['position'] = positions[tempStr];
        }
      }
    }
  }

  int computeDimension(List<Map<String, dynamic>> words, int factor) {
    int temp = 0;
    for (int i = 0; i < words.length; i++) {
      if (temp < words[i]['answer'].length) {
        temp = words[i]['answer'].length;
      }
    }

    return temp * factor;
  }

  // Table functions
  List<List<String>> initTable(int rows, int cols) {
    List<List<String>> table =
        List.generate(rows, (_) => List.filled(cols, '-'));
    return table;
  }

  bool isConflict(List<List<String>> table, bool isVertical, String character,
      int i, int j) {
    if (character != table[i][j] && table[i][j] != "-") {
      return true;
    } else if (table[i][j] == "-" &&
        !isVertical &&
        (i + 1) < table.length &&
        table[i + 1][j] != "-") {
      return true;
    } else if (table[i][j] == "-" &&
        !isVertical &&
        (i - 1) >= 0 &&
        table[i - 1][j] != "-") {
      return true;
    } else if (table[i][j] == "-" &&
        isVertical &&
        (j + 1) < table[i].length &&
        table[i][j + 1] != "-") {
      return true;
    } else if (table[i][j] == "-" &&
        isVertical &&
        (j - 1) >= 0 &&
        table[i][j - 1] != "-") {
      return true;
    } else {
      return false;
    }
  }

  List<dynamic> attemptToInsert(
      int rows,
      int cols,
      List<List<String>> table,
      List<double> weights,
      int verticalCount,
      int totalCount,
      String word,
      int index) {
    int bestI = 0;
    int bestJ = 0;
    int bestO = 0;
    double bestScore = -1;

    // Horizontal
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols - word.length + 1; j++) {
        bool isValid = true;
        int connections = 0;
        bool prevFlag = false;

        for (int k = 0; k < word.length; k++) {
          if (isConflict(table, false, word[k], i, j + k)) {
            isValid = false;
            break;
          } else if (table[i][j + k] == "-") {
            prevFlag = false;
          } else {
            if (prevFlag) {
              isValid = false;
              break;
            } else {
              prevFlag = true;
              connections += 1;
            }
          }
        }

        if ((j - 1) >= 0 && table[i][j - 1] != "-") {
          isValid = false;
        } else if ((j + word.length) < table[i].length &&
            table[i][j + word.length] != "-") {
          isValid = false;
        }

        if (isValid) {
          double tempScore1 = computeScore1(connections, word);
          double tempScore2 =
              computeScore2(rows, cols, i, j + (word.length ~/ 2));
          double tempScore3 = computeScore3(1, 0, verticalCount, totalCount);
          double tempScore4 = computeScore4(rows, word);
          double tempScore = weightedAverage(
              weights, [tempScore1, tempScore2, tempScore3, tempScore4]);

          if (tempScore > bestScore) {
            bestScore = tempScore;
            bestI = i;
            bestJ = j;
            bestO = 0;
          }
        }
      }
    }

    // Vertical
    for (int i = 0; i < rows - word.length + 1; i++) {
      for (int j = 0; j < cols; j++) {
        bool isValid = true;
        int connections = 0;
        bool prevFlag = false;

        for (int k = 0; k < word.length; k++) {
          if (isConflict(table, true, word[k], i + k, j)) {
            isValid = false;
            break;
          } else if (table[i + k][j] == "-") {
            prevFlag = false;
          } else {
            if (prevFlag) {
              isValid = false;
              break;
            } else {
              prevFlag = true;
              connections += 1;
            }
          }
        }

        if ((i - 1) >= 0 && table[i - 1][j] != "-") {
          isValid = false;
        } else if ((i + word.length) < table.length &&
            table[i + word.length][j] != "-") {
          isValid = false;
        }

        if (isValid) {
          double tempScore1 = computeScore1(connections, word);
          double tempScore2 =
              computeScore2(rows, cols, i + (word.length ~/ 2), j);
          double tempScore3 = computeScore3(0, 1, verticalCount, totalCount);
          double tempScore4 = computeScore4(rows, word);
          double tempScore = weightedAverage(
              weights, [tempScore1, tempScore2, tempScore3, tempScore4]);

          if (tempScore > bestScore) {
            bestScore = tempScore;
            bestI = i;
            bestJ = j;
            bestO = 1;
          }
        }
      }
    }

    if (bestScore > -1) {
      return [bestScore, word, index, bestI, bestJ, bestO];
    } else {
      // Allow placement even if no connections
      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols - word.length + 1; j++) {
          bool isValid = true;
          for (int k = 0; k < word.length; k++) {
            if (isConflict(table, false, word[k], i, j + k)) {
              isValid = false;
              break;
            }
          }
          if (isValid) {
            return [0, word, index, i, j, 0];
          }
        }
      }

      for (int i = 0; i < rows - word.length + 1; i++) {
        for (int j = 0; j < cols; j++) {
          bool isValid = true;
          for (int k = 0; k < word.length; k++) {
            if (isConflict(table, true, word[k], i + k, j)) {
              isValid = false;
              break;
            }
          }
          if (isValid) {
            return [0, word, index, i, j, 1];
          }
        }
      }

      return [-1];
    }
  }

  Map<String, dynamic> generateTable(List<List<String>> table, int rows,
      int cols, List<Map<String, dynamic>> words, List<double> weights) {
    int verticalCount = 0;
    int totalCount = 0;

    for (int outerIndex = 0; outerIndex < words.length; outerIndex++) {
      List<dynamic> best = [-1];
      for (int innerIndex = 0; innerIndex < words.length; innerIndex++) {
        if (words[innerIndex].containsKey('answer') &&
            !words[innerIndex].containsKey('startx')) {
          List<dynamic> temp = attemptToInsert(
              rows,
              cols,
              table,
              weights,
              verticalCount,
              totalCount,
              words[innerIndex]['answer'],
              innerIndex);
          if (temp[0] > best[0]) {
            best = temp;
          }
        }
      }

      if (best[0] == -1) {
        // Attempt to insert the word without intersections
        for (int innerIndex = 0; innerIndex < words.length; innerIndex++) {
          if (words[innerIndex].containsKey('answer') &&
              !words[innerIndex].containsKey('startx')) {
            List<dynamic> temp = attemptToInsert(
                rows,
                cols,
                table,
                weights,
                verticalCount,
                totalCount,
                words[innerIndex]['answer'],
                innerIndex);
            if (temp[0] > best[0]) {
              best = temp;
            }
          }
        }
      }

      if (best[0] == -1) {
        break;
      } else {
        addWord(best, words, table);
        if (best[5] == 1) {
          verticalCount += 1;
        }
        totalCount += 1;
      }
    }

    for (int index = 0; index < words.length; index++) {
      if (!words[index].containsKey('startx')) {
        words[index]['orientation'] = "none";
      }
    }

    return {"table": table, "result": words};
  }

  Map<String, dynamic> removeIsolatedWords(Map<String, dynamic> data) {
    List<List<String>> oldTable = data['table'];
    List<Map<String, dynamic>> words = data['result'];
    int rows = oldTable.length;
    int cols = oldTable[0].length;
    List<List<String>> newTable = initTable(rows, cols);

    // Draw intersections as "X"'s
    for (int wordIndex = 0; wordIndex < words.length; wordIndex++) {
      var word = words[wordIndex];
      if (word['orientation'] == "across") {
        int i = (word['starty'].runtimeType == String
                ? int.parse(word['starty'])
                : word['starty']) -
            1;
        int j = (word['startx'].runtimeType == String
                ? int.parse(word['startx'])
                : word['startx']) -
            1;
        for (int k = 0; k < word['answer'].length; k++) {
          if (newTable[i][j + k] == "-") {
            newTable[i][j + k] = "O";
          } else if (newTable[i][j + k] == "O") {
            newTable[i][j + k] = "X";
          }
        }
      } else if (word['orientation'] == "down") {
        int i = (word['starty'].runtimeType == String
                ? int.parse(word['starty'])
                : word['starty']) -
            1;
        int j = (word['startx'].runtimeType == String
                ? int.parse(word['startx'])
                : word['startx']) -
            1;
        for (int k = 0; k < word['answer'].length; k++) {
          if (newTable[i + k][j] == "-") {
            newTable[i + k][j] = "O";
          } else if (newTable[i + k][j] == "O") {
            newTable[i + k][j] = "X";
          }
        }
      }
    }

    // Set orientations to "none" if they have no intersections
    for (int wordIndex = 0; wordIndex < words.length; wordIndex++) {
      var word = words[wordIndex];
      bool isIsolated = true;
      if (word['orientation'] == "across") {
        int i = (word['starty'].runtimeType == String
                ? int.parse(word['starty'])
                : word['starty']) -
            1;
        int j = (word['startx'].runtimeType == String
                ? int.parse(word['startx'])
                : word['startx']) -
            1;
        for (int k = 0; k < word['answer'].length; k++) {
          if (newTable[i][j + k] == "X") {
            isIsolated = false;
            break;
          }
        }
      } else if (word['orientation'] == "down") {
        int i = (word['starty'].runtimeType == String
                ? int.parse(word['starty'])
                : word['starty']) -
            1;
        int j = (word['startx'].runtimeType == String
                ? int.parse(word['startx'])
                : word['startx']) -
            1;
        for (int k = 0; k < word['answer'].length; k++) {
          if (newTable[i + k][j] == "X") {
            isIsolated = false;
            break;
          }
        }
      }
      if (word['orientation'] != "none" && isIsolated) {
        word.remove('startx');
        word.remove('starty');
        word.remove('position');
        word['orientation'] = "none";
      }
    }

    // Draw new table
    newTable = initTable(rows, cols);
    for (int wordIndex = 0; wordIndex < words.length; wordIndex++) {
      var word = words[wordIndex];
      if (word['orientation'] == "across") {
        int i = (word['starty'].runtimeType == String
                ? int.parse(word['starty'])
                : word['starty']) -
            1;
        int j = (word['startx'].runtimeType == String
                ? int.parse(word['startx'])
                : word['startx']) -
            1;
        for (int k = 0; k < word['answer'].length; k++) {
          newTable[i][j + k] = word['answer'][k];
        }
      } else if (word['orientation'] == "down") {
        int i = (word['starty'].runtimeType == String
                ? int.parse(word['starty'])
                : word['starty']) -
            1;
        int j = (word['startx'].runtimeType == String
                ? int.parse(word['startx'])
                : word['startx']) -
            1;
        for (int k = 0; k < word['answer'].length; k++) {
          newTable[i + k][j] = word['answer'][k];
        }
      }
    }

    return {"table": newTable, "result": words};
  }

  Map<String, dynamic> trimTable(Map<String, dynamic> data) {
    List<List<String>> table = data['table'];
    int rows = table.length;
    int cols = table[0].length;

    int leftMost = cols;
    int topMost = rows;
    int rightMost = -1;
    int bottomMost = -1;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (table[i][j] != "-") {
          int x = j;
          int y = i;

          if (x < leftMost) {
            leftMost = x;
          }
          if (x > rightMost) {
            rightMost = x;
          }
          if (y < topMost) {
            topMost = y;
          }
          if (y > bottomMost) {
            bottomMost = y;
          }
        }
      }
    }

    List<List<String>> trimmedTable =
        initTable(bottomMost - topMost + 1, rightMost - leftMost + 1);
    for (int i = topMost; i < bottomMost + 1; i++) {
      for (int j = leftMost; j < rightMost + 1; j++) {
        trimmedTable[i - topMost][j - leftMost] = table[i][j];
      }
    }

    List<Map<String, dynamic>> words = data['result'];
    for (int entry = 0; entry < words.length; entry++) {
      if (words[entry].containsKey('startx')) {
        words[entry]['startx'] -= leftMost;
        words[entry]['starty'] -= topMost;
      }
    }

    return {
      "table": trimmedTable,
      "result": words,
      "rows": max(bottomMost - topMost + 1, 0),
      "cols": max(rightMost - leftMost + 1, 0)
    };
  }

  String tableToString(List<List<String>> table, String delim) {
    int rows = table.length;
    if (rows >= 1) {
      int cols = table[0].length;
      String output = "";
      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
          output += table[i][j];
        }
        output += delim;
      }
      return output;
    } else {
      return "";
    }
  }

  Map<String, dynamic> generateSimpleTable(
      List<Map<String, dynamic>> words, bool isRemovingIsolatedWords) {
    int rows = computeDimension(words, 3);
    int cols = rows;
    List<List<String>> blankTable = initTable(rows, cols);
    Map<String, dynamic> table =
        generateTable(blankTable, rows, cols, words, [0.7, 0.15, 0.1, 0.05]);
    Map<String, dynamic> newTable =
        isRemovingIsolatedWords ? removeIsolatedWords(table) : table;
    Map<String, dynamic> finalTable = trimTable(newTable);
    assignPositions(finalTable['result']);
    return finalTable;
  }

  Map<String, dynamic> generateLayout(
      List<Map<String, dynamic>> wordsJson, bool isRemovingIsolatedWords) {
    Map<String, dynamic> layout =
        generateSimpleTable(wordsJson, isRemovingIsolatedWords);
    layout['table_string'] = tableToString(layout['table'], "<br>");
    return layout;
  }
}

class CrosswordConfig {
  final List<double> weights;
  final int sizeFactor;

  const CrosswordConfig(
      {this.weights = const [0.7, 0.15, 0.1, 0.05], this.sizeFactor = 3});
}
