import 'package:flutter_test/flutter_test.dart';
import 'package:link26_app/features/auth/signup/signup_validators.dart';

void main() {
  test('isBirthYmd8 accepts valid date', () {
    expect(SignupValidators.isBirthYmd8('20040522'), isTrue);
    expect(SignupValidators.isBirthYmd8('20040230'), isFalse);
  });

  test('birthYmdMatchesRrn compares yyMMdd prefix', () {
    expect(
      SignupValidators.birthYmdMatchesRrn('20040522', '0405223123456'),
      isTrue,
    );
    expect(
      SignupValidators.birthYmdMatchesRrn('20040522', '9901013123456'),
      isFalse,
    );
  });
}
