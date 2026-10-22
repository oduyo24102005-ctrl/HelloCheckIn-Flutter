part of '../main.dart';

class MotionScreen extends StatefulWidget {
  const MotionScreen({super.key});

  @override
  State<MotionScreen> createState() => _MotionScreenState();
}

class _MotionScreenState extends State<MotionScreen> {
  StreamSubscription<UserAccelerometerEvent>? sensor;
  double motion = 0;
  double maxMotion = 0;
  String status = 'Đang chờ cảm biến';

  @override
  void initState() {
    super.initState();

    sensor = userAccelerometerEventStream().listen(
          (event) {
        final value = math.sqrt(
          event.x * event.x +
              event.y * event.y +
              event.z * event.z,
        );

        if (!mounted) return;

        setState(() {
          motion = value;
          if (value > maxMotion) maxMotion = value;

          if (value < 0.4) {
            status = 'Điện thoại đang đứng yên';
          } else if (value < 2.5) {
            status = 'Chuyển động nhẹ';
          } else {
            status = 'Chuyển động mạnh';
          }
        });
      },
      onError: (Object error) {
        if (mounted) {
          setState(() => status = 'Lỗi cảm biến: $error');
        }
      },
    );
  }

  @override
  void dispose() {
    sensor?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cảm biến chuyển động'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.directions_run,
                color: Colors.indigo,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                '${motion.toStringAsFixed(2)} m/s²',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: (motion / 12).clamp(0, 1).toDouble(),
              ),
              const SizedBox(height: 15),
              Text(status),
              const SizedBox(height: 10),
              Text(
                'Gia tốc lớn nhất: '
                    '${maxMotion.toStringAsFixed(2)} m/s²',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
