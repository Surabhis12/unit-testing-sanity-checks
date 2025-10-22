#include <iostream>


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
            std::cerr << "Error: Division by zero!" << std::endl;
            return 0.0;
        }
        result = a / b;
        return result;
    }

    double getResult() const {
        return result;
    }
};

int main() {
    Calculator calc;
    
    std::cout << "Simple Calculator" << std::endl;
    std::cout << "5 + 3 = " << calc.add(5, 3) << std::endl;
    std::cout << "10 - 4 = " << calc.subtract(10, 4) << std::endl;
    std::cout << "6 * 7 = " << calc.multiply(6, 7) << std::endl;
    std::cout << "15 / 3 = " << calc.divide(15, 3) << std::endl;
    
    return 0;
}