'use strict';

const Calculator = {
    result: 0,
    
    add: function(a, b) {
        if (typeof a !== 'number' || typeof b !== 'number') {
            throw new TypeError('Arguments must be numbers');
        }
        this.result = a + b;
        return this.result;
    },
    
    divide: function(a, b) {
        if (b === 0) {
            throw new Error('Division by zero');
        }
        this.result = a / b;
        return this.result;
    }
};

module.exports = Calculator;