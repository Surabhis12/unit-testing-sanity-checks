package com.example.calculator

class Calculator {
    private var result: Double = 0.0

    fun add(a: Double, b: Double): Double {
        result = a + b
        return result
    }

    fun subtract(a: Double, b: Double): Double {
        result = a - b
        return result
    }
    

    fun multiply(a: Double, b: Double): Double {
        result = a * b
        return result
    }

    fun divide(a: Double, b: Double): Double {
        require(b != 0.0) { "Division by zero" }
        result = a / b
        return result
    }

    fun getResult(): Double = result

    fun reset() {
        result = 0.0
    }
}

fun main() {
    val calculator = Calculator()
    
    val sum = calculator.add(5.0, 3.0)
    println("5 + 3 = $sum")
    
    val diff = calculator.subtract(10.0, 4.0)
    println("10 - 4 = $diff")
    
    val product = calculator.multiply(6.0, 7.0)
    println("6 * 7 = $product")
    
    try {
        val quotient = calculator.divide(15.0, 3.0)
        println("15 / 3 = $quotient")
    } catch (e: IllegalArgumentException) {
        println("Error: ${e.message}")
    }
}