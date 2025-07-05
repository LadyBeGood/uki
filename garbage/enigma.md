# Enigma Type Checking: Constraint-Guided Static Analysis for Dynamically Typed Languages

---

## Overview

**Enigma Type Checking** is a type analysis strategy for dynamically typed but strongly enforced languages. It enables **compile-time type checking** without requiring type annotations or a full static type system. The approach works by inferring types based on **how values are used**—informed entirely by the semantics of built-in operations and functions—while preserving the flexibility of dynamic types.

This method targets language designs that transpile to loosely typed backends like JavaScript, aiming to eliminate a large class of type errors before runtime while keeping the surface language dynamic and minimal.

---

## Key Concepts

### 1. Semantic Constraints

Each built-in operation (e.g., arithmetic, logical ops, I/O, array manipulation) is defined with:

- Accepted **operand types**
- Expected **arity**
- Deterministic **type signatures**

**Example:**

- `+` accepts either `(Number, Number)` or `(String, String)`
- `length` accepts `Array` or `String` and returns `Number`

These constraints form the basis for all static checking and inference.

---

### 2. Type Sets

Rather than assigning a single type to a variable, Enigma type checker assigns a **set of possible types** (`{Number}`, `{String, Boolean}`, etc.). This supports union-type reasoning without explicit union types in the syntax.

- If a variable's type set is a single valid match for an operation → **allowed**
- If the type set conflicts with the required signature → **compile-time error**
- If analysis can't determine types conclusively → **fallback to runtime checks**

---

### 3. Inference from Usage

Variables introduced via literals or known operations (e.g., `let x = 42`) are trivially inferred. More interestingly, **parameters** and other dynamic variables (like loop bindings) start with **no type**, and their type sets grow as the semantic analyzer walks through how they're used.

**Example:**

```js
function double(x) {
    return x + 2
}
```

Since `+` with a `Number` requires both operands to be `Number`, we infer `x: Number`.

This process is constraint-solving over a type lattice driven entirely by program semantics.

---

### 4. Recursive Propagation

Functions are analyzed recursively:

- Return types of functions influence call sites.
- Call sites influence parameter types.
- Parameters then influence internal logic.

This feedback loop allows inter-procedural inference without annotations.

**Example:**

```js
function ask(q) {
    return prompt(q)
}

function run() {
    let response = ask("name")
    return response + 5
}
```

This infers:

- `q: String` because `prompt` requires it
- `response: String` because that’s what `prompt` returns
- `response + 5` → error, since `(String, Number)` is invalid

---

### 5. Fallbacks and Safety

When the analysis cannot determine a unique type (e.g., due to external input or opaque expressions), the system defers type checks to **runtime** by emitting appropriate runtime guards or coercions.

This fallback is minimal and conservative—most well-structured code receives full static checking.

---

## Why It Matters

Enigma Type Checking is:

- **Annotation-free**: No burden on the programmer  
- **Flow-sensitive**: Types are inferred from control/data flow  
- **Operation-driven**: Behavior is derived from language semantics, not heuristics  
- **Static-first**: Errors are caught early, where possible  
- **Fully dynamic-compatible**: No changes to the runtime semantics of the language  

---

## Applications

- Transpilers from strict dynamic languages to JavaScript, Python, etc.
- Secure scripting environments needing bounded dynamism
- DSLs with rich semantics but minimal syntax
- Educational interpreters for teaching typing through behavior

---

## Comparison with Other Systems

| System                 | Type Annotations | Static Checking | Runtime Checking | Type Inference | Type Sets      |
|------------------------|------------------|------------------|-------------------|----------------|----------------|
| Static Typing (e.g. TypeScript) | Optional/Required | Yes              | No                | Yes            | Limited        |
| Gradual Typing         | Optional         | Partial           | Yes               | Partial         | Yes (narrow)   |
| Dynamic Typing         | No               | No                | Yes               | No              | No             |
| **Enigma Typing**     | **No**           | **Yes (partial)** | **Yes (fallback)**| **Yes**         | **Yes**         |

---

## Conclusion

**Enigma Type Checking** sits between dynamic and static typing. It reuses the dynamic semantics of a language as a type system, using operation constraints as a form of *latent specification*. The result is a lightweight yet powerful mechanism for catching type errors in dynamic code—without the cost of verbosity, without loss of expressiveness, and without runtime overreach.

It offers a compelling alternative to gradual typing for language designers targeting safety without compromising minimalism.

