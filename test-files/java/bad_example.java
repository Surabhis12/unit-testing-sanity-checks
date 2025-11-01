// TrickyBugs.java
// Subtle, real-world Java errors meant to stress static analyzers.
// Compile: javac TrickyBugs.java

import java.util.*;
import java.io.*;

class TrickyBugs {

    // 1) Null dereference after conditional (NP_ALWAYS_NULL)
    static void nullDereference() {
        String s = null;
        if (s == null) {
            System.out.println("Null string!");
        }
        System.out.println(s.length()); // potential NullPointerException
    }

    // 2) Unclosed resource (RESOURCE_LEAK)
    static void leakFile() throws IOException {
        BufferedReader br = new BufferedReader(new FileReader("nonexistent.txt"));
        String line = br.readLine();
        System.out.println(line);
        // forgot br.close();
    }

    // 3) Infinite recursion (INFINITE_RECURSION)
    static int factorial(int n) {
        if (n <= 1) return 1;
        return n * factorial(n); // wrong recursive call (should be n-1)
    }

    // 4) Using == instead of .equals() (EQ_CHECK_FOR_REFERENCE)
    static void stringCompare() {
        String a = new String("hello");
        String b = new String("hello");
        if (a == b) { // wrong comparison
            System.out.println("Equal!");
        }
    }

    // 5) Unsynchronized access to static mutable field (THREAD_SAFETY_VIOLATION)
    private static List<String> sharedList = new ArrayList<>();
    static void unsafeThread() {
        new Thread(() -> sharedList.add("A")).start();
        new Thread(() -> sharedList.add("B")).start();
    }

    // 6) Ignored return value (RESULT_IGNORED)
    static void ignoredReturn() {
        "Test".replace("t", "T"); // ignored result
    }

    // 7) Double-checked locking without volatile (DC_DOUBLECHECK)
    private static TrickyBugs instance;
    static TrickyBugs getInstance() {
        if (instance == null) {
            synchronized (TrickyBugs.class) {
                if (instance == null) {
                    instance = new TrickyBugs(); // missing volatile -> unsafe publication
                }
            }
        }
        return instance;
    }

    // 8) Integer overflow / boundary bug (INT_OVERFLOW)
    static void overflow() {
        int big = Integer.MAX_VALUE;
        int result = big + 1; // wraps to negative
        System.out.println("Result: " + result);
    }

    // 9) Suspicious equals() override without hashCode() (EQ_COMPARETO_USE_OBJECT_EQUALS)
    static class Person {
        String name;
        Person(String n) { name = n; }
        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Person)) return false;
            return Objects.equals(name, ((Person)o).name);
        }
        // forgot to override hashCode()
    }

    // 10) Resource not closed on exception (RELIABILITY / FINALLY_LEAK)
    static String readFile(String path) throws IOException {
        FileInputStream fis = new FileInputStream(path);
        byte[] data = new byte[128];
        int len = fis.read(data);
        if (len < 0) throw new IOException("empty");
        fis.close(); // will never run if exception occurs above
        return new String(data);
    }

    public static void main(String[] args) {
        try {
            nullDereference();
        } catch (Exception e) {
            System.out.println("Caught null exception");
        }

        try {
            leakFile();
        } catch (IOException e) {
            System.out.println("File leak triggered: " + e.getMessage());
        }

        try {
            factorial(5);
        } catch (StackOverflowError e) {
            System.out.println("Infinite recursion detected");
        }

        stringCompare();
        unsafeThread();
        ignoredReturn();
        getInstance();
        overflow();

        Person p1 = new Person("Alice");
        Person p2 = new Person("Alice");
        System.out.println("Equal? " + p1.equals(p2));

        try {
            readFile("nofile.txt");
        } catch (IOException e) {
            System.out.println("IOException caught: " + e.getMessage());
        }
    }
}
