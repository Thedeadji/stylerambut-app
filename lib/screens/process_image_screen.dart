import 'package:flutter/material.dart';

import '../services/hairstyle_analysis_service.dart';
import '../services/scan_feedback_service.dart';
import 'hairstyle_result_screen.dart';

class ProcessImageScreen extends StatefulWidget {
  const ProcessImageScreen({
    super.key,
    required this.imagePath,
    required this.faceRect,
  });

  final String imagePath;
  final Rect faceRect;

  static const backgroundColor = Color(0xFFFFC107);

  @override
  State<ProcessImageScreen> createState() => _ProcessImageScreenState();
}

class _ProcessImageScreenState extends State<ProcessImageScreen> {
  final HairstyleAnalysisService _analysisService = HairstyleAnalysisService();

  final Map<_ProcessStep, _StepStatus> _stepStatus = {};

  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    for (final step in _ProcessStep.values) {
      _stepStatus[step] = _StepStatus.pending;
    }
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    try {
      final result = await _analysisService.analyze(
        imagePath: widget.imagePath,
        faceRect: widget.faceRect,
        onStepStarted: (step) {
          if (!mounted) return;
          setState(() {
            _mapPipelineStep(step).forEach((processStep) {
              _stepStatus[processStep] = _StepStatus.inProgress;
            });
          });
        },
        onStepCompleted: (step) {
          if (!mounted) return;
          setState(() {
            _mapPipelineStep(step).forEach((processStep) {
              _stepStatus[processStep] = _StepStatus.completed;
            });
          });
        },
      );

      if (!mounted) return;
      await ScanFeedbackService.instance.playScanCompleteFeedback();
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HairstyleResultScreen(result: result),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Gagal memproses gambar.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  List<_ProcessStep> _mapPipelineStep(AnalysisPipelineStep step) {
    return switch (step) {
      AnalysisPipelineStep.landmarks => [_ProcessStep.landmarks],
      AnalysisPipelineStep.faceShape => [_ProcessStep.faceShape],
      AnalysisPipelineStep.hairDensity => [_ProcessStep.hairDensity],
      AnalysisPipelineStep.hairType => [_ProcessStep.hairType],
      AnalysisPipelineStep.preparing => [_ProcessStep.preparing],
    };
  }

  _StepStatus _statusFor(_ProcessStep step) {
    return _stepStatus[step] ?? _StepStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProcessImageScreen.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              SizedBox(
                width: 200,
                height: 200,
                child: _isProcessing
                    ? const CircularProgressIndicator(
                        strokeWidth: 14,
                        color: Colors.black,
                        backgroundColor: Colors.black12,
                      )
                    : const _LargeProgressRing(),
              ),
              const Spacer(flex: 2),
              Container(height: 1.5, color: Colors.black),
              const SizedBox(height: 28),
              _ProcessStepItem(
                label: 'Calculating Landmarks',
                status: _statusFor(_ProcessStep.landmarks),
              ),
              const SizedBox(height: 20),
              _ProcessStepItem(
                label: 'Face Shape',
                status: _statusFor(_ProcessStep.faceShape),
              ),
              const SizedBox(height: 20),
              _ProcessStepItem(
                label: 'Hairline Density',
                status: _statusFor(_ProcessStep.hairDensity),
              ),
              const SizedBox(height: 20),
              _ProcessStepItem(
                label: 'Hairline Type',
                status: _statusFor(_ProcessStep.hairType),
              ),
              const SizedBox(height: 20),
              _ProcessStepItem(
                label: 'Preparing',
                status: _statusFor(_ProcessStep.preparing),
              ),
              const Spacer(flex: 3),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Kembali',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ProcessStep { landmarks, faceShape, hairDensity, hairType, preparing }

enum _StepStatus { completed, inProgress, pending }

class _LargeProgressRing extends StatelessWidget {
  const _LargeProgressRing();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GradientArcPainter(strokeWidth: 14, sweepAngle: 4.8),
    );
  }
}

class _ProcessStepItem extends StatelessWidget {
  const _ProcessStepItem({required this.label, required this.status});

  final String label;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepIcon(status: status),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.status});

  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: switch (status) {
        _StepStatus.completed => Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: ProcessImageScreen.backgroundColor,
            size: 18,
          ),
        ),
        _StepStatus.inProgress => CustomPaint(
          painter: _GradientArcPainter(strokeWidth: 3, sweepAngle: 4.2),
        ),
        _StepStatus.pending => CustomPaint(
          painter: _GradientArcPainter(
            strokeWidth: 3,
            sweepAngle: 2.8,
            faded: true,
          ),
        ),
      },
    );
  }
}

class _GradientArcPainter extends CustomPainter {
  _GradientArcPainter({
    required this.strokeWidth,
    required this.sweepAngle,
    this.faded = false,
  });

  final double strokeWidth;
  final double sweepAngle;
  final bool faded;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -1.2,
        endAngle: sweepAngle,
        colors: faded
            ? [
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.45),
                Colors.black.withValues(alpha: 0.15),
              ]
            : [
                Colors.black.withValues(alpha: 0.2),
                Colors.black,
                Colors.black.withValues(alpha: 0.15),
              ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
