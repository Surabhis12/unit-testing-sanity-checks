

public class Calculator {
    private double result;

    public Calculator() {
        this.result = 0.0;
    }

    public double add(double a, double b) {
        result = a + b;
        return result;
    }

    public double divide(double a, double b) throws ArithmeticException {
        if (b == 0.0) {
            throw new ArithmeticException("Division by zero");
        }
        result = a / b;
        return result;
    }
}