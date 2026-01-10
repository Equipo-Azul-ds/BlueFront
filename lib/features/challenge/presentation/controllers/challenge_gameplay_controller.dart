import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:Trivvy/core/utils/countdown_service.dart';
import '../../application/dtos/single_player_dtos.dart';
import '../../domain/entities/single_player_game.dart';
import '../blocs/single_player_challenge_bloc.dart';

/// Manages gameplay state for a single-player challenge session.
/// 
/// Extracts slide management, countdown, and answer state from the screen,
/// leaving the UI layer to focus purely on presentation.
class ChallengeGameplayController extends ChangeNotifier {
  final SinglePlayerChallengeBloc _bloc;
  final CountdownService _countdown = CountdownService();
  
  // Slide state
  SlideDTO? _displayedSlide;
  SlideDTO? _pendingSlide;
  
  // Answer state
  final Set<int> _selectedIndexes = <int>{};
  bool _answerRevealed = false;
  bool _hasEvaluation = false;
  EvaluatedAnswer? _displayedEvaluated;
  
  // Countdown state
  int _timeRemaining = 0;
  DateTime? _countdownIssuedAt;
  
  // Callbacks
  VoidCallback? onReviewComplete;
  void Function(Object error)? onError;
  
  ChallengeGameplayController(this._bloc) {
    _bloc.addListener(_onBlocChanged);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public getters
  // ─────────────────────────────────────────────────────────────────────────
  
  SlideDTO? get displayedSlide => _displayedSlide;
  SlideDTO? get pendingSlide => _pendingSlide;
  Set<int> get selectedIndexes => Set.unmodifiable(_selectedIndexes);
  bool get answerRevealed => _answerRevealed;
  bool get hasEvaluation => _hasEvaluation;
  EvaluatedAnswer? get displayedEvaluated => _displayedEvaluated;
  int get timeRemaining => _timeRemaining;
  bool get isLoading => _bloc.isLoading && !_answerRevealed;
  SinglePlayerGame? get currentGame => _bloc.currentGame;
  SlideDTO? get blocCurrentSlide => _bloc.currentSlide;
  int? get lastCorrectIndex => _bloc.lastCorrectIndex;
  QuestionResult? get lastResult => _bloc.lastResult;
  
  /// Returns true if the UI should show the review overlay (answer submitted & evaluated).
  bool get canShowReviewUi => _answerRevealed && _hasEvaluation;
  
  /// Returns true if the current slide supports multiple answers.
  bool get isMultiSelect {
    final slide = _displayedSlide;
    if (slide == null) return false;
    return _supportsMultipleAnswers(slide);
  }
  
  /// Returns true if the multi-select submit button should be enabled.
  bool get canSubmitMulti => isMultiSelect && !_answerRevealed && _selectedIndexes.isNotEmpty;

  // ─────────────────────────────────────────────────────────────────────────
  // Public methods
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Initializes the gameplay session. Call from didChangeDependencies.
  Future<void> initialize({
    required String quizId,
    required String userId,
    SinglePlayerGame? resumeGame,
    SlideDTO? resumeSlide,
  }) async {
    try {
      if (resumeGame != null) {
        await _bloc.hydrateExistingGame(resumeGame, userId, nextSlide: resumeSlide);
      } else {
        await _bloc.startGame(quizId, userId);
      }
    } catch (error) {
      onError?.call(error);
    }
  }
  
  /// Toggles selection of an answer at [buttonIndex] for multi-select questions.
  void toggleSelection(int buttonIndex) {
    if (_answerRevealed) return;
    
    if (_selectedIndexes.contains(buttonIndex)) {
      _selectedIndexes.remove(buttonIndex);
    } else {
      _selectedIndexes.add(buttonIndex);
    }
    notifyListeners();
  }
  
  /// Submits a single answer (for single-select questions).
  Future<void> submitSingle(int buttonIndex) async {
    if (_answerRevealed) return;
    HapticFeedback.mediumImpact();
    _countdown.cancel();
    await _submitAnswer([buttonIndex]);
  }
  
  /// Submits all selected answers (for multi-select questions).
  Future<void> submitMultiple() async {
    if (_answerRevealed || _selectedIndexes.isEmpty) return;
    HapticFeedback.mediumImpact();
    _countdown.cancel();
    await _submitAnswer(_selectedIndexes.toList()..sort());
  }
  
  /// Called when time expires.
  void onTimeExpired() {
    if (_answerRevealed) return;
    
    if (_selectedIndexes.isEmpty) {
      _submitAnswer(null);
    } else {
      _submitAnswer(_selectedIndexes.toList()..sort());
    }
  }
  
  /// Called when the review animation completes.
  void onReviewAnimationComplete() {
    _applyPendingOrAdvance();
  }
  
  /// Maps a button index to the server's answer index.
  int? serverIndexForButton(SlideDTO slide, int buttonIndex) {
    if (buttonIndex < 0 || buttonIndex >= slide.options.length) {
      return null;
    }
    return slide.options[buttonIndex].index;
  }
  
  /// Maps a server answer index back to a button index.
  int? buttonIndexForServer(List<SlideOptionDTO> options, int? serverIndex) {
    if (serverIndex == null) return null;
    for (var i = 0; i < options.length; i++) {
      if (options[i].index == serverIndex) {
        return i;
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private methods
  // ─────────────────────────────────────────────────────────────────────────
  
  void _onBlocChanged() {
    final slide = _bloc.currentSlide;
    
    if (_answerRevealed) {
      _pendingSlide = slide;
      return;
    }

    _cancelTimers();
    _selectedIndexes.clear();
    _answerRevealed = false;
    _hasEvaluation = false;
    _displayedSlide = slide;
    
    notifyListeners();

    if (_displayedSlide != null) {
      _startCountdown(_displayedSlide!.timeLimitSeconds);
    }
  }
  
  void _startCountdown(int seconds) {
    _countdown.cancel();
    final issuedAt = DateTime.now();
    _countdownIssuedAt = issuedAt;
    _timeRemaining = _countdown.computeRemaining(
      issuedAt: issuedAt,
      timeLimitSeconds: seconds,
    );
    notifyListeners();
    
    _countdown.start(
      issuedAt: issuedAt,
      timeLimitSeconds: seconds,
      onTick: (remaining) {
        _timeRemaining = remaining;
        notifyListeners();
      },
      onElapsed: onTimeExpired,
    );
  }
  
  void _cancelTimers() {
    _countdown.cancel();
  }
  
  Future<void> _submitAnswer(List<int>? selectedIdxs) async {
    final currentDisplayed = _displayedSlide ?? _bloc.currentSlide;
    if (_bloc.currentGame == null || currentDisplayed == null) return;
    if (_answerRevealed) return;

    _countdown.cancel();

    final totalSeconds = currentDisplayed.timeLimitSeconds;
    final timeUsedSeconds = totalSeconds - _timeRemaining;
    final int rawElapsedMs = _countdownIssuedAt != null
        ? DateTime.now().difference(_countdownIssuedAt!).inMilliseconds
        : (timeUsedSeconds * 1000).round();
    final int timeUsedMs = rawElapsedMs.clamp(0, totalSeconds * 1000).toInt();
    
    final serverAnswerIndexes = selectedIdxs
        ?.map((idx) => serverIndexForButton(currentDisplayed, idx))
        .whereType<int>()
        .toList();
    final normalizedServerIndexes =
        serverAnswerIndexes == null || serverAnswerIndexes.isEmpty
            ? null
            : (serverAnswerIndexes..sort());

    final playerAnswer = PlayerAnswer(
      slideId: currentDisplayed.slideId,
      answerIndex: normalizedServerIndexes,
      timeUsedMs: timeUsedMs,
    );

    _selectedIndexes
      ..clear()
      ..addAll(selectedIdxs ?? const <int>[]);
    _answerRevealed = true;
    _hasEvaluation = false;
    _displayedEvaluated = null;
    notifyListeners();

    await _bloc.submitAnswer(playerAnswer);

    _displayedEvaluated = _bloc.lastResult?.evaluatedAnswer;
    _hasEvaluation = true;
    notifyListeners();
  }
  
  bool _supportsMultipleAnswers(SlideDTO slide) {
    final normalized = slide.questionType.trim().toLowerCase();
    const multiEnums = <String>{
      'multi_select',
      'multiple_select',
      'multiple_choice',
      'multiple_answer',
      'multiple_answers',
      'multi_answer',
      'multi_answers',
      'checkbox',
    };
    if (multiEnums.contains(normalized)) return true;
    return normalized.contains('multi') ||
        normalized.contains('multiple') ||
        normalized.contains('checkbox');
  }
  
  void _applyPendingOrAdvance() {
    final currentGame = _bloc.currentGame;

    if (_pendingSlide != null) {
      _displayedSlide = _pendingSlide;
      _pendingSlide = null;
      _selectedIndexes.clear();
      _answerRevealed = false;
      _hasEvaluation = false;
      notifyListeners();
      _startCountdown(_displayedSlide!.timeLimitSeconds);
      return;
    }

    final bool finished =
        currentGame == null ||
        currentGame.gameProgress.state == GameProgressStatus.COMPLETED ||
        _bloc.currentSlide == null;

    if (finished && currentGame != null) {
      onReviewComplete?.call();
      return;
    }

    _displayedSlide = _bloc.currentSlide;
    _selectedIndexes.clear();
    _answerRevealed = false;
    _hasEvaluation = false;
    notifyListeners();

    if (_displayedSlide != null) {
      _startCountdown(_displayedSlide!.timeLimitSeconds);
    }
  }

  @override
  void dispose() {
    _cancelTimers();
    _bloc.removeListener(_onBlocChanged);
    super.dispose();
  }
}
