

# Big Number Library for Solidity

## Introduction

With the release of Metropolis, and the precompiled contract allowing modular exponentiations for arbitrary-sized inputs,  we can now process big integer functions on the EVM, ie. values greater than a single EVM word (256 bits). These functions can be used as the building blocks for various cryptographic operations, for example in RSA signature verification, and ring-signature schemes.

## Overview
Values in memory on the EVM are in 256 bit (32 byte) words - `BigNumber`s in this library are considered to be consecutive words in big-endian order (top to bottom: word `0` - word `n`).

The struct `BigNumber` defined in (`src/BigNumber.sol`) consists of the bytes value, the bit-length, and the sign of the value.

The value is in the Solidity `bytes` data structure. by default, this data structure is 'tightly packed', ie. it has no leading zeroes, and it has a 'length' word indicating the number of bytes in the structure.

We consider each BigNumber value to NOT be tightly packed in the bytes data structure, ie. it has a number of leading zeros such that the value aligns at exactly the size of a number of words.
for explanation's sake, imagine that instead the EVM had a 32 bit word width, and the following value (in bytes):

     ae1b6b9f1be57476a6948f77effc

this is 14 bytes. by default, solidity's `bytes` would prepend this structure with the value `0x0e` (14 in hex), and it's representation in memory would be like so:

     0000000e - length
     ae1b6b9f - word 0
     1be57476 - word 1
     a6948f77 - word 2
     effc0000 - word 3

In our scheme, the values are literally shifted to the right by the amount of zero bytes in the final word, and the length is changed to include these bytes.
     our scheme:

     00000010 - length (16 - num words * 4, 4 bytes per word)
     0000ae1b - word 0
     6b9f1be5 - word 1
     7476a694 - word 2
     8f77effc - word 3

this is a kind of 'normalisation'. values will 'line up' with their number representation in memory and so it saves us the hassle of trying to manage the offset when performing operations like add and subtract.

our scheme is the same as above with 32 byte words. This is actually how `uint[]` represents values (bar the length being the number of words as opposed to number of bytes); however, using raw bytes has a number of advantages.

## Rationale
As we are using assembly to manipulate values directly in memory, `uint[]` is cumbersome and adds too much unnecessary overhead.
     Additionally, the modular exponentiation pre-compiled contract, used and derived from in the library for various operations, expects as parameters, AND returns, the bytes datatype, so it saves the conversion either side.
     
The sign of the value is controlled artificially, as is the case with other big integer libraries. 

 The most significant bit (`bitlen`) is tracked throughout the lifespan of the BigNumber instance. when the caller creates a BigNumber they can also indicate this value (which the contract verifies), or allow the contract to compute it itself.


## Verification
In performing computations that consume an impossibly large amount of gas, it is necessary to compute them off-chain and have them verified on-chain. In this library, this is possible with two functions: `divVerify` and `modinvVerify`. in both cases, the user must pass the result of each computation along with the computation's inputs, and the contracts verifies that they were computed correctly, before returning the result.

To make this as frictionless as possible:
    - Import your function into a Foundry test case
    - use the `ffi` cheatcode to call the real function in an external library
    - write the resulting calldata to be used for the function call.

see `tests/differential` for examples of this.

## Usage
If you're functions directly take `BigNumber`s as arguments, it is required to first call `verify()` on these values to ensure that they are in the right format. See `src/utils/Crypto.sol` for an example of this.

## Crypto
The library `src/utils/Crypto.sol` contains some common algorithms that can be used with this `BigNumber` library. Is also shows some example usage.


## Development

This is a [Foundry](https://github.com/foundry-rs/foundry/) project. Ensure you have that installed.

#### Build
```
$ forge build
```

#### Run Unit Tests 
```
$ forge test --mc BigNumbersTest
```

## Differential Testing
Similar to [Murky](https://github.com/dmfxyz/murky/), this project makes use of Foundry's differential and fuzz testing capibilities. More info and setup is in `test/differential`.

Any proposed extensions, improvements, issue discoveries etc. are welcomed!
