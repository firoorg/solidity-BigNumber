# Big Number Library for Solidity

## Introduction

With the first release of Metropolis, and the precompiled contract allowing modular exponentiations for arbitrary-sized inputs,  we can now conceivably process big integer functions on the EVM, ie. values greater than a single EVM word (256 bits). These functions can be used as the building blocks for various cryptographic operations, for example, [Zerocoin](http://zerocoin.org/media/pdf/ZerocoinOakland.pdf), RSA signature verification, and ring-signature schemes.

## Overview
Values in memory on the EVM are in 256 bit (32 byte) words - BigNumbers in this library are considered to be consecutive words in big-endian order (top to bottom: word 0 - word n).

The struct *instance* consists of the BigNumber bytes value, the bit-length, and the sign of the value.

The value is in the Solidity 'bytes' data structure. by default, this data structure is 'tightly packed', ie. it has no leading zeroes, and it has a 'length' word indicating the number of bytes in the structure.

We consider each BigNumber value to NOT be tightly packed in the bytes data structure, ie. it has a number of leading zeros such that the value aligns at exactly the size of a number of words.
for explanation's sake, imagine that instead the EVM had a 32 bit word width, and the following value (in bytes):

     ae1b6b9f1be57476a6948f77effc

this is 14 bytes. by default, solidity's 'bytes' would prepend this structure with the value '0x0E' (14 in hex), and it's representation in memory would be like so:

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

our scheme is the same as above with 32 byte words. This is actually how the uint array represents values (bar the length being the number of words as opposed to number of bytes); however, using raw bytes has a number of advantages.

## Rationale
As we are using assembly to manipulate values directly in memory, a uint array is cumbersome and adds too much unnecessary additional overhead.
     Additionally, the modular exponentation precompiled contract, used and derivied from in the library for various operations, expects as parameters, AND returns, the bytes datatype, so it saves the conversion either side.

The sign of the value is controlled artificially, as is the case with other big integer libraries.

 The most significant bit (bitlen) is tracked throughout the lifespan of the BigNumber instance. when the caller creates a BigNumber they can also indicate this value (which the contract verifies), or allow the contract to compute it itself.


## Verification
When performing computations that consume a lot of gas, it is advisable, where possible, to compute them off-chain and have them verified on-chain. In this library, this is possible with two functions: bn_div and inverse. in both cases, the user passes the result of each computation along with the computation's inputs, and the contracts verifies that they were computed correctly, before returning the result.

## Development

This is a truffle project, with js dependancies in the package.json file.
Ensure you have node/npm, then:

#### Install
```
$ npm install -g
```

#### Run truffle's testrpc
```
$ truffle develop
```

#### Compile contracts:
```
truffle(develop)> compile 
```

#### Deploy:
```
truffle(develop)> deploy 
```

#### Run tests:
```
truffle(develop)> test 
```

I usually use Remix (Offline dev mode) for the debugger, hooked up to a local testrpc instance (much faster for functions consuming more gas).

Any proposed extensions, improvements, issue discoveries etc. are more than encouraged!

## Reference

TBD



