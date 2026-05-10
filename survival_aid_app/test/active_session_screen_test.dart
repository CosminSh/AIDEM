import 'package:flutter_test/flutter_test.dart';
import 'package:aidem_app/ui/screens/active_session_screen.dart';

void main() {
  group('quick reply detection', () {
    test('shows yes/no for true binary questions', () {
      expect(isBinaryYesNoQuestion('Are there any blisters?'), isTrue);
      expect(isBinaryYesNoQuestion('Can you move your finger?'), isTrue);
      expect(isBinaryYesNoQuestion('Is the bleeding stopped or not?'), isTrue);
    });

    test('does not show yes/no for either-or choice questions', () {
      expect(
        isBinaryYesNoQuestion('Does the pain feel sharp or dull?'),
        isFalse,
      );
      expect(
        isBinaryYesNoQuestion(
          'Is the skin only red, or are there blisters, numbness, white skin, or black skin?',
        ),
        isFalse,
      );
    });

    test('does not show yes/no for open questions', () {
      expect(isBinaryYesNoQuestion('What happened?'), isFalse);
      expect(isBinaryYesNoQuestion('Where are you?'), isFalse);
      expect(isBinaryYesNoQuestion('How bad is the pain?'), isFalse);
    });
  });
}
