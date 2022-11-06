// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IBigNumbers.sol";
import "./BigNumbers.sol";

library Helpers {
    using BigNumbers for *;

    // ***************** START EXPOSED HELPER FUNCTIONS ******************
    /** @notice BigNumber odd number check
      * @dev isOdd: returns 1 if BigNumber value is an odd number and 0 otherwise.
      *              
      * @param a BigNumber
      * @return r Boolean result
      */  
    function isOdd(
        BigNumber memory a
    ) internal pure returns(bool r){
        assembly{
            let a_ptr := add(mload(a), mload(mload(a))) // go to least significant word
            r := mod(mload(a_ptr),2)                      // mod it with 2 (returns 0 or 1) 
        }
    }

    /** @notice BigNumber comparison
      * @dev cmp: Compares BigNumbers a and b. 'signed' parameter indiciates whether to consider the sign of the inputs.
      *           'trigger' is used to decide this - 
      *              if both negative, invert the result; 
      *              if both positive (or signed==false), trigger has no effect;
      *              if differing signs, we return immediately based on input.
      *           returns -1 on a<b, 0 on a==b, 1 on a>b.
      *           
      * @param a BigNumber
      * @param b BigNumber
      * @param signed whether to consider sign of inputs
      * @return int result
      */
    function cmp(
        BigNumber memory a, 
        BigNumber memory b, 
        bool signed
    ) internal pure returns(int){
        int trigger = 1;
        if(signed){
            if(a.neg && b.neg) trigger = -1;
            else if(a.neg==false && b.neg==true) return 1;
            else if(a.neg==true && b.neg==false) return -1;
        }

        if(a.bitlen>b.bitlen) return    trigger;   // 1*trigger
        if(b.bitlen>a.bitlen) return -1*trigger;

        uint a_ptr;
        uint b_ptr;
        uint a_word;
        uint b_word;

        uint len = a.val.length; //bitlen is same so no need to check length.

        assembly{
            a_ptr := add(mload(a),0x20) 
            b_ptr := add(mload(b),0x20)
        }

        for(uint i=0; i<len;i+=32){
            assembly{
                a_word := mload(add(a_ptr,i))
                b_word := mload(add(b_ptr,i))
            }

            if(a_word>b_word) return    trigger; // 1*trigger
            if(b_word>a_word) return -1*trigger; 

        }

        return 0; //same value.
    }

    /** @notice BigNumber equality
      * @dev eq: returns true if a==b. sign always considered.
      *           
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
    function eq(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(bool){
        int result = cmp(a, b, true);
        return (result==0) ? true : false;
    }

    /** @notice BigNumber greater than
      * @dev eq: returns true if a>b. sign always considered.
      *           
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
    function gt(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(bool){
        int result = cmp(a, b, true);
        return (result==1) ? true : false;
    }

    /** @notice BigNumber greater than or equal to
      * @dev eq: returns true if a>=b. sign always considered.
      *           
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
    function gte(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(bool){
        int result = cmp(a, b, true);
        return (result==1 || result==0) ? true : false;
    }

    /** @notice BigNumber less than
      * @dev eq: returns true if a<b. sign always considered.
      *           
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
    function lt(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(bool){
        int result = cmp(a, b, true);
        return (result==-1) ? true : false;
    }

    /** @notice BigNumber less than or equal o
      * @dev eq: returns true if a<=b. sign always considered.
      *           
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
    function lte(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(bool){
        int result = cmp(a, b, true);
        return (result==-1 || result==0) ? true : false;
    }

    /** @notice right shift BigNumber value
      * @dev shr: right shift BigNumber a by 'bits' bits.
             copies input value to new memory location before shift and calls _shr function after. 
      * @param a BigNumber value to shift
      * @param bits amount of bits to shift by
      * @return result BigNumber
      */
    function shr(
        BigNumber memory a, 
        uint bits
    ) internal view returns(BigNumber memory){
        require(!a.neg);
        return _shr(a, bits);
    }

    /** @notice right shift BigNumber memory 'dividend' by 'bits' bits.
      * @dev _shr: Shifts input value in-place, ie. does not create new memory. shr function does this.
      * right shift does not necessarily have to copy into a new memory location. where the user wishes the modify
      * the existing value they have in place, they can use this.  
      * @param bn value to shift
      * @param bits amount of bits to shift by
      * @return r result
      */
    function _shr(BigNumber memory bn, uint bits) internal view returns(BigNumber memory){
        uint length;
        assembly { length := mload(mload(bn)) }

        // if bits is >= the bitlength of the value the result is always 0
        if(bits >= bn.bitlen) return zero();
        
        // set bitlen initially as we will be potentially modifying 'bits'
        bn.bitlen = bn.bitlen-(bits);

        // handle shifts greater than 256:
        // if bits is greater than 256 we can simply remove any trailing words, by altering the BN length. 
        // we also update 'bits' so that it is now in the range 0..256.
        assembly {
            if or(gt(bits, 0x100), eq(bits, 0x100)) {
                length := sub(length, mul(div(bits, 0x100), 0x20))
                mstore(mload(bn), length)
                bits := mod(bits, 0x100)
            }

            // if bits is multiple of 8 (byte size), we can simply use identity precompile for cheap memcopy.
            // otherwise we shift each word, starting at the least signifcant word, one-by-one using the mask technique.
            // TODO it is possible to do this without the last two operations, see SHL identity copy.
            let bn_val_ptr := mload(bn)
            switch eq(mod(bits, 8), 0)
              case 1 {  
                  let bytes_shift := div(bits, 8)
                  let in          := mload(bn)
                  let inlength    := mload(in)
                  let insize      := add(inlength, 0x20)
                  let out         := add(in,     bytes_shift)
                  let outsize     := sub(insize, bytes_shift)
                  let success     := staticcall(450, 0x4, in, insize, out, insize)
                  mstore8(add(out, 0x1f), 0) // maintain our BN layout following identity call:
                  mstore(in, inlength)         // set current length byte to 0, and reset old length.
              }
              default {
                  let mask
                  let lsw
                  let mask_shift := sub(0x100, bits)
                  let lsw_ptr := add(bn_val_ptr, length)   
                  for { let i := length } eq(eq(i,0),0) { i := sub(i, 0x20) } { // for(int i=max_length; i!=0; i-=32)
                      switch eq(i,0x20)                                         // if i==32:
                          case 1 { mask := 0 }                                  //    - handles lsword: no mask needed.
                          default { mask := mload(sub(lsw_ptr,0x20)) }          //    - else get mask (previous word)
                      lsw := shr(bits, mload(lsw_ptr))                          // right shift current by bits
                      mask := shl(mask_shift, mask)                             // left shift next significant word by mask_shift
                      mstore(lsw_ptr, or(lsw,mask))                             // store OR'd mask and shifted bits in-place
                      lsw_ptr := sub(lsw_ptr, 0x20)                             // point to next bits.
                  }
              }

            // The following removes the leading word containing all zeroes in the result should it exist, 
            // as well as updating lengths and pointers as necessary.
            let msw_ptr := add(bn_val_ptr,0x20)
            switch eq(mload(msw_ptr), 0) 
                case 1 {
                   mstore(msw_ptr, sub(mload(bn_val_ptr), 0x20)) // store new length in new position
                   mstore(bn, msw_ptr)                           // update pointer from bn
                }
                default {}
        }
    

        return bn;
    }

    /** @notice left shift BigNumber value
      * @dev shr: left shift BigNumber a by 'bits' bits.
                  ensures the value is not negative before calling the private function.
      * @param a BigNumber value to shift
      * @param bits amount of bits to shift by
      * @return result BigNumber
      */
    function shl(
        BigNumber memory a, 
        uint bits
    ) internal view returns(BigNumber memory){
        require(!a.neg);
        return _shl(a, bits);
    }

    /** @notice sha3 hash a BigNumber.
      * @dev hash: takes a BigNumber and performs sha3 hash on it.
      *            we hash each BigNumber WITHOUT it's first word - first word is a pointer to the start of the bytes value,
      *            and so is different for each struct.
      *             
      * @param a BigNumber
      * @return h bytes32 hash.
      */
    function hash(
        BigNumber memory a
    ) internal pure returns(bytes32 h) {
        //amount of words to hash = all words of the value and three extra words: neg, bitlen & value length.     
        assembly {
            h := keccak256( add(a,0x20), add (mload(mload(a)), 0x60 ) ) 
        }
    }

    /** @notice BigNumber full zero check
      * @dev isZero: checks if the BigNumber is in the default zero format for BNs (ie. the result from zero()).
      *             
      * @param a BigNumber
      * @return boolean result.
      */
    function isZero(
        BigNumber memory a
    ) internal pure returns(bool) {
        return isZero(a.val) && a.val.length==0x20 && !a.neg && a.bitlen == 0;
    }


    /** @notice bytes zero check
      * @dev isZero: checks if input bytes value resolves to zero.
      *             
      * @param a bytes value
      * @return boolean result.
      */
    function isZero(
        bytes memory a
    ) internal pure returns(bool) {
        uint msword;
        uint msword_ptr;
        assembly {
            msword_ptr := add(a,0x20)
        }
        for(uint i=0; i<a.length; i+=32) {
            assembly { msword := mload(msword_ptr) } // get msword of input
            if(msword > 0) return false;
            assembly { msword_ptr := add(msword_ptr, 0x20) }
        }
        return true;

    }

    /** @notice BigNumber value bit length
      * @dev bitLength: returns BigNumber value bit length- ie. log2 (most significant bit of value)
      *             
      * @param a BigNumber
      * @return uint bit length result.
      */
    function bitLength(
        BigNumber memory a
    ) internal pure returns(uint){
        return bitLength(a.val);
    }

    /** @notice bytes bit length
      * @dev bitLength: returns bytes bit length- ie. log2 (most significant bit of value)
      *             
      * @param a bytes value
      * @return r uint bit length result.
      */
    function bitLength(
        bytes memory a
    ) internal pure returns(uint r){
        if(isZero(a)) return 0;
        uint msword; 
        assembly {
            msword := mload(add(a,0x20))               // get msword of input
        }
        r = bitLength(msword);                         // get bitlen of msword, add to size of remaining words.
        assembly {                                           
            r := add(r, mul(sub(mload(a), 0x20) , 8))  // res += (val.length-32)*8;  
        }
    }

    /** @notice uint bit length
        @dev bitLength: get the bit length of a uint input - ie. log2 (most significant bit of 256 bit value (one EVM word))
      *                       credit: Tjaden Hess @ ethereum.stackexchange             
      * @param a uint value
      * @return r uint bit length result.
      */
    function bitLength(
        uint a
    ) internal pure returns (uint r){
        assembly {
            switch eq(a, 0)
            case 1 {
                r := 0
            }
            default {
                let arg := a
                a := sub(a,1)
                a := or(a, div(a, 0x02))
                a := or(a, div(a, 0x04))
                a := or(a, div(a, 0x10))
                a := or(a, div(a, 0x100))
                a := or(a, div(a, 0x10000))
                a := or(a, div(a, 0x100000000))
                a := or(a, div(a, 0x10000000000000000))
                a := or(a, div(a, 0x100000000000000000000000000000000))
                a := add(a, 1)
                let m := mload(0x40)
                mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
                mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
                mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
                mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
                mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
                mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
                mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
                mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
                mstore(0x40, add(m, 0x100))
                let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
                let shift := 0x100000000000000000000000000000000000000000000000000000000000000
                let _a := div(mul(a, magic), shift)
                r := div(mload(add(m,sub(255,_a))), shift)
                r := add(r, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
                // where a is a power of two, result needs to be incremented. we use the power of two trick here: if(arg & arg-1 == 0) ++r;
                if eq(and(arg, sub(arg, 1)), 0) {
                    r := add(r, 1) 
                }
            }
        }
    }

    /** @notice BigNumber zero value
        @dev zero: returns zero encoded as a BigNumber
      * @return zero encoded as BigNumber
      */
    function zero(
    ) internal pure returns(BigNumber memory) {
        return BigNumber(hex"0000000000000000000000000000000000000000000000000000000000000000", false, 0);
    }

    /** @notice BigNumber one value
        @dev one: returns one encoded as a BigNumber
      * @return one encoded as BigNumber
      */
    function one(
    ) internal pure returns(BigNumber memory) {
        return BigNumber(hex"0000000000000000000000000000000000000000000000000000000000000001", false, 1);
    }

    /** @notice BigNumber two value
        @dev two: returns two encoded as a BigNumber
      * @return two encoded as BigNumber
      */
    function two(
    ) internal pure returns(BigNumber memory) {
        return BigNumber(hex"0000000000000000000000000000000000000000000000000000000000000002", false, 2);
    }
    // ***************** END EXPOSED HELPER FUNCTIONS ******************















    // ***************** START PRIVATE HELPER FUNCTIONS ******************
    /** @notice left shift BigNumber memory 'dividend' by 'value' bits.
      * @param bn value to shift
      * @param bits amount of bits to shift by
      * @return r result
      */
    function _shl(
        BigNumber memory bn, 
        uint bits
    ) private view returns(BigNumber memory r) {
        if(bits==0 || bn.bitlen==0) return bn;
        
        // we start by creating an empty bytes array of the size of the output, based on 'bits'.
        // for that we must get the amount of extra words needed for the output.
        uint length = bn.val.length;
        // position of bitlen in most significnat word
        uint bit_position = ((bn.bitlen-1) % 256) + 1;
        // total extra words. we check if the bits remainder will add one more word.
        uint extra_words = (bits / 256) + ( (bits % 256) >= (256 - bit_position) ? 1 : 0);
        // length of output
        uint total_length = length + (extra_words * 0x20);

        r.bitlen = bn.bitlen+(bits);
        r.neg = bn.neg;
        bits %= 256;

        
        bytes memory bn_shift;
        uint bn_shift_ptr;
        // the following efficiently creates an empty byte array of size 'total_length'
        assembly {
            let freemem_ptr := mload(0x40)                // get pointer to free memory
            mstore(freemem_ptr, total_length)             // store bytes length
            let mem_end := add(freemem_ptr, total_length) // end of memory
            mstore(mem_end, 0)                            // store 0 at memory end
            bn_shift := freemem_ptr                       // set pointer to bytes
            bn_shift_ptr := add(bn_shift, 0x20)           // get bn_shift pointer
            mstore(0x40, add(mem_end, 0x20))              // update freemem pointer
        }

        // use identity for cheap copy if bits is multiple of 8.
        if(bits % 8 == 0) {
            // calculate the position of the first byte in the result.
            uint bytes_pos = ((256-(((bn.bitlen-1)+bits) % 256))-1) / 8;
            uint insize = (bn.bitlen / 8) + ((bn.bitlen % 8 != 0) ? 1 : 0);
            assembly {
              let in          := add(add(mload(bn), 0x20), div(sub(256, bit_position), 8))
              let out         := add(bn_shift_ptr, bytes_pos)
              let success     := staticcall(450, 0x4, in, insize, out, length)
            }
            r.val = bn_shift;
            return r;
        }


        uint mask;
        uint mask_shift = 0x100-bits;
        uint msw;
        uint msw_ptr;

       assembly {
           msw_ptr := add(mload(bn), 0x20)   
       }
        
       // handle first word before loop if the shift adds any extra words.
       // the loop would handle it if the bit shift doesn't wrap into the next word, 
       // so we check only for that condition.
       if((bit_position+bits) > 256){
           assembly {
              msw := mload(msw_ptr)
              mstore(bn_shift_ptr, shr(mask_shift, msw))
              bn_shift_ptr := add(bn_shift_ptr, 0x20)
           }
       }
        
       // as a result of creating the empty array we just have to operate on the words in the original bn.
       for(uint i=bn.val.length; i!=0; i-=0x20){                  // for each word:
           assembly {
               msw := mload(msw_ptr)                              // get most significant word
               switch eq(i,0x20)                                  // if i==32:
                   case 1 { mask := 0 }                           // handles msword: no mask needed.
                   default { mask := mload(add(msw_ptr,0x20)) }   // else get mask (next word)
               msw := shl(bits, msw)                              // left shift current msw by 'bits'
               mask := shr(mask_shift, mask)                      // right shift next significant word by mask_shift
               mstore(bn_shift_ptr, or(msw,mask))                 // store OR'd mask and shifted bits in-place
               msw_ptr := add(msw_ptr, 0x20)
               bn_shift_ptr := add(bn_shift_ptr, 0x20)
           }
       }

       r.val = bn_shift;
    }
    // ***************** END PRIVATE HELPER FUNCTIONS ******************
}
