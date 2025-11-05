// dart_tricky_errors.dart
// Subtle, real-world Dart bugs to test static analyzer configurations.

import 'dart:async';
import 'dart:math';

// 1) Late variable used before initialization
late int lateValue;
int computeLate() {
  // subtle: if never initialized, this throws at runtime
  return lateValue + 1;
}


// 2) Null dereference due to missing null check
void nullDereference(String? name) {
  print("Length: ${name.length}"); // 'name' could be null
}

// 3) Type inference confusion – dynamic vs Object
void dynamicMisuse() {
  var items = []; // List<dynamic>
  items.add(10);
  items.add("ten");
  int sum = items.fold(0, (a, b) => a + b); // runtime error
  print(sum);
}

// 4) Async function forgetting to await Future
Future<void> asyncError() async {
  Future<int> delayed = Future.delayed(Duration(milliseconds: 10), () => 42);
  int result;
  result = await delayed; // ok
  // subtle: forgot await, assigned Future<int> to int (no analyzer warning unless strict)
  int wrong = delayed as int; 
  print(wrong);
}

// 5) Unused Stream subscription (resource leak)
void leakStream() {
  final controller = StreamController<int>();
  controller.stream.listen((data) {
    print('Data: $data');
  }); // never canceled, leak in long-running app
  controller.add(10);
}

// 6) Integer division truncation bug
double average(int a, int b) {
  return (a + b) / 2; // might be int division if using ~/ somewhere incorrectly
}

// 7) Mutable default parameter (List reused across calls)
void addItem(String item, [List<String> store = const []]) {
  // const [] hides the bug; change to [] to trigger shared mutable default
  store.add(item); // modifying shared list across calls if not const
  print(store);
}

// 8) Wrong equality check (using '==' on doubles)
bool isAlmostEqual(double a, double b) => a == b; // precision issue

// 9) Future not awaited (fire-and-forget async)
Future<void> computeSomething() async {
  Future.delayed(Duration(seconds: 1), () => print('Done')); // unawaited future
}

// 10) Incorrect override (typo in method name)
class Animal {
  void speak() => print('Generic sound');
}

class Dog extends Animal {
  void speek() => print('Bark!'); // never overrides, silent bug
}

void main() {
  try {
    computeLate();
  } catch (e) {
    print("Late variable error: $e");
  }

  nullDereference(null);

  dynamicMisuse();

  asyncError();

  leakStream();

  print('Average(3,4): ${average(3, 4)}');

  addItem('apple');
  addItem('banana'); // reused default if const removed

  print('Equality: ${isAlmostEqual(0.1 + 0.2, 0.3)}');

  computeSomething();

  Dog().speek(); // typo silently breaks polymorphism
}
