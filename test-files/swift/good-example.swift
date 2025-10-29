import Foundation

class Calculator {
    private var result: Double = 0.0
    
    func add(_ a: Double, _ b: Double) -> Double {
        result = a + b
        return result
    }
    
    
    func divide(_ a: Double, _ b: Double) throws -> Double {
        guard b != 0 else {
            throw NSError(domain: "Calculator", code: 1)
        }
        result = a / b
        return result
    }
}

let calculator = Calculator()
print("Result: \(calculator.add(5, 3))")