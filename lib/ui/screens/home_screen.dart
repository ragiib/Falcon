import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../animations/particle_system.dart';
import '../animations/parallax_grid.dart';
import '../core_renderer/falcon_core.dart';
import '../chat/temporary_transcript.dart';
import '../hud/falcon_header.dart';
import '../hud/left_telemetry_stack.dart';
import '../hud/right_telemetry_stack.dart';
import '../hud/bottom_branding_bar.dart';
import '../theme/app_colors.dart';
import '../../providers/chat_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _debugTextController = TextEditingController();
  bool _showDebugInput = false;
  final FocusNode _focusNode = FocusNode();

  void _sendMessage() {
    final text = _debugTextController.text;
    if (text.trim().isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(text);
      _debugTextController.clear();
      setState(() {
        _showDebugInput = false;
      });
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (event) {
          if (event.character == 't' || event.character == '/') {
            if (!_showDebugInput) {
              setState(() {
                _showDebugInput = true;
              });
              _focusNode.requestFocus();
            }
          }
        },
        child: Stack(
          children: [
            // 1. Deep Space Atmosphere (Deep Graphite + Ambient Glow)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      AppColors.darkBackground,
                      AppColors.obsidian,
                    ],
                  ),
                ),
              ),
            ),

            // 2. Parallax Grid & Procedural Particles
            const Positioned.fill(child: ParallaxGridBackground()),
            const Positioned.fill(child: ParticleSystem(count: 35)),

            // 3. Central Radial Vignette
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [
                      Colors.transparent,
                      AppColors.obsidian.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Central Visual Focus: Falcon Arc Reactor Core
            const Positioned.fill(
              child: Center(
                child: FalconCore(size: 420),
              ),
            ),

            // 5. Left Telemetry Stack
            const Positioned(
              top: 70,
              bottom: 85,
              left: 12,
              child: LeftTelemetryStack(),
            ),

            // 6. Right Telemetry Stack
            const Positioned(
              top: 70,
              bottom: 85,
              right: 12,
              child: RightTelemetryStack(),
            ),

            // 7. Top System Header Bar
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FalconHeader(),
            ),

            // 8. Bottom Branding & Traffic Bar
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomBrandingBar(),
            ),

            // 9. Temporary Voice Response Overlay (Overlay above central core)
            const Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 550,
                  child: TemporaryTranscriptOverlay(),
                ),
              ),
            ),

            // 10. Debug Input Command Bar (Hidden by default, press / or T)
            if (_showDebugInput)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 500,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.cyanGlow),
                      boxShadow: [
                        BoxShadow(color: AppColors.cyanGlow.withOpacity(0.3), blurRadius: 15),
                      ],
                    ),
                    child: TextField(
                      controller: _debugTextController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: AppColors.cyanGlow, fontFamily: 'Share Tech Mono'),
                      decoration: const InputDecoration(
                        hintText: 'DEBUG COMMAND OVERRIDE...',
                        hintStyle: TextStyle(color: AppColors.textDisabled, fontFamily: 'Share Tech Mono'),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
