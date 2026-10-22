
part of '../main.dart';

Future<dynamic> api(
    String method,
    String endpoint, [
      Object? body,
    ]) async {
  final url = Uri.parse('$apiUrl$endpoint');

  final headers = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (jwtToken != null && jwtToken!.isNotEmpty)
      'Authorization': 'Bearer $jwtToken',
  };

  try {
    late final http.Response response;

    switch (method.toUpperCase()) {
      case 'POST':
        response = await http
            .post(
          url,
          headers: headers,
          body: jsonEncode(body),
        )
            .timeout(const Duration(seconds: 20));
        break;

      case 'PUT':
        response = await http
            .put(
          url,
          headers: headers,
          body: jsonEncode(body),
        )
            .timeout(const Duration(seconds: 20));
        break;

      case 'DELETE':
        response = await http
            .delete(
          url,
          headers: headers,
        )
            .timeout(const Duration(seconds: 20));
        break;

      case 'GET':
        response = await http
            .get(
          url,
          headers: headers,
        )
            .timeout(const Duration(seconds: 20));
        break;

      default:
        throw Exception(
          'Phương thức HTTP không được hỗ trợ: $method',
        );
    }

    dynamic data;

    if (response.body.trim().isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        data = response.body;
      }
    }

    if (response.statusCode >= 400) {
      String? message;

      if (data is Map) {
        message = data['message']?.toString();

        if (message == null && data['errors'] is Map) {
          final errors = data['errors'] as Map;

          message = errors.entries
              .map((entry) {
            final value = entry.value;

            if (value is List) {
              return '${entry.key}: ${value.join(", ")}';
            }

            return '${entry.key}: $value';
          })
              .join('\n');
        }

        message ??= data['title']?.toString();
      }

      final fallback = switch (response.statusCode) {
        400 => 'Dữ liệu gửi lên không hợp lệ.',
        401 => 'Sai thông tin đăng nhập hoặc token hết hạn.',
        403 => 'Tài khoản không có quyền truy cập.',
        404 => 'Không tìm thấy API: $endpoint',
        500 => 'Backend gặp lỗi. Kiểm tra Visual Studio.',
        _ => 'Lỗi API HTTP ${response.statusCode}',
      };

      throw Exception(message ?? fallback);
    }

    return data;
  } on TimeoutException {
    throw Exception(
      'Kết nối API quá thời gian. Kiểm tra Backend cổng 5088.',
    );
  } on http.ClientException catch (error) {
    throw Exception(
      'Không kết nối được API: $error',
    );
  }
}
