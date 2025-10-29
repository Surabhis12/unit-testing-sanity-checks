#include <iostream>
#include <vector>
#include <memory>


class Calculator {
private:
    double result;


public:
    Calculator() : result(0.0) {}


    double add(double a, double b) {
        result = a + b;
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


int main() {
    Calculator calc;
   
    std::cout << "Calculator Test" << std::endl;
    std::cout << "5 + 3 = " << calc.add(5, 3) << std::endl;
    std::cout << "15 / 3 = " << calc.divide(15, 3) << std::endl;
   
    return 0;
}
