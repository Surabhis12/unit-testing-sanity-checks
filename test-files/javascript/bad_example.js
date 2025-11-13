// hard-to-detect issues unless advanced lint rules are on

function processData(data) {
    // 1. == instead of === (type coercion bug)
    if (data == null) console.log("No data"); // passes default eslint, but can break logic

    // 2. Implicit global variable (forgot 'let' or 'const')
    total = 0; // creates global 'total' — not flagged without 'no-undef' or 'no-global-assign'

    // 3. for..in used on array instead of for..of
    const arr = [1, 2, 3];
    for (let i in arr) { // 'i' is a string, not number
        total += i * 2; // NaN logic bug
    }

    
    // 4. Misplaced semicolon after if
    if (data) ; {
        console.log("Always runs"); // block runs even if data is falsy
    }

    // 5. Comparing NaN incorrectly
    let value = NaN;
    if (value === NaN) console.log("NaN detected"); // never true

    // 6. Mutation of a const object
    const user = { name: "Nikhil" };
    user.name = "Changed"; // allowed, but misleading — const doesn't freeze object

    // 7. Silent integer overflow due to bitwise op
    let big = 1e12 | 0; // becomes 0 — bitwise ops convert to 32-bit signed integers

    // 8. Misused async without await
    async function fetchData() {
        Promise.resolve("done"); // missing await — silently returns unresolved promise
    }
    fetchData();

    // 9. == used again for tricky type coercion
    if ("0" == 0) total += 1; // true, but not intended

    // 10. Object comparison by reference
    let a = { x: 1 }, b = { x: 1 };
    if (a == b) console.log("Equal!"); // never true, even though looks same
}

processData({});
