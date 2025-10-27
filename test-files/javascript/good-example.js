
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