import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// How sharp the photo needs to be.
enum PhotoQuality {
  /// To recognise something (a medicine photo): small and quick to upload.
  normal(ResolutionPreset.high),

  /// To read small print (a prescription, a report).
  document(ResolutionPreset.veryHigh);

  final ResolutionPreset preset;
  const PhotoQuality(this.preset);
}

/// Takes a photo with a camera inside the app and returns the file's path,
/// or null if the user went back.
///
/// The phone's own camera app is not used on purpose. Opening it puts a
/// second, heavy app on top of this one, and phones with little memory then
/// close one of the two: the user comes back to a frozen or restarted app
/// and the photo is lost. A camera inside the app needs far less memory and
/// nothing has to be handed back between apps.
Future<String?> takePhoto(
  BuildContext context, {
  PhotoQuality quality = PhotoQuality.normal,
}) {
  return Navigator.of(context, rootNavigator: true).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _CameraCapturePage(quality: quality),
    ),
  );
}

class _CameraCapturePage extends StatefulWidget {
  final PhotoQuality quality;
  const _CameraCapturePage({required this.quality});

  @override
  State<_CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<_CameraCapturePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _starting = true;
  bool _taking = false;
  bool _flashOn = false;

  /// Why the camera cannot be used; null while it works.
  String? _problem;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  /// The camera has to be given back while the app is in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final old = _controller;
      _controller = null;
      old?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _start();
    }
  }

  Future<void> _start() async {
    if (mounted) {
      setState(() {
        _starting = true;
        _problem = null;
      });
    }
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        // Start with the camera on the back of the phone.
        final back = _cameras.indexWhere(
            (c) => c.lensDirection == CameraLensDirection.back);
        _cameraIndex = back < 0 ? 0 : back;
      }
      if (_cameras.isEmpty) {
        throw CameraException('noCamera', 'No camera found');
      }
      final controller = CameraController(
        _cameras[_cameraIndex],
        widget.quality.preset,
        enableAudio: false, // photos only: no microphone permission
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await _controller?.dispose();
      _flashOn = false;
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {
        // A camera without a flash.
      }
      setState(() {
        _controller = controller;
        _starting = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _problem = e.code.toLowerCase().contains('denied') ||
                e.code.toLowerCase().contains('restricted')
            ? 'MediSathi is not allowed to use the camera. Allow it in your '
                    "phone's Settings, then try again."
                .tr
            : e.code == 'noCamera'
                ? 'This device has no camera.'.tr
                : 'Could not start the camera. Please try again.'.tr;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _problem = 'Could not start the camera. Please try again.'.tr;
      });
    }
  }

  Future<void> _take() async {
    final controller = _controller;
    if (controller == null || _taking || !controller.value.isInitialized) {
      return;
    }
    setState(() => _taking = true);
    try {
      final file = await controller.takePicture();
      if (mounted) Navigator.of(context).pop(file.path);
    } catch (_) {
      if (!mounted) return;
      setState(() => _taking = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not take the photo. Please try again.'.tr),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller
          .setFlashMode(_flashOn ? FlashMode.off : FlashMode.torch);
      setState(() => _flashOn = !_flashOn);
    } catch (_) {
      // No flash on this camera.
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _starting) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _start();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Close'.tr,
                  iconSize: 30,
                  color: Colors.white,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                if (ready)
                  IconButton(
                    tooltip: 'Light'.tr,
                    iconSize: 28,
                    color: Colors.white,
                    icon: Icon(_flashOn
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded),
                    onPressed: _toggleFlash,
                  ),
              ],
            ),
            Expanded(
              child: Center(
                child: _problem != null
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.no_photography_outlined,
                                size: 56, color: Colors.white70),
                            const SizedBox(height: 16),
                            Text(
                              _problem!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                minimumSize: const Size(160, 50),
                              ),
                              onPressed: _start,
                              child: Text('Try again'.tr),
                            ),
                          ],
                        ),
                      )
                    : ready
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CameraPreview(controller),
                          )
                        : const CircularProgressIndicator(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 56),
                  // A big round button: easy to hit with an unsteady hand.
                  Semantics(
                    button: true,
                    label: 'Take photo'.tr,
                    child: GestureDetector(
                      onTap: ready && !_taking ? _take : null,
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ready ? Colors.white : Colors.white30,
                          border: Border.all(color: Colors.white54, width: 5),
                        ),
                        child: _taking
                            ? const Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(
                                    strokeWidth: 3),
                              )
                            : const Icon(Icons.photo_camera_rounded,
                                size: 36, color: Colors.black87),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: _cameras.length > 1 && ready
                        ? IconButton(
                            tooltip: 'Switch camera'.tr,
                            iconSize: 30,
                            color: Colors.white,
                            icon: const Icon(Icons.cameraswitch_rounded),
                            onPressed: _switchCamera,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
