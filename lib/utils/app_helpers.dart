part of '../main.dart';

void showMessage(BuildContext context, String text) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text)),
  );
}

void goTo(BuildContext context, Widget page) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => page),
        (_) => false,
  );
}

String formatTime(dynamic value) {
  if (value == null) return '--:--';
  final date = DateTime.tryParse(value.toString());
  if (date == null) return '--:--';
  final local = date.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

Future<Position> getGPS() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception('Hãy bật GPS trên điện thoại');
  }

  var permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception('Ứng dụng chưa được cấp quyền vị trí');
  }

  return Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

