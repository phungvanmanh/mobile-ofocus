import 'package:flutter_test/flutter_test.dart';

import 'package:ofocus/main.dart';

void main() {
  testWidgets('Login screen renders key copy', (WidgetTester tester) async {
    await tester.pumpWidget(const OFocusApp());
    await tester.pumpAndSettle();

    expect(find.text('Khởi đầu buổi học\nthông minh'), findsOneWidget);
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });
}
