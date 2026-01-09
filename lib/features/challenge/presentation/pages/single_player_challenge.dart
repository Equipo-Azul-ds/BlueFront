import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';
import 'package:Trivvy/core/constants/answer_option_palette.dart';
import 'package:Trivvy/core/widgets/answer_option_card.dart';
import 'package:Trivvy/core/widgets/standard_dialogs.dart';
import 'package:Trivvy/core/widgets/game_ui_kit.dart';

import '../../application/dtos/single_player_dtos.dart';
import '../../domain/entities/single_player_game.dart';
import '../blocs/single_player_challenge_bloc.dart';
import '../controllers/challenge_gameplay_controller.dart';
import '../widgets/animated_countdown.dart';
import '../widgets/review_overlay.dart';
import 'single_player_challenge_results.dart';

/// Pantalla principal del modo desafío single-player.
/// 
/// Utiliza [ChallengeGameplayController] para gestión de estado,
/// manteniendo este widget enfocado puramente en presentación.
class SinglePlayerChallengeScreen extends StatefulWidget {
  final String quizId;
  final SinglePlayerGame? initialGame;
  final SlideDTO? initialSlide;

  const SinglePlayerChallengeScreen({
    super.key,
    required this.quizId,
    this.initialGame,
    this.initialSlide,
  });

  @override
  State<SinglePlayerChallengeScreen> createState() =>
      _SinglePlayerChallengeScreenState();
}

class _SinglePlayerChallengeScreenState
    extends State<SinglePlayerChallengeScreen> {
  late ChallengeGameplayController _controller;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final bloc = Provider.of<SinglePlayerChallengeBloc>(context, listen: false);
      _controller = ChallengeGameplayController(bloc);
      _controller.addListener(_onControllerChanged);
      _controller.onReviewComplete = _navigateToResults;
      _controller.onError = _showErrorDialog;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.initialize(
          quizId: widget.quizId,
          resumeGame: widget.initialGame,
          resumeSlide: widget.initialSlide,
        );
      });

      _initialized = true;
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _navigateToResults() {
    final game = _controller.currentGame;
    if (game == null || !mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SinglePlayerChallengeResultsScreen(
          gameId: game.gameId,
          initialSummaryGame: game,
        ),
      ),
    );
  }

  void _showErrorDialog(Object error) {
    if (!mounted) return;
    showBlockingErrorDialog(
      context: context,
      title: 'No se pudo iniciar el juego',
      message: '$error',
      onExit: () => Navigator.of(context).pop(),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _controller.displayedSlide ?? _controller.blocCurrentSlide;
    
    if (_controller.isLoading || slide == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Datos para el overlay de revisión
    final isTimeout = _controller.selectedIndexes.isEmpty && _controller.answerRevealed;
    final wasCorrect = _controller.displayedEvaluated?.wasCorrect ?? 
        (_controller.lastResult?.evaluatedAnswer.wasCorrect ?? false);
    final pointsEarned = _controller.displayedEvaluated?.pointsEarned ?? 
        (_controller.lastResult?.evaluatedAnswer.pointsEarned ?? 0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColor.secundary, AppColor.primary],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Contenido principal
            _buildMainContent(slide),
            
            // Botón de enviar (multi-select)
            if (_controller.isMultiSelect && !_controller.answerRevealed)
              _buildSubmitButton(),
            
            // Overlay de revisión (reemplaza la barra anterior)
            if (_controller.canShowReviewUi)
              Positioned.fill(
                child: ReviewOverlay(
                  wasCorrect: wasCorrect,
                  wasTimeout: isTimeout,
                  pointsEarned: pointsEarned,
                  onComplete: _controller.onReviewAnimationComplete,
                ),
              ),
            
            // Botón de salir (siempre visible, posición fija)
            _buildExitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(SlideDTO slide) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: 20,
              left: 12,
              right: 12,
              bottom: _controller.isMultiSelect ? 92 : 24,
            ),
            child: Column(
              key: ValueKey<String>(slide.slideId),
              children: [
                if (!_controller.answerRevealed) 
                  _buildCountdown(slide.timeLimitSeconds),
                const SizedBox(height: 14),
                _buildQuestionArea(slide.questionText),
                if (slide.mediaUrl != null) ...[
                  const SizedBox(height: 28),
                  _buildMedia(slide.mediaUrl!),
                ],
                const SizedBox(height: 18),
                if (_controller.isMultiSelect && !_controller.answerRevealed) ...[
                  Text(
                    'Selecciona una o más opciones',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _buildAnswerOptions(slide),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdown(int totalTime) {
    return AnimatedCountdown(
      timeRemaining: _controller.timeRemaining,
      totalTime: totalTime,
      warningThreshold: 5,
    );
  }

  Widget _buildQuestionArea(String questionText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Text(
          questionText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColor.primary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildMedia(String mediaUrl) {
    Widget buildFallback() {
      return Container(
        height: 160,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.broken_image)),
      );
    }

    final uri = Uri.tryParse(mediaUrl);
    final isRemote = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    final image = isRemote
        ? Image.network(
            mediaUrl,
            height: 360,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => buildFallback(),
          )
        : Image.asset(
            mediaUrl,
            height: 360,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => buildFallback(),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: image,
      ),
    );
  }

  Widget _buildAnswerOptions(SlideDTO slide) {
    final answers = slide.options;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final optionWidth = (availableWidth - 32) / (answers.length == 1 ? 1 : 2);
        
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 0,
          runSpacing: 0,
          children: List.generate(
            answers.length,
            (idx) => _buildOption(slide, idx, optionWidth),
          ),
        );
      },
    );
  }

  Widget _buildOption(SlideDTO slide, int idx, double optionWidth) {
    final answers = slide.options;
    final ansText = answers[idx].text ?? '';
    final baseColor = answerOptionColors[idx % answerOptionColors.length];
    final icon = answerOptionIcons[idx % answerOptionIcons.length];

    final isSelected = _controller.selectedIndexes.contains(idx);
    final reveal = _controller.answerRevealed;
    final correctIdx = _controller.buttonIndexForServer(
      answers,
      _controller.lastCorrectIndex,
    );
    final isCorrect = reveal && correctIdx != null && correctIdx == idx;

    Color backgroundColor = baseColor;
    IconData? indicatorIcon;
    if (reveal) {
      backgroundColor = isCorrect
          ? AppColor.success
          : (isSelected ? AppColor.error : baseColor);
      if (isCorrect) {
        indicatorIcon = Icons.check;
      } else if (isSelected) {
        indicatorIcon = Icons.close;
      }
    }

    return SizedBox(
      width: optionWidth,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AnswerOptionCard(
          layout: Axis.horizontal,
          text: ansText,
          icon: icon,
          color: backgroundColor,
          selected: isSelected,
          disabled: reveal,
          trailing: indicatorIcon != null ? Icon(indicatorIcon, size: 22) : null,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
          onTap: reveal
              ? null
              : () {
                  if (_controller.isMultiSelect) {
                    _controller.toggleSelection(idx);
                  } else {
                    _controller.submitSingle(idx);
                  }
                },
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: PrimaryButton(
              onPressed: _controller.canSubmitMulti
                  ? () => _controller.submitMultiple()
                  : null,
              icon: Icons.send_rounded,
              label: 'Enviar (${_controller.selectedIndexes.length})',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExitButton() {
    return Positioned(
      top: 10,
      right: 10,
      child: SafeArea(
        child: SecondaryButton(
          expanded: false,
          icon: Icons.exit_to_app_rounded,
          label: 'Salir',
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }
}
