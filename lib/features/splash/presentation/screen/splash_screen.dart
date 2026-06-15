import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/splash_bloc.dart';

/// Modern splash screen: animated logo, app name, and live initialization
/// progress. Calls [onInitialized] once startup succeeds.
class SplashScreen extends StatefulWidget {
  final VoidCallback onInitialized;
  const SplashScreen({super.key, required this.onInitialized});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: BlocConsumer<SplashBloc, SplashState>(
          listener: (context, state) {
            if (state.status == SplashStatus.success) {
              widget.onInitialized();
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome,
                                size: 64, color: Colors.white),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            AppConstants.appName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppConstants.appTagline,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 48, left: 48,
                        right: 48),
                    child: state.status == SplashStatus.failure
                        ? _FailureView(message: state.errorMessage)
                        : _ProgressView(state: state),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProgressView extends StatelessWidget {
  final SplashState state;
  const _ProgressView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: state.fraction == 0 ? null : state.fraction,
            backgroundColor: Colors.white24,
            color: Colors.white,
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 12),
        Text(state.stepLabel, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class _FailureView extends StatelessWidget {
  final String? message;
  const _FailureView({this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message ?? 'Something went wrong.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () =>
              context.read<SplashBloc>().add(const SplashStarted()),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}
