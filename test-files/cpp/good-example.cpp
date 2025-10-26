// # Make sure you're on the branch with bad code
// git checkout test-bad-cpp-code

// # Replace the bad file with good code
// cat > test-files/cpp/test.cpp << 'EOF'
#include <iostream>
#include <vector>
#include <string>
#include <memory>

// Well-structured Calculator class with proper practices
class Calculator {
private:
    double result;

public:
    Calculator() : result(0.0) {}

    double add(double a, double b) {
        result = a + b;
        return result;
    }

    double subtract(double a, double b) {
        result = a - b;
        return result;
    }

    double multiply(double a, double b) {
        result = a * b;
        return result;
    }

    double divide(double a, double b) {
        if (b == 0.0) {
            throw std::invalid_argument("Division by zero");
        }
        result = a / b;
        return result;
    }

    double getResult() const {
        return result;
    }
};

// Helper function with proper error handling
std::vector<int> createArray(size_t size) {
    std::vector<int> arr(size);
    for (size_t i = 0; i < size; ++i) {
        arr[i] = static_cast<int>(i * 2);
    }
    return arr;
}

// String handling with safe functions
std::string safeStringCopy(const std::string& input) {
    std::string result = input;
    return result;
}

int main() {
    // Using smart pointers (no manual memory management)
    std::unique_ptr<Calculator> calc = std::make_unique<Calculator>();
    
    std::cout << "Calculator Demonstration" << std::endl;
    std::cout << "========================" << std::endl;
    
    // All variables are initialized
    double num1 = 10.0;
    double num2 = 5.0;
    
    std::cout << "Addition: " << num1 << " + " << num2 
              << " = " << calc->add(num1, num2) << std::endl;
    
    std::cout << "Subtraction: " << num1 << " - " << num2 
              << " = " << calc->subtract(num1, num2) << std::endl;
    
    std::cout << "Multiplication: " << num1 << " * " << num2 
              << " = " << calc->multiply(num1, num2) << std::endl;
    
    try {
        std::cout << "Division: " << num1 << " / " << num2 
                  << " = " << calc->divide(num1, num2) << std::endl;
    } catch (const std::invalid_argument& e) {
        std::cerr << "Error: " << e.what() << std::endl;
    }
    
    // Using safe vector instead of raw arrays
    std::vector<int> numbers = createArray(5);
    std::cout << "\nArray values: ";
    for (const auto& num : numbers) {
        std::cout << num << " ";
    }
    std::cout << std::endl;
    
    // Safe string handling
    std::string testString = "Hello, World!";
    std::string copiedString = safeStringCopy(testString);
    std::cout << "String: " << copiedString << std::endl;
    
    return 0;
}
// EOF

// # Commit and push
// git add test-files/cpp/test.cpp
// git commit -m "Fix: Replace bad code with clean, well-structured code

// Changes:
// - Removed memory leaks (using smart pointers)
// - Removed unsafe strcpy (using std::string)
// - Initialized all variables
// - Removed gets() usage
// - Added proper error handling
// - Used safe C++ practices"

// git push origin test-bad-cpp-code