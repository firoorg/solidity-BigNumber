// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./../interfaces/IBigNumbers.sol";
import "../BigNumbers.sol";

library Crypto {
    using Management for *;
    using Helpers for *;
    using Core for *;

    /** @notice Verifies a PKCSv1.5 SHA256 signature
      * @dev credit: https://github.com/adria0/SolRsaVerify
      * @param _sha256 is the sha256 of the data
      * @param _s is the signature
      * @param _e is the exponent
      * @param _m is the modulus
      * @return 0 if success, >0 otherwise
    */    
    function pkcs1Sha256Verify(
        bytes32 _sha256,
        BigNumber memory _s,
        BigNumber memory _e,
        BigNumber memory _m
    ) internal view verifyParams(_s,_e,_m) returns (uint) {
        return _pkcs1Sha256Verify(_sha256,_s,_e,_m);
    }

    /** @notice Verifies a PKCSv1.5 SHA256 signature
      * @dev credit: https://github.com/adria0/SolRsaVerify
      * @param _data to verify
      * @param _s is the signature
      * @param _e is the exponent
      * @param _m is the modulus
      * @return 0 if success, >0 otherwise
    */    
    function pkcs1Sha256VerifyRaw(
        bytes memory _data, 
        BigNumber memory _s, 
        BigNumber memory _e, 
        BigNumber memory _m
    ) internal view verifyParams(_s,_e,_m) returns (uint) {
        return _pkcs1Sha256Verify(sha256(_data),_s,_e,_m);
    }

    /** @notice executes Miller-Rabin Primality Test to see whether input BigNumber is prime or not.
      * @dev isPrime: executes Miller-Rabin Primality Test to see whether input BigNumber is prime or not.
      *                'randomness' is expected to be provided.
      *                TODO: 1. add Oraclize randomness generation code template to be added to calling contract.
      *                TODO generalize for any size input - currently just works for 850-1300 bit primes
      *           
      * @param a BigNumber value to check
      * @param randomness BigNumber array of randomness
      * @return bool indicating primality.
      */
    function isPrime(
        BigNumber memory a, 
        BigNumber[3] memory randomness
    ) internal view returns (bool){

        BigNumber memory one = Helpers.one();
        BigNumber memory two = Helpers.two();
        
        int compare = a.cmp(two,true); 
        if (compare < 0){
            // if value is < 2
            return false;
        } 
        if(compare == 0){
            // if value is 2
            return true;
        }
        // if a is even and not 2 (checked): return false
        if (!a.isOdd()) {
            return false; 
        }
                 
        BigNumber memory a1 = a.sub(one);

        uint k = getK(a1);
        BigNumber memory a1_odd = a1.val.init(a1.neg); 
        a1_odd._shr(k);

        int j;
        uint num_checks = primeChecksForSize(a.bitlen);
        BigNumber memory check;
        for (uint i = 0; i < num_checks; i++) {
            
            check = randomness[i].add(one);
            // now 1 <= check < a.

            j = witness(check, a, a1, a1_odd, k);

            if(j==-1 || j==1) return false;
        }

        //if we've got to here, a is likely a prime.
        return true;
    }

    /** @notice Verifies a PKCSv1.5 SHA256 signature
      * @dev credit: https://github.com/adria0/SolRsaVerify
      * @param _sha256 to verify
      * @param _s is the signature
      * @param _e is the exponent
      * @param _m is the modulus
      * @return 0 if success, >0 otherwise
    */    
    function _pkcs1Sha256Verify(
        bytes32 _sha256,
        BigNumber memory _s,
        BigNumber memory _e,
        BigNumber memory _m
    ) private view returns (uint) {
        
        uint8[19] memory sha256Prefix = [
            0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x05, 0x00, 0x04, 0x20
        ];
        
      	require(_m.val.length >= sha256Prefix.length+_sha256.length+11);

        /// decipher
        uint decipherlen = _m.val.length;
        bytes memory decipher = (_s.modexp(_e, _m)).val;
        
        /// 0x00 || 0x01 || PS || 0x00 || DigestInfo
        /// PS is padding filled with 0xff
        //  DigestInfo ::= SEQUENCE {
        //     digestAlgorithm AlgorithmIdentifier,
        //     digest OCTET STRING
        //  }
        uint i;
        uint paddingLen = decipherlen - 3 - sha256Prefix.length - 32;
        if (decipher[0] != 0 || uint8(decipher[1]) != 1) {
            return 1;
        }
        for (i = 2;i<2+paddingLen;i++) {
            if (decipher[i] != 0xff) {
                return 2;
            }
        }
        if (decipher[2+paddingLen] != 0) {
            return 3;
        }
        for (i = 0;i<sha256Prefix.length;i++) {
            if (uint8(decipher[3+paddingLen+i])!=sha256Prefix[i]) {
                return 4;
            }
        }
        for (i = 0;i<_sha256.length;i++) {
            if (decipher[3+paddingLen+sha256Prefix.length+i]!=_sha256[i]) {
                return 5;
            }
        }

        return 0;
    }

    function getK(
        BigNumber memory a1
    ) private pure returns (uint k){
        k = 0;
        uint mask=1;
        uint a1_ptr;
        uint val;
        assembly{ 
            a1_ptr := add(mload(a1),mload(mload(a1))) // get address of least significant portion of a
            val := mload(a1_ptr)  //load it
        }
        
        //loop from least signifcant bits until we hit a set bit. increment k until this point.        
        for(bool bit_set = ((val & mask) != 0); !bit_set; bit_set = ((val & mask) != 0)){
            
            if(((k+1) % 256) == 0){ //get next word should k reach 256.
                a1_ptr -= 32;
                assembly {val := mload(a1_ptr)}
                mask = 1;
            }
            
            mask*=2; // set next bit (left shift)
            k++;     // increment k
        }
    } 

    function primeChecksForSize(
        uint bit_size
    ) private pure returns(uint checks){

       checks = bit_size >= 1300 ?  2 :
                bit_size >=  850 ?  3 :
                bit_size >=  650 ?  4 :
                bit_size >=  550 ?  5 :
                bit_size >=  450 ?  6 :
                bit_size >=  400 ?  7 :
                bit_size >=  350 ?  8 :
                bit_size >=  300 ?  9 :
                bit_size >=  250 ? 12 :
                bit_size >=  200 ? 15 :
                bit_size >=  150 ? 18 :
                /* b >= 100 */ 27;
    }
    
    function witness(
        BigNumber memory w, 
        BigNumber memory a, 
        BigNumber memory a1, 
        BigNumber memory a1_odd, 
        uint k
    ) private view returns (int){
        BigNumber memory one = Helpers.one();
        BigNumber memory two = Helpers.two();
        // returns -  0: likely prime, 1: composite number (definite non-prime).

        w = w.modexp(a1_odd, a); // w := w^a1_odd mod a

        if (w.cmp(one,true)==0) return 0; // probably prime.                
                           
        if (w.cmp(a1,true)==0) return 0; // w == -1 (mod a), 'a' is probably prime
                                 
         for (;k != 0; k=k-1) {
             w = w.modexp(two,a); // w := w^2 mod a

             if (w.cmp(one,true)==0) return 1; // // 'a' is composite, otherwise a previous 'w' would have been == -1 (mod 'a')
                                    
             if (w.cmp(a1,true)==0) return 0; // w == -1 (mod a), 'a' is probably prime
                      
         }
        /*
         * If we get here, 'w' is the (a-1)/2-th power of the original 'w', and
         * it is neither -1 nor +1 -- so 'a' cannot be prime
         */
        return 1;
    }

    modifier verifyParams(
        BigNumber memory s,
        BigNumber memory e,
        BigNumber memory m
    ) {
        s.verify();
        e.verify();
        m.verify();
        _;
    }
}
