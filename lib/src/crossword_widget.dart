import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ====================== DATA MODELS ======================
enum Orientation { horizontal, vertical }

class CrosswordPosition {
  final int row;
  final int col;

  const CrosswordPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrosswordPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

class CrosswordWord {
  final String answer;
  final String clue;
  final Orientation orientation;
  final CrosswordPosition start;
  bool isCompleted;

  CrosswordWord({
    required this.answer,
    required this.clue,
    required this.orientation,
    required this.start,
    this.isCompleted = false,
  });
}

class CrosswordCell {
  final CrosswordPosition position;
  final String correctValue;
  String userValue;
  bool isSelected;
  bool isHighlighted;
  bool isRevealed;

  CrosswordCell({
    required this.position,
    required this.correctValue,
    this.userValue = '',
    this.isSelected = false,
    this.isHighlighted = false,
    this.isRevealed = false,
  });

  String get displayValue =>
      isRevealed ? correctValue.toUpperCase() : userValue.toUpperCase();
  bool get isEmpty => correctValue.isEmpty;
  bool get isFilled => userValue.isNotEmpty || isRevealed;
  bool get isCorrect => userValue.toLowerCase() == correctValue.toLowerCase();
}

// ====================== PUZZLE LOGIC ======================
class CrosswordPuzzle with ChangeNotifier {
  final List<CrosswordWord> words;
  late List<List<CrosswordCell>> grid;
  CrosswordPosition? _selectedPosition;
  Orientation _currentOrientation = Orientation.horizontal;
  final Set<CrosswordPosition> _revealedCells = {};

  CrosswordPuzzle({required this.words}) {
    _generateGrid();
  }

  void _generateGrid() {
    // Initial grid generation logic (simplified)
    final size = _calculateGridSize();
    grid = List.generate(
        size,
        (row) => List.generate(
            size,
            (col) => CrosswordCell(
                  position: CrosswordPosition(row, col),
                  correctValue: '',
                )));

    // Place words in grid (implementation details would go here)
    for (final word in words) {
      _placeWordInGrid(word);
    }
  }

  void _placeWordInGrid(CrosswordWord word) {
    final letters = word.answer.split('');
    final start = word.start;

    for (var i = 0; i < letters.length; i++) {
      final pos = word.orientation == Orientation.horizontal
          ? CrosswordPosition(start.row, start.col + i)
          : CrosswordPosition(start.row + i, start.col);

      if (_isValidPosition(pos)) {
        grid[pos.row][pos.col] = CrosswordCell(
          position: pos,
          correctValue: letters[i],
        );
      }
    }
  }

  bool _isValidPosition(CrosswordPosition pos) =>
      pos.row >= 0 &&
      pos.row < grid.length &&
      pos.col >= 0 &&
      pos.col < grid[0].length;

  int _calculateGridSize() =>
      words.fold(0,
          (max, word) => word.answer.length > max ? word.answer.length : max) *
      2;

  void selectCell(CrosswordPosition position) {
    _clearSelection();
    _selectedPosition = position;
    _updateOrientation();
    _highlightWord();
    notifyListeners();
  }

  void _clearSelection() {
    for (final row in grid) {
      for (final cell in row) {
        cell.isSelected = false;
        cell.isHighlighted = false;
      }
    }
  }

  void _updateOrientation() {
    final currentCell = currentSelectedCell;
    if (currentCell == null) return;

    final horizontalWord =
        _getWordAt(currentCell.position, Orientation.horizontal);
    final verticalWord = _getWordAt(currentCell.position, Orientation.vertical);

    if (horizontalWord != null && verticalWord != null) {
      _currentOrientation = _currentOrientation == Orientation.horizontal
          ? Orientation.vertical
          : Orientation.horizontal;
    } else if (horizontalWord != null) {
      _currentOrientation = Orientation.horizontal;
    } else if (verticalWord != null) {
      _currentOrientation = Orientation.vertical;
    }
  }

  void _highlightWord() {
    final word = currentWord;
    if (word == null) return;

    final positions = _getWordPositions(word);
    for (final pos in positions) {
      grid[pos.row][pos.col].isHighlighted = true;
    }
  }

  CrosswordWord? get currentWord {
    final pos = _selectedPosition;
    if (pos == null) return null;
    return _getWordAt(pos, _currentOrientation);
  }

  CrosswordWord? _getWordAt(CrosswordPosition pos, Orientation orientation) {
    for (final word in words) {
      if (word.orientation != orientation) continue;

      final start = word.start;
      final end = orientation == Orientation.horizontal
          ? CrosswordPosition(start.row, start.col + word.answer.length - 1)
          : CrosswordPosition(start.row + word.answer.length - 1, start.col);

      if (orientation == Orientation.horizontal) {
        if (pos.row == start.row &&
            pos.col >= start.col &&
            pos.col <= end.col) {
          return word;
        }
      } else {
        if (pos.col == start.col &&
            pos.row >= start.row &&
            pos.row <= end.row) {
          return word;
        }
      }
    }
    return null;
  }

  List<CrosswordPosition> _getWordPositions(CrosswordWord word) {
    final positions = <CrosswordPosition>[];
    final start = word.start;

    for (var i = 0; i < word.answer.length; i++) {
      final pos = word.orientation == Orientation.horizontal
          ? CrosswordPosition(start.row, start.col + i)
          : CrosswordPosition(start.row + i, start.col);

      if (_isValidPosition(pos)) {
        positions.add(pos);
      }
    }
    return positions;
  }

  void revealCurrentCell() {
    final cell = currentSelectedCell;
    if (cell != null && !cell.isRevealed) {
      cell.isRevealed = true;
      _revealedCells.add(cell.position);
      _validateWordCompletion();
      notifyListeners();
    }
  }

  void _validateWordCompletion() {
    for (final word in words) {
      final positions = _getWordPositions(word);
      final allRevealed =
          positions.every((pos) => _revealedCells.contains(pos));
      word.isCompleted = allRevealed ||
          positions.every((pos) => grid[pos.row][pos.col].isCorrect);
    }
    notifyListeners();
  }

  CrosswordCell? get currentSelectedCell => _selectedPosition != null
      ? grid[_selectedPosition!.row][_selectedPosition!.col]
      : null;

  void updateCellValue(String value) {
    final cell = currentSelectedCell;
    if (cell != null && !cell.isRevealed && value.isNotEmpty) {
      cell.userValue = value[0];
      _validateWordCompletion();
      _moveToNextCell();
      notifyListeners();
    }
  }

  void _moveToNextCell() {
    final word = currentWord;
    if (word == null || _selectedPosition == null) return;

    final positions = _getWordPositions(word);
    final currentIndex = positions.indexWhere((p) => p == _selectedPosition!);

    if (currentIndex != -1 && currentIndex < positions.length - 1) {
      selectCell(positions[currentIndex + 1]);
    }
  }
}

// ====================== WIDGET IMPLEMENTATION ======================
class CrosswordWidget extends StatefulWidget {
  final List<CrosswordWord> words;
  final CrosswordStyle style;
  final VoidCallback? onComplete;

  const CrosswordWidget({
    Key? key,
    required this.words,
    this.style = const CrosswordStyle(),
    this.onComplete,
  }) : super(key: key);

  @override
  _CrosswordWidgetState createState() => _CrosswordWidgetState();
}

class _CrosswordWidgetState extends State<CrosswordWidget> {
  late CrosswordPuzzle _puzzle;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _puzzle = CrosswordPuzzle(words: widget.words);
    _puzzle.addListener(_onPuzzleUpdate);
    _setupInputHandling();
  }

  void _setupInputHandling() {
    _inputController.addListener(() {
      if (_inputController.text.isNotEmpty) {
        _puzzle.updateCellValue(_inputController.text);
        _inputController.clear();
      }
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        RawKeyboard.instance.addListener(_handleKeyEvent);
      } else {
        RawKeyboard.instance.removeListener(_handleKeyEvent);
      }
    });
  }

  void _onPuzzleUpdate() {
    if (_puzzle.words.every((word) => word.isCompleted)) {
      widget.onComplete?.call();
    }
    setState(() {});
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _moveSelection(-1, 0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _moveSelection(1, 0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _moveSelection(0, -1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moveSelection(0, 1);
      } else if (event.logicalKey == LogicalKeyboardKey.tab) {
        _toggleOrientation();
      }
    }
  }

  void _moveSelection(int colDelta, int rowDelta) {
    final current = _puzzle._selectedPosition;
    if (current == null) return;

    final newRow = (current.row + rowDelta).clamp(0, _puzzle.grid.length - 1);
    final newCol =
        (current.col + colDelta).clamp(0, _puzzle.grid[0].length - 1);
    _puzzle.selectCell(CrosswordPosition(newRow, newCol));
  }

  void _toggleOrientation() {
    final current = _puzzle._currentOrientation;
    _puzzle._currentOrientation = current == Orientation.horizontal
        ? Orientation.vertical
        : Orientation.horizontal;
    _puzzle._highlightWord();
    _puzzle.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      focusNode: _focusNode,
      autofocus: true,
      shortcuts: _keyboardShortcuts,
      actions: _keyboardActions,
      child: Stack(
        children: [
          Column(
            children: [
              _buildGrid(),
              _buildDescription(),
            ],
          ),
          // Hidden text field for keyboard input
          Positioned(
            left: -100,
            child: Opacity(
              opacity: 0,
              child: TextField(
                focusNode: _focusNode,
                controller: _inputController,
                autofocus: false,
                maxLength: 1,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<LogicalKeySet, Intent> get _keyboardShortcuts => {
        LogicalKeySet(LogicalKeyboardKey.arrowLeft):
            const DirectionalFocusIntent(TraversalDirection.left),
        LogicalKeySet(LogicalKeyboardKey.arrowRight):
            const DirectionalFocusIntent(TraversalDirection.right),
        LogicalKeySet(LogicalKeyboardKey.arrowUp):
            const DirectionalFocusIntent(TraversalDirection.up),
        LogicalKeySet(LogicalKeyboardKey.arrowDown):
            const DirectionalFocusIntent(TraversalDirection.down),
        LogicalKeySet(LogicalKeyboardKey.tab): const ActivateIntent(),
      };

  Map<Type, Action<Intent>> get _keyboardActions => {
        ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _toggleOrientation()),
      };

  Widget _buildGrid() {
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.8,
      maxScale: 2.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = _calculateCellSize(constraints);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _puzzle.grid.length,
              childAspectRatio: cellSize.width / cellSize.height,
            ),
            itemCount: _puzzle.grid.length * _puzzle.grid.length,
            itemBuilder: (context, index) => _buildCell(index),
          );
        },
      ),
    );
  }

  Size _calculateCellSize(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth / _puzzle.grid.length;
    return Size(maxWidth, maxWidth);
  }

  Widget _buildCell(int index) {
    final row = index ~/ _puzzle.grid.length;
    final col = index % _puzzle.grid.length;
    final cell = _puzzle.grid[row][col];

    return GestureDetector(
      onTap: () {
        _puzzle.selectCell(cell.position);
        _focusNode.requestFocus();
        // Show keyboard explicitly
        SystemChannels.textInput.invokeMethod('TextInput.show');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          border: Border.all(
            color: cell.isSelected
                ? widget.style.selectedBorderColor
                : widget.style.gridColor,
            width: cell.isSelected ? 2 : 1,
          ),
          color: _getCellColor(cell),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              cell.displayValue,
              key: ValueKey(cell.displayValue),
              style: widget.style.cellTextStyle,
            ),
          ),
        ),
      ),
    );
  }

  Color _getCellColor(CrosswordCell cell) {
    if (cell.isSelected) return widget.style.selectedColor;
    if (cell.isHighlighted) return widget.style.highlightColor;
    if (cell.isRevealed) return widget.style.revealedColor;
    if (cell.isCorrect) return widget.style.correctColor;
    return widget.style.backgroundColor;
  }

  Widget _buildDescription() {
    final currentWord = _puzzle.currentWord;
    if (currentWord == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Clue (${currentWord.orientation.toString().split('.').last}):',
                style: widget.style.clueHeaderStyle,
              ),
              const SizedBox(height: 8),
              Text(
                currentWord.clue,
                style: widget.style.clueTextStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _puzzle.removeListener(_onPuzzleUpdate);
    _focusNode.dispose();
    _inputController.dispose();
    super.dispose();
  }
}

// ====================== STYLE CONFIGURATION ======================
class CrosswordStyle {
  final Color backgroundColor;
  final Color gridColor;
  final Color selectedColor;
  final Color selectedBorderColor;
  final Color highlightColor;
  final Color revealedColor;
  final Color correctColor;
  final TextStyle cellTextStyle;
  final TextStyle clueHeaderStyle;
  final TextStyle clueTextStyle;

  const CrosswordStyle({
    this.backgroundColor = Colors.white,
    this.gridColor = Colors.black54,
    this.selectedColor =
        const Color(0x1A0000FF), // Predefined color with opacity
    this.selectedBorderColor = Colors.blue,
    this.highlightColor = const Color.fromRGBO(0, 0, 255, 0.05),
    this.revealedColor = const Color.fromRGBO(0, 255, 0, 0.2),
    this.correctColor = const Color.fromRGBO(0, 255, 0, 0.1),
    this.cellTextStyle =
        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    this.clueHeaderStyle =
        const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    this.clueTextStyle = const TextStyle(fontSize: 16),
  });
}
