## Installation

### Prerequisites
[Install Nim](https://nim-lang.org/install.html)

### Steps
1. Clone the GitHub repository
    ```sh
    git clone https://github.com/LadyBeGood/uki.git
    ```
2. Compile the code
    ```sh
    nim cpp --d:release --opt:speed --passC:-flto --out:ukic --verbosity:0 ./uki/compiler/compiler.nim
    ```



2. Compile a file:
   ```sh
   ./uki input.uki output.js
   node output.js             # Run the output
   ```

## License

Utkrisht (uki) is licensed under the AGPL-3.0-or-later license. See the [license](./license.txt) file for full license text. 

Copyright © 2025 Haha-jk