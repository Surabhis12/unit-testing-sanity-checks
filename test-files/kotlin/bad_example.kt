// Hard-to-detect Kotlin issues that static analyzers miss without strict rules

fun process(input: String?) {
    // 1. Unsafe call on nullable
    println(input!!.length) // will throw NPE if input is null, not flagged unless Detekt's "NullCheck" rules are on

    // 2. Unused variable (hidden dead code)
    val temp = calculateSomething() // result never used, needs 'unusedVariable' rule
    // no warning unless linting for unused values

    // 3. Shadowed variable
    var total = 10
    if (true) {
        val total = 5 // shadows outer variable silently
        println(total) // prints 5, but outer 'total' stays 10
    }

    // 4. Ignored return value
    listOf(1, 2, 3).map { it * 2 } // return ignored — useless call unless rule "ignoredReturnValue" is on

    // 5. Silent integer division pitfall
    val ratio = 3 / 2 // = 1, not 1.5 — both are Int
    println("Ratio: $ratio")

    // 6. Data class equality confusion
    data class User(val name: String)
    val a = User("Nik")
    val b = User("Nik")
    if (a === b) println("Same!") // reference equality, not structural; won't trigger static warning

    // 7. Suspicious empty when branch
    val x = 5
    when (x) {
        1 -> println("One")
        2 -> println("Two")
        else -> {} // does nothing silently
    }

    // 8. Non-exhaustive when on enum
    enum class Mode { ON, OFF }
    val mode = Mode.ON
    when (mode) {
        Mode.ON -> println("On!") // missing OFF — compiles because no 'else'
    }

    // 9. Mutating a var parameter (bad style, hidden logic bug)
    var counter = 0
    fun add() { counter++ }
    add(); add(); add()
    println("Counter = $counter")

    // 10. Using == on floating point values
    val f1 = 0.1 + 0.2
    val f2 = 0.3
    if (f1 == f2) println("Equal!") // false due to precision, but no warning without 'FloatingPointEquality' rule
}

fun calculateSomething(): Int {
    return (1..10).sum()
}

fun main() {
    process(null)
}
