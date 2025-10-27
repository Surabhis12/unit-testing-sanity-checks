package com.example.calculator

class Calculator {
    private var result: Double = 0.0

    fun add(a: Double, b: Double): Double {
        result = a + b
        return result
    }

    fun divide(a: Double, b: Double): Double {
        require(b != 0.0) { "Division by zero not allowed" }
        result = a / b
        return result
    }

    fun getResult(): Double = result
}

fun main() {
    val calculator = Calculator()
    val sum = calculator.add(5.0, 3.0)
    println("Result: $sum")
}