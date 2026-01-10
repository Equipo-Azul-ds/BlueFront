import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/core/constants/colors.dart';
import 'package:Trivvy/core/constants/answer_option_palette.dart';
import 'package:Trivvy/core/widgets/answer_option_card.dart';
import 'package:Trivvy/core/widgets/animated_list_helpers.dart';
import 'package:Trivvy/core/widgets/animated_timer.dart';
import 'package:Trivvy/core/widgets/standard_dialogs.dart';
import 'package:Trivvy/core/widgets/game_ui_kit.dart';
import 'package:Trivvy/features/user/presentation/blocs/auth_bloc.dart';

import '../../application/dtos/single_player_dtos.dart';
import '../../domain/entities/single_player_game.dart';
import '../blocs/single_player_challenge_bloc.dart';
import '../controllers/challenge_gameplay_controller.dart';
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
      final authBloc = Provider.of<AuthBloc>(context, listen: false);
      final userId = authBloc.currentUser?.id ?? '';
      
      _controller = ChallengeGameplayController(bloc);
      _controller.addListener(_onControllerChanged);
      _controller.onReviewComplete = _navigateToResults;
      _controller.onError = _showErrorDialog;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.initialize(
          quizId: widget.quizId,
          userId: userId,
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
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildCountdown(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        slide.questionText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColor.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (slide.mediaUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildMedia(slide.mediaUrl!),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_controller.isMultiSelect && !_controller.answerRevealed) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Selecciona una o más opciones',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: _buildAnswerOptions(slide),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    return AnimatedTimer(timeRemaining: _controller.timeRemaining);
  }

  Widget _buildMedia(String mediaUrl) {
    Widget buildFallback() {
      return Container(
        height: 180,
        color: Colors.black.withValues(alpha: 0.1),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white70,
          ),
        ),
      );
    }

    final uri = Uri.tryParse(mediaUrl);
    final isRemote = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    final image = isRemote
        ? Image.network(
            mediaUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => buildFallback(),
          )
        : Image.asset(
            mediaUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => buildFallback(),
          );

    return image;
  }

  Widget _buildAnswerOptions(SlideDTO slide) {
    final answers = slide.options;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < 420 ? 1 : 2;
        final childAspectRatio = width < 420 ? 3.4 : 1.2;
        
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: answers.length,
          itemBuilder: (context, idx) {
            return _buildOption(slide, idx);
          },
        );
      },
    );
  }

  Widget _buildOption(SlideDTO slide, int idx) {
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

    return StaggeredFadeSlide(
      index: idx,
      duration: const Duration(milliseconds: 350),
      staggerDelay: const Duration(milliseconds: 60),
      child: AnswerOptionCard(
        text: ansText,
        icon: icon,
        color: backgroundColor,
        selected: isSelected,
        disabled: reveal,
        trailing: indicatorIcon != null ? Icon(indicatorIcon, size: 22) : null,
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
    );
  }

  Widget _buildSubmitButton() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 12,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _controller.canSubmitMulti
                    ? () => _controller.submitMultiple()
                    : null,
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  'Enviar (${_controller.selectedIndexes.length})',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.secundary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
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

