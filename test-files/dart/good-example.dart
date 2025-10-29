import 'package:flutter/foundation.dart';

class Calculator {
  double _result = 0.0;

  double add(double a, double b) {
    _result = a + b;
    return _result;
  }

  double divide(double a, double b) {
    if (b == 0.0) {
      throw ArgumentError('Division by zero');
    }
    
    _result = a / b;
    return _result;
  }
}

void main() {
  final calculator = Calculator();
  debugPrint('Result: ${calculator.add(5, 3)}');
}