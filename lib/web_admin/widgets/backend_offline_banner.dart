import 'package:flutter/material.dart';
import 'package:access_mobile/shared/api/backend_health.dart';
import 'package:access_mobile/shared/constants/api_config.dart';

/// Shown when FastAPI is not running on [ApiConfig.baseUrl].
class BackendOfflineBanner extends StatefulWidget {
  const BackendOfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  State<BackendOfflineBanner> createState() => _BackendOfflineBannerState();
}

class _BackendOfflineBannerState extends State<BackendOfflineBanner> {
  bool? _online;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
    });
    final ok = await BackendHealth.isReachable();
    if (mounted) {
      setState(() {
        _online = ok;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_checking)
          const LinearProgressIndicator(minHeight: 2)
        else if (_online == false)
          Material(
            color: const Color(0xFFFEE2E2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cloud_off, color: Color(0xFFB91C1C), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Backend offline',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB91C1C),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cannot reach ${ApiConfig.baseUrl}. Start the API first:',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          BackendHealth.startCommand,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Color(0xFF991B1B),
                          ),
                        ),
                        Text(
                          'Then open ${BackendHealth.healthUrl} in your browser.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _check,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (_online == true)
          const SizedBox.shrink(),
        Expanded(child: widget.child),
      ],
    );
  }
}
