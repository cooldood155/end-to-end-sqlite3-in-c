# *Fuzzing*

`fuzz_core.cpp` is the entry point every fuzzing engine uses. It takes one
buffer and **must not** crash, hand, leak or trip a sanitizer for any input.

```sh
conan install . -pr:a profiles/native -s build_type=Debug --build=missing \
  -c tools.build:compiler_executables="{'c': 'clang-18', 'cpp': 'clang++-18}"

cmake --preset native-debug \
  -DETESCA_FUZZER=libfuzzer -DETESCA_SANITIZE=address,undefined

cmake --build --preset native-debug

ctest --preset native-debug -L fuzz
```

`corpus/core/` is the seed corpus committed and reused,
`<build>/fuzz-corpus/core/` is where the fuzzer engine saves its logs;
permanently save anything by copying it from `<build>/fuzz-corpus/core/` into
`corpus/core/`.

- *corpus*: A collection of sample data used as inputs to test a program.

For `AFL++` instead, configure with `CXX-afl-clang-fast++ -DETESCA_FUZZER=afl`
and drive the binary with `afl-fuzz` yourself.
