'use strict';
class Calculator {
    constructor() {
        this.result = 0;
    }
    add(a, b) {
        if (typeof a !== 'number' || typeof b !== 'number') {
            throw new TypeError('Arguments must be numbers');
        }
        this.result = a + b;
        return this.result;
    }
}
module.exports = Calculator;