// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.16;

interface IBigNumbers {
    // TODO create storage friendly version (pack/unpack bool and bitlen into one word)
    struct BigNumber { 
        bytes val;
        bool neg;
        uint bitlen;
    }
}
