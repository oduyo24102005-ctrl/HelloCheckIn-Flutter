import 'package:flutter_test/flutter_test.dart';
import 'package:phamtheduy_hello_chamcong/main.dart';

void main() {
  testWidgets('Kiem tra giao dien Hello CheckIn', (tester) async {
    await tester.pumpWidget(const HelloCheckIn());

    expect(
      find.text('HELLO CHECKIN'),
      findsOneWidget,
    );

    expect(
      find.text('ĐĂNG NHẬP'),
      findsOneWidget,
    );
  });
}