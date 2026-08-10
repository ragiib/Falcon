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
import '../hud/hud_vector_overlay.dart';
import '../theme/app_colors.dart';
import '../../providers/chat_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _debugTextController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();
  bool _showDebugInput = false;

  @override
  void initState() {
    super.initState();
    // Ensure keyboard focus node requests focus once mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debugTextController.dispose();
    _inputFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _debugTextController.text;
    if (text.trim().isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(text);
      _debugTextController.clear();
      setState(() {
        _showDebugInput = false;
      });
      // Permanently restore keyboard listener focus after sending message
      _keyboardFocusNode.requestFocus();
    }
  }

  void _toggleInput() {
    setState(() {
      _showDebugInput = !_showDebugInput;
    });
    if (_showDebugInput) {
      _inputFocusNode.requestFocus();
    } else {
      _keyboardFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event.character == 't' || event.character == '/') {
            if (!_showDebugInput) {
              _toggleInput();
            }
          } else if (event.character == 'v') {
            // Hotkey 'V' activates Falcon Voice Assistant greeting ("Falcon")
            final currentState = ref.read(aiStateProvider);
            if (currentState == AiState.wakeWordDetection || currentState == AiState.returningToSleep) {
              ref.read(chatProvider.notifier).activateVoiceAssistant();
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
            const Positioned.fill(child: ParticleSystem(count: 45)),

            // 3. Central Visual Focus: Large Falcon Arc Reactor Core (560px diameter ~75% vertical screen height)
            Positioned.fill(
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    // Tap on central Arc Reactor activates Falcon Voice Assistant
                    debugPrint("[ACTIVATION TRACE] UI TAP RECEIVED on FalconCore Arc Reactor");
                    final currentState = ref.read(aiStateProvider);
                    debugPrint("[ACTIVATION TRACE] Function: home_screen.onTap() | State: $currentState");
                    ref.read(chatProvider.notifier).activateVoiceAssistant();
                  },
                  child: const FalconCore(size: 560),
                ),
              ),
            ),

            // 4. Procedural Vector Overlay (Full-Bleed Axis Line & Angled Callouts)
            const Positioned.fill(
              child: HudVectorOverlay(),
            ),

            // 5. Left Telemetry Stack (High density)
            const Positioned(
              top: 60,
              bottom: 65,
              left: 10,
              child: LeftTelemetryStack(),
            ),

            // 6. Right Telemetry Stack (High density)
            const Positioned(
              top: 60,
              bottom: 65,
              right: 10,
              child: RightTelemetryStack(),
            ),

            // 7. Top System Header Bar
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FalconHeader(),
            ),

            // 8. Bottom Branding Logo Bar
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomBrandingBar(),
            ),

            // 9. Temporary Voice Response Transcript Overlay
            const Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 550,
                  child: TemporaryTranscriptOverlay(),
                ),
              ),
            ),

            // 10. Debug Input Command Bar (Press / or T, tap Core, or press V)
            if (_showDebugInput)
              Positioned(
                bottom: 75,
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
                      focusNode: _inputFocusNode,
                      style: const TextStyle(color: AppColors.cyanGlow, fontFamily: 'Share Tech Mono'),
                      decoration: const InputDecoration(
                        hintText: 'DEBUG COMMAND OVERRIDE (PRESS ESC OR ENTER TO CLOSE)...',
                        hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 10, fontFamily: 'Share Tech Mono'),
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
