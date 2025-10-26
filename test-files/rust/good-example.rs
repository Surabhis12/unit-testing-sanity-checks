pub struct Calculator {
    result: f64,
}

impl Calculator {
    pub fn new() -> Self {
        Calculator { result: 0.0 }
    }

    pub fn add(&mut self, a: f64, b: f64) -> f64 {
        self.result = a + b;
        self.result
    }

    pub fn divide(&mut self, a: f64, b: f64) -> Result<f64, String> {
        if b == 0.0 {
            return Err(String::from("Division by zero"));
        }
        self.result = a / b;
        Ok(self.result)
    }
}

fn main() {
    let mut calc = Calculator::new();
    let sum = calc.add(5.0, 3.0);
}