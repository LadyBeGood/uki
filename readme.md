## Installation

### Prerequisites
[Install Nim](https://nim-lang.org/install.html)

### Steps
1. Clone this repository
    ```sh
    git clone --depth 1 https://github.com/LadyBeGood/utkrisht.git
    ```
2. Compile the compiler
    ```sh
    nim c --d:release --opt:speed --passC:-flto --out:uki --verbosity:0 ./utkrisht/compiler.nim
    ```
3. (Optional) Clean up the repository after successful compilation:
    ```sh
    rm -rf utkrisht
    ```
    


## Example usage
Compile a `input.uki` file to `output.js` file:
```sh
./uki input.uki output.js
```

## License

Utkrisht (uki) is licensed under the AGPL-3.0-or-later license. See the [license](./license.txt) file for full license text. 

Copyright © 2025 LadyBeGood

