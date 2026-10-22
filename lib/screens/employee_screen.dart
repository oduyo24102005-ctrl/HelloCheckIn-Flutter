part of '../main.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() =>
      _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  List<dynamic> history = [];
  String workplace = 'Đang tải vị trí văn phòng...';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final data = await api('GET', 'attendance/mine');
      if (!mounted) return;
      setState(() => history = data is List ? data : []);

      try {
        final work = await api('GET', 'attendance/workplace');
        if (!mounted) return;
        setState(() => workplace = work is Map
            ? (work['name']?.toString() ?? 'Văn phòng nhóm Hello')
            : 'Văn phòng nhóm Hello');
      } catch (_) {
        if (!mounted) return;
        setState(() => workplace = 'Admin chưa thiết lập vị trí văn phòng');
      }
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    }
  }

  Future<void> checkIn() async {
    if (busy) return;

    // Quét QR trước khi lấy GPS
    final qrText = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanQRScreen(),
      ),
    );
    if (qrText == null || !mounted) return;

    setState(() => busy = true);

    try {
      final pos = await getGPS();

      final result = await api(
        'POST',
        'attendance/check-in',
        {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'qrText': qrText,
        },
      );

      if (mounted) {
        showMessage(context, (result is Map ? result['message']?.toString() : null) ?? 'Thao tác thành công');
        await refresh();
      }
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> checkOut() async {
    if (busy) return;
    setState(() => busy = true);

    try {
      final pos = await getGPS();

      final result = await api(
        'POST',
        'attendance/check-out',
        {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        },
      );

      if (mounted) {
        showMessage(context, (result is Map ? result['message']?.toString() : null) ?? 'Thao tác thành công');
        await refresh();
      }
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> explain(dynamic item) async {
    final reason = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Giải trình đi trễ'),
        content: TextField(
          controller: reason,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Nhập lý do đi trễ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              reason.text.trim(),
            ),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );

    // Dialog đã được đóng; giải phóng controller ở frame kế tiếp.
    WidgetsBinding.instance.addPostFrameCallback((_) => reason.dispose());

    if (text == null || text.isEmpty) return;

    try {
      await api('POST', 'attendance/explanation', {
        'attendanceRecordId': item['id'],
        'reason': text,
      });
      if (mounted) {
        showMessage(context, 'Đã gửi giải trình');
      }
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hello CheckIn - Nhân viên'),
        actions: [
          IconButton(
            onPressed: () {
              jwtToken = null;
              goTo(context, const LoginScreen());
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Xin chào, $fullName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.indigo,
                      size: 35,
                    ),
                    Text(workplace),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: busy ? null : checkIn,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text(
                        'CHẤM CÔNG VÀO - GPS + QR',
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: busy ? null : checkOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('CHẤM CÔNG RA'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.sensors,
                  color: Colors.indigo,
                ),
                title: const Text('Cảm biến chuyển động'),
                subtitle: const Text('Đo gia tốc điện thoại'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MotionScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'LỊCH SỬ CHẤM CÔNG',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Chưa có dữ liệu chấm công'),
              ),
            ...history.map(
                  (item) => Card(
                child: ListTile(
                  title: Text('Ngày: ${item['workDate']}'),
                  subtitle: Text(
                    'Vào: ${formatTime(item['checkInUtc'])}\n'
                        'Ra: ${formatTime(item['checkOutUtc'])}',
                  ),
                  trailing: item['isLate'] == true
                      ? TextButton(
                    onPressed: () => explain(item),
                    child: const Text('Giải trình'),
                  )
                      : const Icon(
                    Icons.check_circle,
                    color: Colors.green,
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

// ====================================
// QUÉT QR CODE
// ====================================

