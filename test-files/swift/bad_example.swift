// Hard-to-detect Swift issues — compiles fine, but logically broken or misleading

import Foundation

func processData(_ input: String?) {
    // 1. Force unwrapping optional (runtime crash if nil)
    print("Length:", input!.count) // passes unless 'force_unwrapping' lint is on

    // 2. Unused result from map
    [1, 2, 3].map { $0 * 2 } // return value ignored — no warning by default

    // 3. Implicitly unwrapped optional misuse
    var name: String! = "Nikhil"
    name = nil
    print(name.count) // crash, but analyzer won't warn unless strict mode


    // 4. Shadowing variable
    let data = "Hello"
    if true {
        let data = "World" // shadows silently
        print(data)
    }
    print(data) // prints original, subtle logic confusion

    // 5. Equality on floating-point values
    let x = 0.1 + 0.2
    if x == 0.3 {
        print("Equal!") // false due to precision, not flagged unless 'floating_point_equality' rule is on
    }

    // 6. Unowned reference capture — potential dangling pointer
    class Foo {
        var closure: (() -> Void)?
        func setClosure() {
            closure = { [unowned self] in
                print("Foo instance:", self)
            }
        }
    }

    do {
        let foo = Foo()
        foo.setClosure()
        // foo goes out of scope -> closure now references deallocated object
    }

    // 7. Wrong collection API
    let dict = ["a": 1, "b": 2]
    for k in dict { // iterates tuple, not key
        print(k.0) // subtle — needs advanced rule 'for_in_over_dictionary'
    }

    // 8. Mutable default argument trap
    func appendItem(_ item: Int, to list: inout [Int] = [1, 2, 3]) {
        list.append(item) // modifies shared default across calls
        print(list)
    }
    var myList = [1, 2]
    appendItem(4, to: &myList)
    appendItem(5) // modifies default argument unexpectedly

    // 9. String indexing bug
    let text = "Swift🦅"
    let idx = text.index(text.startIndex, offsetBy: 5) // off-by-one due to Unicode graphemes
    print(text[idx]) // runtime error, but static analyzer sees nothing

    // 10. Capturing self strongly in closure
    class Bar {
        var value = 0
        func start() {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                self.value += 1 // retain cycle, leaks Bar
            }
        }
    }
    Bar().start()
}

processData(nil)
