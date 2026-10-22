part of '../main.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<dynamic> employees = [];
  List<dynamic> attendance = [];
  List<dynamic> explanations = [];
  String? qrText;
  Timer? qrTimer;

  @override
  void initState() {
    super.initState();
    refresh();
    qrTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => loadQR(),
    );
  }

  @override
  void dispose() {
    qrTimer?.cancel();
    super.dispose();
  }

  Future<void> loadQR() async {
    try {
      final result = await api('GET', 'attendance/qr');
      if (mounted) {
        setState(() {
          qrText = result is Map ? result['qrText']?.toString() : null;
        });
      }
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    }
  }

  Future<void> refresh() async {
    try {
      final users = await api('GET', 'admin/employees');
      final records =
      await api('GET', 'admin/attendances');
      final notes =
      await api('GET', 'admin/explanations');

      if (!mounted) return;

      setState(() {
        employees = users as List;
        attendance = records as List;
        explanations = notes as List;
      });
      await loadQR();
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    }
  }

  Future<void> setWorkplace() async {
    try {
      final pos = await getGPS();

      final result = await api(
        'PUT',
        'admin/workplace',
        {
          'name': 'Văn phòng nhóm Hello',
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'radiusMeters': 150,
        },
      );

      if (mounted) {
        showMessage(context, (result is Map ? result['message']?.toString() : null) ?? 'Thao tác thành công');
      }
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    }
  }

  Future<void> createAttendance() async {
    if (employees.isEmpty) {
      showMessage(context, 'Chưa có nhân viên');
      return;
    }

    final employee = employees.first;
    final now = DateTime.now();
    final day =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    try {
      await api(
        'POST',
        'admin/attendances',
        {
          'userId': employee['id'],
          'workDate': day,
          'checkInUtc': now.toUtc().toIso8601String(),
          'checkOutUtc': null,
        },
      );
      if (mounted) showMessage(context, 'Đã thêm chấm công');
      await refresh();
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    }
  }

  Future<void> editAttendance(dynamic item) async {
    final oldTime = DateTime.tryParse(
      item['checkInUtc']?.toString() ?? '',
    )?.toLocal();
    if (oldTime == null) return;

    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(oldTime),
    );
    if (selected == null) return;

    final newTime = DateTime(
      oldTime.year,
      oldTime.month,
      oldTime.day,
      selected.hour,
      selected.minute,
    );

    try {
      await api(
        'PUT',
        "admin/attendances/${item['id']}",
        {
          'checkInUtc': newTime.toUtc().toIso8601String(),
          'checkOutUtc': item['checkOutUtc'],
        },
      );
      if (mounted) showMessage(context, 'Đã sửa giờ vào');
      await refresh();
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    }
  }

  Future<void> deleteAttendance(dynamic item) async {
    try {
      await api(
        'DELETE',
        "admin/attendances/${item['id']}",
      );
      if (mounted) showMessage(context, 'Đã xóa bản ghi');
      await refresh();
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    }
  }

  Future<void> decide(dynamic item, String status) async {
    try {
      await api(
        'PUT',
        "admin/explanations/${item['id']}",
        {'status': status},
      );
      await refresh();
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hello CheckIn - Admin'),
        actions: [
          IconButton(
            onPressed: refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              jwtToken = null;
              goTo(context, const LoginScreen());
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Xin chào Admin, $fullName',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text(
                    'MÃ QR CHẤM CÔNG',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (qrText != null)
                    QrImageView(
                      data: qrText!,
                      version: QrVersions.auto,
                      size: 210,
                      backgroundColor: Colors.white,
                    )
                  else
                    const Text('Chưa lấy được mã QR. Nhấn Làm mới QR.'),
                  TextButton(
                    onPressed: loadQR,
                    child: const Text('Làm mới QR'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: setWorkplace,
            icon: const Icon(Icons.location_on),
            label: const Text(
              'ĐẶT VỊ TRÍ VĂN PHÒNG TẠI ĐÂY',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nhân viên: ${employees.length}',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...employees.map(
                (item) => Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text('${item['fullName']}'),
                subtitle: Text('${item['email']}'),
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'QUẢN LÝ CHẤM CÔNG - CRUD',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          FilledButton.icon(
            onPressed: createAttendance,
            icon: const Icon(Icons.add),
            label: const Text(
              'Thêm chấm công cho nhân viên đầu tiên',
            ),
          ),
          ...attendance.map(
                (item) => Card(
              child: ListTile(
                title: Text('${item['fullName']}'),
                subtitle: Text(
                  '${item['workDate']}\n'
                      'Vào: ${formatTime(item['checkInUtc'])}  '
                      'Ra: ${formatTime(item['checkOutUtc'])}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => editAttendance(item),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () => deleteAttendance(item),
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'GIẢI TRÌNH ĐI TRỄ',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...explanations.map(
                (item) => Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('${item['reason']}'),
                    subtitle: Text('${item['status']}'),
                  ),
                  if (item['status'] == 'Pending')
                    Row(
                      children: [
                        TextButton(
                          onPressed: () =>
                              decide(item, 'Approved'),
                          child: const Text('Duyệt'),
                        ),
                        TextButton(
                          onPressed: () =>
                              decide(item, 'Rejected'),
                          child: const Text('Từ chối'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================
// CẢM BIẾN CHUYỂN ĐỘNG
// ====================================

