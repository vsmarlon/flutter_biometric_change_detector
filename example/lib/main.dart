//
//  Example App for FlutterBiometricChangeDetectorPlugin
//
//  Created by Nabraj Khadka on 12/02/2025.
//  Enhanced with ANR testing capabilities:
//  - Spinning animation to detect UI freezes
//  - Testing button
//  - Timing display
//
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:flutter_biometric_change_detector/flutter_biometric_change_detector.dart';
import 'package:flutter_biometric_change_detector/status_enum.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biometric Change Detector Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestHomePage(),
    );
  }
}

class TestHomePage extends StatefulWidget {
  const TestHomePage({super.key});

  @override
  State<TestHomePage> createState() => _TestHomePageState();
}

class _TestHomePageState extends State<TestHomePage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const int _stressTestCount = 5;

  AuthChangeStatus? _status;
  bool _isLoading = false;
  int _checkCount = 0;
  Duration? _lastDuration;
  String? _errorMessage;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Setup spinning animation - if this freezes, there's an issue
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      checkBiometric();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> checkBiometric() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final stopwatch = Stopwatch()..start();

    try {
      final status = await FlutterBiometricChangeDetector.checkBiometric();
      stopwatch.stop();

      setState(() {
        _status = status;
        _isLoading = false;
        _checkCount++;
        _lastDuration = stopwatch.elapsed;
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        _lastDuration = stopwatch.elapsed;
      });
    }
  }

  /// Stress test: run multiple concurrent checks
  Future<void> runStressTest() async {
    final futures = List.generate(_stressTestCount, (_) => checkBiometric());
    await Future.wait(futures);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkBiometric();
    }
  }

  Color _getStatusColor() {
    switch (_status) {
      case AuthChangeStatus.VALID:
        return Colors.green;
      case AuthChangeStatus.CHANGED:
        return Colors.orange;
      case AuthChangeStatus.INVALID:
        return Colors.red;
      case AuthChangeStatus.UNKNOWN:
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_status) {
      case AuthChangeStatus.VALID:
        return 'VALID - Biometric unchanged';
      case AuthChangeStatus.CHANGED:
        return 'CHANGED - Biometric was modified!';
      case AuthChangeStatus.INVALID:
        return 'INVALID - Biometric invalid';
      case AuthChangeStatus.UNKNOWN:
        return 'UNKNOWN';
      default:
        return 'Not checked yet';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Change Detector'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ANR Indicator Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    RotationTransition(
                      turns: _animationController,
                      child: const Icon(
                        Icons.refresh,
                        size: 40,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ANR Indicator',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'If this icon freezes during biometric check, there is an ANR issue.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getStatusColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Total checks: $_checkCount'),
                    if (_lastDuration != null)
                      Text(
                          'Last check duration: ${_lastDuration!.inMilliseconds}ms'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : checkBiometric,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fingerprint),
              label: Text(_isLoading ? 'Checking...' : 'Check Biometric'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _isLoading ? null : runStressTest,
              icon: const Icon(Icons.speed),
              label: const Text('Stress Test ($_stressTestCount concurrent)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const Spacer()
          ],
        ),
      ),
    );
  }
}
