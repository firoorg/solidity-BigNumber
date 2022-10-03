// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.16;
import "./interfaces/IBigNumbers.sol";

library BigNumbers {

    bytes constant ZERO = hex"0000000000000000000000000000000000000000000000000000000000000000";
    bytes constant  ONE = hex"0000000000000000000000000000000000000000000000000000000000000001";
    bytes constant  TWO = hex"0000000000000000000000000000000000000000000000000000000000000002";

    function verify(IBigNumbers.BigNumber memory bn) internal pure {
        uint val_msword; 
        bytes memory val = bn.val;
        assembly {val_msword := mload(add(val,0x20))} //get msword of result
        require((bn.val.length % 32 == 0) && (val_msword>>((bn.bitlen%256)-1)==1));
    }

    /** @dev init: Create a new BigNumber.
      *            overloading allows caller to obtionally pass bitlen where it is known - as it is cheaper to do off-chain and verify on-chain. 
      *            we assert input is in data structure as defined above, and that bitlen, if passed, is correct.
      *            'copy' parameter indicates whether or not to copy the contents of val to a new location in memory (for example where you pass 
                   the contents of another variable's value in)
      * parameter: bytes val - bignum value.
      * parameter: bool  neg - sign of value
      * parameter: uint bitlen - bit length of value
      * returns: IBigNumbers.BigNumber memory r.
      */
    function _init(bytes memory val, bool neg, uint bitlen) internal view returns(IBigNumbers.BigNumber memory r){ 
        // use identity at location 0x4 for cheap memcpy.
        // grab contents of val, load starting from memory end, update memory end pointer.
        assembly {
            let data := add(val, 0x20)
            let length := mload(val)
            let out
            let freemem := msize()
            switch eq(mod(length, 0x20), 0)                       // if(val.length % 32 == 0)
                case 1 {
                    out     := add(freemem, 0x20)                 // freememory location + length word
                    mstore(freemem, length)                       // set new length 
                }
                default { 
                    let offset  := sub(0x20, mod(length, 0x20))   // offset: 32 - (length % 32)
                    out     := add(add(freemem, offset), 0x20)    // freememory location + offset + length word
                    mstore(freemem, add(length, offset))          // set new length 
                }
            pop(staticcall(450, 0x4, data, length, out, length))  // copy into 'out' memory location
            mstore(0x40, add(freemem, add(mload(freemem), 0x20))) // update the free memory pointer
            mstore(r, freemem)                                    // store new bytes value in r
            mstore(add(r, 0x20), neg)                             // store neg value in r
        }

        r.bitlen = bitlen == 0 ? get_bit_length(r.val) : bitlen;
    }

    function init(bytes memory val, bool neg, uint bitlen) internal view returns(IBigNumbers.BigNumber memory){
        return _init(val, neg, bitlen);
    }
    
    function init(bytes memory val, bool neg) internal view returns(IBigNumbers.BigNumber memory){
        return _init(val, neg, 0);
    }

    /** @dev add: Initially prepare bignum BigNumbers for addition operation; internally calls actual addition/subtraction, depending on inputs.
      *                   In order to do correct addition or subtraction we have to handle the sign.
      *                   This function discovers the sign of the result based on the inputs, and calls the correct operation.
      *
      * parameter: IBigNumbers.BigNumber memory a - first BigNumber
      * parameter: IBigNumbers.BigNumber memory b - second BigNumber
      * returns: IBigNumbers.BigNumber memory r - addition of a & b.
      */
    function add(IBigNumbers.BigNumber memory a, IBigNumbers.BigNumber memory b) internal pure returns(IBigNumbers.BigNumber memory r) {
        IBigNumbers.BigNumber memory zero = IBigNumbers.BigNumber(ZERO,false,0); 
        if(a.bitlen==0 && b.bitlen==0) return zero;
        if(a.bitlen==0) return b;
        if(b.bitlen==0) return a;
        bytes memory val;
        uint bitlen;
        int compare = cmp(a,b,false);

        if(a.neg || b.neg){
            if(a.neg && b.neg){
                if(compare>=0) (val, bitlen) = _add(a.val,b.val,a.bitlen);
                else (val, bitlen) = _add(b.val,a.val,b.bitlen);
                r.neg = true;
            }
            else {
                if(compare==1){
                    (val, bitlen) = _sub(a.val,b.val);
                    r.neg = a.neg;
                }
                else if(compare==-1){
                    (val, bitlen) = _sub(b.val,a.val);
                    r.neg = !a.neg;
                }
                else return zero;//one pos and one neg, and same value.
            }
        }
        else{
            if(compare>=0){ // a>=b
                (val, bitlen) = _add(a.val,b.val,a.bitlen);
            }
            else {
                (val, bitlen) = _add(b.val,a.val,b.bitlen);
            }
            r.neg = false;
        }

        r.val = val;
        r.bitlen = (bitlen);
    }

    /** @dev _add: takes two IBigNumbers.BigNumber memory values and the bitlen of the max value, and adds them.
      *              This function is private and only callable from add: therefore the values may be of different sizes, 
      *              in any order of size, and of different signs (handled in add).
      *              As values may be of different sizes, inputs are considered starting from the least significant words, working back. 
      *              The function calculates the new bitlen (basically if bitlens are the same for max and min, max_bitlen++) and returns a new IBigNumbers.BigNumber memory value.
      *
      * parameter: bytes max -  biggest value  (determined from add)
      * parameter: bytes min -  smallest value (determined from add)
      * parameter: uint max_bitlen -  bit length of max value.
      * returns: bytes result - max + min.
      * returns: uint - bit length of result.
      */
    function _add(bytes memory max, bytes memory min, uint max_bitlen) private pure returns (bytes memory, uint) {
        bytes memory result;
        assembly {

            let result_start := msize()                                       // Get the highest available block of memory
            let carry := 0
            let uint_max := sub(0,1)

            let max_ptr := add(max, mload(max))
            let min_ptr := add(min, mload(min))                               // point to last word of each byte array.

            let result_ptr := add(add(result_start,0x20), mload(max))         // set result_ptr end.

            for { let i := mload(max) } eq(eq(i,0),0) { i := sub(i, 0x20) } { // for(int i=max_length; i!=0; i-=32)
                let max_val := mload(max_ptr)                                 // get next word for 'max'
                switch gt(i,sub(mload(max),mload(min)))                       // if(i>(max_length-min_length)). while 'min' words are still available.
                    case 1{ 

                        let min_val := mload(min_ptr)                         //      get next word for 'min'
        
                        mstore(result_ptr, add(add(max_val,min_val),carry))   //      result_word = max_word+min_word+carry
                    
                        switch gt(max_val, sub(uint_max,sub(min_val,carry)))  //      this switch block finds whether or not to set the carry bit for the next iteration.
                            case 1  { carry := 1 }
                            default {
                                switch and(eq(max_val,uint_max),or(gt(carry,0), gt(min_val,0)))
                                case 1 { carry := 1 }
                                default{ carry := 0 }
                            }
                            
                        min_ptr := sub(min_ptr,0x20)                       //       point to next 'min' word
                    }
                    default{                                               // else: remainder after 'min' words are complete.
                        mstore(result_ptr, add(max_val,carry))             //       result_word = max_word+carry
                        
                        switch and( eq(uint_max,max_val), eq(carry,1) )    //       this switch block finds whether or not to set the carry bit for the next iteration.
                            case 1  { carry := 1 }
                            default { carry := 0 }
                    }
                result_ptr := sub(result_ptr,0x20)                         // point to next 'result' word
                max_ptr := sub(max_ptr,0x20)                               // point to next 'max' word
            }

            switch eq(carry,0) 
                case 1{ result_start := add(result_start,0x20) }           // if carry is 0, increment result_start, ie. length word for result is now one word position ahead.
                default { mstore(result_ptr, 1) }                          // else if carry is 1, store 1; overflow has occured, so length word remains in the same position.

            result := result_start                                         // point 'result' bytes value to the correct address in memory
            mstore(result,add(mload(max),mul(0x20,carry)))                 // store length of result. we are finished with the byte array.
            
            mstore(0x40, add(result,add(mload(result),0x20)))              // Update freemem pointer to point to new end of memory.

            /* we now calculate the result's bit length.
             * with addition, if we assume that some a is at least equal to some b, then the resulting bit length will be a's bit length or (a's bit length)+1, depending on carry bit.
             * this is cheaper than calling get_bit_length.
             */
            let msword := mload(add(result,0x20))                             // calculate get most significant word of result
            if or( eq(msword, 1), eq(shr(mod(max_bitlen,256),msword),1) ) { // if(msword==1 || msword>>(max_bitlen % 256)==1):
                
                    max_bitlen := add(max_bitlen, 1)                          // if msword's bit length is 1 greater than max_bitlen, OR overflow occured, new bitlen is max_bitlen+1.
                }
        }
        

        return (result, max_bitlen);
    }

    
      /** @dev sub: Initially prepare bignum BigNumbers for addition operation; internally calls actual addition/subtraction, depending on inputs.
      *                   In order to do correct addition or subtraction we have to handle the sign.
      *                   This function discovers the sign of the result based on the inputs, and calls the correct operation.
      *
      * parameter: IBigNumbers.BigNumber memory a - first BigNumber
      * parameter: IBigNumbers.BigNumber memory b - second BigNumber
      * returns: IBigNumbers.BigNumber memory r - a-b.
      */  

    function sub(IBigNumbers.BigNumber memory a, IBigNumbers.BigNumber memory b) internal pure returns(IBigNumbers.BigNumber memory r) {
        IBigNumbers.BigNumber memory zero = IBigNumbers.BigNumber(ZERO,false,0); 
        if(a.bitlen==0 && b.bitlen==0) return zero;
        bytes memory val;
        int compare;
        uint bitlen;
        compare = cmp(a,b,false);
        if(a.neg || b.neg) {
            if(a.neg && b.neg){           
                if(compare == 1) { 
                    (val,bitlen) = _sub(a.val,b.val); 
                    r.neg = true;
                }
                else if(compare == -1) { 

                    (val,bitlen) = _sub(b.val,a.val); 
                    r.neg = false;
                }
                else return zero;
            }
            else {
                if(compare >= 0) (val,bitlen) = _add(a.val,b.val,a.bitlen);
                else (val,bitlen) = _add(b.val,a.val,b.bitlen);
                
                r.neg = (a.neg) ? true : false;
            }
        }
        else {
            if(compare == 1) {
                (val,bitlen) = _sub(a.val,b.val);
                r.neg = false;
             }
            else if(compare == -1) { 
                (val,bitlen) = _sub(b.val,a.val);
                r.neg = true;
            }
            else return zero; 
        }

        r.val = val;
        r.bitlen = (bitlen);
    }


    /** @dev _sub: takes two IBigNumbers.BigNumber memory values and subtracts them.
      *              This function is private and only callable from add: therefore the values may be of different sizes, 
      *              in any order of size, and of different signs (handled in add).
      *              As values may be of different sizes, inputs are considered starting from the least significant words, working back. 
      *              The function calculates the new bitlen (basically if bitlens are the same for max and min, max_bitlen++) and returns a new IBigNumbers.BigNumber memory value.
      *
      * parameter: bytes max -  biggest value  (determined from add)
      * parameter: bytes min -  smallest value (determined from add)
      * parameter: uint max_bitlen -  bit length of max value.
      * returns: bytes result - max + min.
      * returns: uint - bit length of result.
      */
    function _sub(bytes memory max, bytes memory min) private pure returns (bytes memory, uint) {
        bytes memory result;
        uint carry = 0;
        uint uint_max = type(uint256).max;
        unchecked {
        assembly {
                
            let result_start := msize()                                         // Get the highest available block of memory
        
            let max_len := mload(max)
            let min_len := mload(min)                                           // load lengths of inputs
            
            let len_diff := sub(max_len,min_len)                                // get differences in lengths.
            
            let max_ptr := add(max, max_len)
            let min_ptr := add(min, min_len)                                    // go to end of arrays
            let result_ptr := add(result_start, max_len)                        // point to least significant result word.
            let memory_end := add(result_ptr,0x20)                              // save memory_end to update free memory pointer at the end.
            
            for { let i := max_len } eq(eq(i,0),0) { i := sub(i, 0x20) } {      // for(int i=max_length; i!=0; i-=32)
                let max_val := mload(max_ptr)                                   // get next word for 'max'
                switch gt(i,len_diff)                                           // if(i>(max_length-min_length)). while 'min' words are still available.
                    case 1{ 
                        let min_val := mload(min_ptr)                           //      get next word for 'min'
        
                        mstore(result_ptr, sub(sub(max_val,min_val),carry))     //      result_word = (max_word-min_word)-carry
                    
                        switch or(lt(max_val, add(min_val,carry)), 
                               and(eq(min_val,uint_max), eq(carry,1)))          //      this switch block finds whether or not to set the carry bit for the next iteration.
                            case 1  { carry := 1 }
                            default { carry := 0 }
                            
                        min_ptr := sub(min_ptr,0x20)                            //      point to next 'result' word
                    }
                    default{                                                    // else: remainder after 'min' words are complete.

                        mstore(result_ptr, sub(max_val,carry))                  //      result_word = max_word-carry
                    
                        switch and( eq(max_val,0), eq(carry,1) )                //      this switch block finds whether or not to set the carry bit for the next iteration.
                            case 1  { carry := 1 }
                            default { carry := 0 }

                    }
                result_ptr := sub(result_ptr,0x20)                              // point to next 'result' word
                max_ptr    := sub(max_ptr,0x20)                                 // point to next 'max' word
            }      

            //the following code removes any leading words containing all zeroes in the result.
            result_ptr := add(result_ptr,0x20)                                                 
            for { }   eq(mload(result_ptr), 0) { result_ptr := add(result_ptr,0x20) } { // for(result_ptr+=32;; result==0; result_ptr+=32)
               result_start := add(result_start, 0x20)                                  // push up the start pointer for the result..
               max_len := sub(max_len,0x20)                                             // and subtract a word (32 bytes) from the result length.
            } 

            result := result_start                                                      // point 'result' bytes value to the correct address in memory
            
            mstore(result,max_len)                                                      // store length of result. we are finished with the byte array.
            
            mstore(0x40, memory_end)                                                    // Update freemem pointer.
        }
        }

        uint new_bitlen = get_bit_length(result);                                       // calculate the result's bit length.
        
        return (result, new_bitlen);
    }


    /** @dev mul: takes two BigNumbers and multiplys them. Order is irrelevant.
      *              multiplication achieved using modexp precompile:
      *                 (a * b) = (((a + b)**2 - (a - b)**2) / 4
      *              squaring is done in op_and_square function.
      *
      * parameter: IBigNumbers.BigNumber memory a 
      * parameter: IBigNumbers.BigNumber memory b 
      * returns: bytes res - a*b.
      */
    function mul(IBigNumbers.BigNumber memory a, IBigNumbers.BigNumber memory b) internal view returns(IBigNumbers.BigNumber memory res){

        res = op_and_square(a,b,0);                                             // add_and_square = (a+b)^2

        //no need to do subtraction part of the equation if a == b; if so, it has no effect on final result.
        if(cmp(a,b,true)!=0){  
            IBigNumbers.BigNumber memory sub_and_square = op_and_square(a,b,1); // sub_and_square = (a-b)^2
            res = sub(res,sub_and_square);                              // res = add_and_square - sub_and_square
        }
        _shr(res, 2);                                              // res = res / 4
     }


    /** @dev op_and_square: takes two BigNumbers, performs operation 'op' on them, and squares the result.
      *                     mul uses the multiplication by squaring method, ie. a*b == ((a+b)^2 - (a-b)^2)/4.
      *                     using modular exponentation precompile for squaring. this requires taking a special modulus value of the form:
      *                     modulus == '1|(0*n)', where n = 2 * bit length of (a 'op' b).
      *
      * parameter: IBigNumbers.BigNumber memory a 
      * parameter: IBigNumbers.BigNumber memory b 
      * parameter: int op 
      * returns: bytes res - (a'op'b) ^ 2.
      */
    function op_and_square(IBigNumbers.BigNumber memory a, IBigNumbers.BigNumber memory b, int op) private view returns(IBigNumbers.BigNumber memory res){
        IBigNumbers.BigNumber memory two = IBigNumbers.BigNumber(TWO,false,2);   
        
        uint mod_index = 0;
        uint first_word_modulus;
        bytes memory _modulus;
        
        res = (op == 0) ? add(a,b) : sub(a,b); //op == 0: add, op == 1: sub.
        uint res_bitlen = res.bitlen;
        assembly { mod_index := mul(res_bitlen,2) }
        first_word_modulus = uint(1) << ((mod_index % 256)); //set bit in first modulus word.
        
        //we pass the minimum modulus value which would return JUST the squaring part of the calculation; therefore the value may be many words long.
        //This is done by:
        //  - storing total modulus byte length
        //  - storing first word of modulus with correct bit set
        //  - updating the free memory pointer to come after total length.
        _modulus = ZERO;
        assembly {
            mstore(_modulus, mul(add(div(mod_index,256),1),0x20))  //store length of modulus
            mstore(add(_modulus,0x20), first_word_modulus)         //set first modulus word
            mstore(0x40, add(_modulus, add(mload(_modulus),0x20))) //update freemem pointer to be modulus index + length
        }

        //create modulus IBigNumbers.BigNumber memory for modexp function
        IBigNumbers.BigNumber memory modulus; 
        modulus.val = _modulus;
        modulus.neg = false;
        modulus.bitlen = (mod_index);

        res = modexp(res,two,modulus); // ((a 'op' b) ^ 2 % modulus) == (a 'op' b) ^ 2.
    }


    /** @dev div: takes three BigNumbers (a,b and result), and verifies that a/b == result.
      *              Verifying a bigint division operation is far cheaper than actually doing the computation. 
      *              As this library is for verification of cryptographic schemes it makes more sense that this function be used in this way.
      *              (a/b = result) == (a = b * result)
      *              Integer division only; therefore:
      *                verify ((b*result) + (a % (b*result))) == a.
      *              eg. 17/7 == 2:
      *                verify  (7*2) + (17 % (7*2)) == 17.
      *              the function returns the 'result' param passed on successful validation. returning a bool on successful validation is an option, 
      *              however it makes more sense in the context of the calling contract that it should return the result. 
      *
      * parameter: IBigNumbers.BigNumber memory a 
      * parameter: IBigNumbers.BigNumber memory b 
      * parameter: IBigNumbers.BigNumber memory result
      * returns: 'result' param. 
      */
    function div(IBigNumbers.BigNumber memory a, IBigNumbers.BigNumber memory b, IBigNumbers.BigNumber memory result) internal view {
        // TODO: require strings

        // first do zero check.
        // if a<b (always zero) and result==zero (input check), return.
        IBigNumbers.BigNumber memory zero = IBigNumbers.BigNumber(ZERO,false,0);
        if(cmp(a, b, false) == -1){
            require(cmp(zero, result, false)==0);
            return;
        }

        // Following zero check:
        //if both negative: result positive
        //if one negative: result negative
        //if neither negative: result positive
        bool positiveResult = ( a.neg && b.neg ) || (!a.neg && !b.neg);
        require(positiveResult ? !result.neg : result.neg);
        
        // require denominator to not be zero.
        require(!(cmp(b,zero,true)==0));

        // do multiplication (b * result)
        IBigNumbers.BigNumber memory fst = mul(b,result);
        // check if we already have 'a' (ie. no remainder after division). if so, no mod necessary, and return.
        if(cmp(fst,a,true)==0) return;  
        IBigNumbers.BigNumber memory one = IBigNumbers.BigNumber(ONE,false,1);
        //a mod (b*result)
        IBigNumbers.BigNumber memory snd = modexp(a,one,fst); 
        // ((b*result) + a % (b*result)) == a
        require(cmp(add(fst,snd),a,true)==0); 
    }


    function mod(IBigNumbers.BigNumber memory a, IBigNumbers.BigNumber memory n) internal view returns(IBigNumbers.BigNumber memory res){
      IBigNumbers.BigNumber memory one = IBigNumbers.BigNumber(ONE,false,1);
      res = modexp(a,one,n);
    }


    /** @dev modexp: takes base, exponent, and modulus, internally computes base^exponent % modulus, and creates new BigNumber.
      *                      this function is overloaded: it assumes the exponent is positive. if not, the other method is used, whereby the inverse of the base is also passed.
      *
      * parameter: IBigNumbers.BigNumber memory base 
      * parameter: IBigNumbers.BigNumber memory exponent
      * parameter: IBigNumbers.BigNumber memory modulus
      * returns: IBigNumbers.BigNumber memory result.
      */    
    function modexp(
        IBigNumbers.BigNumber memory base, 
        IBigNumbers.BigNumber memory exponent, 
        IBigNumbers.BigNumber memory modulus) 
    internal view returns(IBigNumbers.BigNumber memory result) {
        //if exponent is negative, other method with this same name should be used.
        //if modulus is negative, we cannot perform the operation.
        require(  exponent.neg==false 
                && modulus.neg==false); 

        bytes memory _result = _modexp(base.val,exponent.val,modulus.val);
        //get bitlen of result (TODO: optimise. we know bitlen is in the same byte as the modulus bitlen byte)
        uint bitlen;
        assembly { bitlen := mload(add(_result,0x20))}
        bitlen = get_word_length(bitlen) + (((_result.length/32)-1)*256);
        
        // result assuming base is positive.
        result = IBigNumbers.BigNumber(_result, false, bitlen);
        // if base is negative, result value is abs(result-modulus).
        if(base.neg) { 
            result = sub(result, modulus);
            result.neg = false;
        }
     }

    /** @dev modexp: takes base, base inverse, exponent, and modulus, asserts inverse(base)==base inverse, 
      *                      internally computes base_inverse^exponent % modulus and creates new BigNumber.
      *                      this function is overloaded: it assumes the exponent is negative. 
      *                      if not, the other method is used, where the inverse of the base is not passed.
      *
      * parameter: IBigNumbers.BigNumber memory base
      * parameter: IBigNumbers.BigNumber memory base_inverse 
      * parameter: IBigNumbers.BigNumber memory exponent
      * parameter: IBigNumbers.BigNumber memory modulus
      * returns: IBigNumbers.BigNumber memory result.
      */ 
     function modexp(
        IBigNumbers.BigNumber memory base, 
        IBigNumbers.BigNumber memory base_inverse, 
        IBigNumbers.BigNumber memory exponent, 
        IBigNumbers.BigNumber memory modulus) 
    internal view returns(IBigNumbers.BigNumber memory result) {
        // base^-exp = (base^-1)^exp
        require(exponent.neg);

        require(cmp(base_inverse, mod_inverse(base,modulus,base_inverse), true)==0); //assert base_inverse == inverse(base, modulus)
            
        exponent.neg = false; //make e positive

        bytes memory _result = _modexp(base_inverse.val,exponent.val,modulus.val);
        //get bitlen of result (TODO: optimise. we know bitlen is in the same byte as the modulus bitlen byte)
        uint bitlen;
        assembly { bitlen := mload(add(_result,0x20))}
        bitlen = get_word_length(bitlen) + (((_result.length/32)-1)*256); 

        // result assuming base is positive.
        result = IBigNumbers.BigNumber(_result, false, bitlen);
        // if base is negative, result value is abs(result-modulus).
        if(base.neg) { 
            result = sub(result, modulus);
            result.neg = false;
        }
     }
 

    /** @dev modexp: Takes IBigNumbers.BigNumber memory values for base, exp, mod and calls precompile for (_base^_exp)%^mod
      *              Wrapper for built-in modexp (contract 0x5) as described here - https://github.com/ethereum/EIPs/pull/198
      *
      * parameter: bytes base
      * parameter: bytes base_inverse 
      * parameter: bytes exponent
      * returns: bytes ret.
      */
    function _modexp(bytes memory _base, bytes memory _exp, bytes memory _mod) private view returns(bytes memory ret) {
        assembly {
            
            let bl := mload(_base)
            let el := mload(_exp)
            let ml := mload(_mod)
            
            
            let freemem := mload(0x40) // Free memory pointer is always stored at 0x40
            
            
            mstore(freemem, bl)         // arg[0] = base.length @ +0
            
            mstore(add(freemem,32), el) // arg[1] = exp.length @ +32
            
            mstore(add(freemem,64), ml) // arg[2] = mod.length @ +64
            
            // arg[3] = base.bits @ + 96
            // Use identity built-in (contract 0x4) as a cheap memcpy
            let success := staticcall(450, 0x4, add(_base,32), bl, add(freemem,96), bl)
            
            // arg[4] = exp.bits @ +96+base.length
            let size := add(96, bl)
            success := staticcall(450, 0x4, add(_exp,32), el, add(freemem,size), el)
            
            // arg[5] = mod.bits @ +96+base.length+exp.length
            size := add(size,el)
            success := staticcall(450, 0x4, add(_mod,32), ml, add(freemem,size), ml)
            
            switch success case 0 { invalid() } //fail where we haven't enough gas to make the call

            // Total size of input = 96+base.length+exp.length+mod.length
            size := add(size,ml)
            // Invoke contract 0x5, put return value right after mod.length, @ +96
            success := staticcall(sub(gas(), 1350), 0x5, freemem, size, add(96,freemem), ml)

            switch success case 0 { invalid() } //fail where we haven't enough gas to make the call

            let length := ml
            let length_ptr := add(96,freemem)

            ///the following code removes any leading words containing all zeroes in the result.
            //start_ptr := add(start_ptr,0x20)
            for { } eq ( eq(mload(length_ptr), 0), 1) { } {
               length_ptr := add(length_ptr, 0x20)        //push up the start pointer for the result..
               length := sub(length,0x20) //and subtract a word (32 bytes) from the result length.
            } 

            ret := sub(length_ptr,0x20)
            mstore(ret, length)
            
            // point to the location of the return value (length, bits)
            //assuming mod length is multiple of 32, return value is already in the right format.
            //function visibility is changed to internal to reflect this.
            //ret := add(64,freemem) 
            
            mstore(0x40, add(add(96, freemem),ml)) //deallocate freemem pointer
        }        
    }


    /** @dev modmul: Takes BigNumbers for a, b, and modulus, and computes (a*b) % modulus
      *              We call mul for the two input values, before calling modexp, passing exponent as 1.
      *              Sign is taken care of in sub-functions.
      *
      * parameter: IBigNumbers.BigNumber memory a
      * parameter: IBigNumbers.BigNumber memory b
      * parameter: IBigNumbers.BigNumber memory modulus
      * returns: IBigNumbers.BigNumber memory res.
      */
    function modmul(IBigNumbers.BigNumber memory a, IBigNumbers.BigNumber memory b, IBigNumbers.BigNumber memory modulus) internal view returns(IBigNumbers.BigNumber memory res){       
        res = mod( mul(a,b), modulus);       
    }


    /** @dev mod_inverse: Takes BigNumbers for base, modulus, and result, verifies (base*result)%modulus==1, and returns result.
      *                   Similar to div, it's far cheaper to verify an inverse operation on-chain than it is to calculate it, so we allow the user to pass their own result.
      *
      * parameter: IBigNumbers.BigNumber memory base
      * parameter: IBigNumbers.BigNumber memory modulus
      * parameter: IBigNumbers.BigNumber memory user_result
      * returns: IBigNumbers.BigNumber memory user_result.
      */
    function mod_inverse(IBigNumbers.BigNumber memory base, IBigNumbers.BigNumber memory modulus, IBigNumbers.BigNumber memory user_result) internal view returns(IBigNumbers.BigNumber memory){
        require(base.neg==false && modulus.neg==false); //assert positivity of inputs.
            
        /*
         * the following proves:
         * - user result passed is correct for values base and modulus
         * - modular inverse exists for values base and modulus.
         * otherwise it fails.
         */        
        IBigNumbers.BigNumber memory one = IBigNumbers.BigNumber(ONE,false,1);
        require(cmp(modmul(base, user_result, modulus),one,true)==0);

        return user_result;
     }


    /** @dev is_odd: returns 1 if IBigNumbers.BigNumber memory value is an odd number and 0 otherwise.
      *              
      * parameter: IBigNumbers.BigNumber memory _in
      * returns: uint ret.
      */  
    function is_odd(IBigNumbers.BigNumber memory _in) internal pure returns(uint ret){
        assembly{
            let in_ptr := add(mload(_in), mload(mload(_in))) //go to least significant word
            ret := mod(mload(in_ptr),2)                      //..and mod it with 2. 
        }
    }


    /** @dev cmp: IBigNumbers.BigNumber memory comparison. 'signed' parameter indiciates whether to consider the sign of the inputs.
      *           'trigger' is used to decide this - 
      *              if both negative, invert the result; 
      *              if both positive (or signed==false), trigger has no effect;
      *              if differing signs, we return immediately based on input.
      *           returns -1 on a<b, 0 on a==b, 1 on a>b.
      *           
      * parameter: IBigNumbers.BigNumber memory a
      * parameter: IBigNumbers.BigNumber memory b
      * parameter: bool signed
      * returns: int.
      */
    function cmp(IBigNumbers.BigNumber memory a, IBigNumbers.BigNumber memory b, bool signed) internal pure returns(int){
        // TODO full conversion to assembly
        // will require a yul function (for breaking out of) and int handling.
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

    function gt(IBigNumbers.BigNumber memory a, IBigNumbers.BigNumber memory b) internal pure returns(bool){
        int result = cmp(a, b, true);
        return (result==1) ? true : false;
    }

    function gte(IBigNumbers.BigNumber memory a, IBigNumbers.BigNumber memory b) internal pure returns(bool){
        int result = cmp(a, b, true);
        return (result==1 || result==0) ? true : false;
    }

    function lt(IBigNumbers.BigNumber memory a, IBigNumbers.BigNumber memory b) internal pure returns(bool){
        int result = cmp(a, b, true);
        return (result==-1) ? true : false;
    }

    function lte(IBigNumbers.BigNumber memory a, IBigNumbers.BigNumber memory b) internal pure returns(bool){
        int result = cmp(a, b, true);
        return (result==-1 || result==0) ? true : false;
    }


    //*************** begin is_prime functions **********************************

    //
    //TODO generalize for any size input - currently just works for 850-1300 bit primes

    /** @dev is_prime: executes Miller-Rabin Primality Test to see whether input IBigNumbers.BigNumber memory is prime or not.
      *                'randomness' is expected to be provided 
      *                TODO: 1. add Oraclize randomness generation code template to be added to calling contract.
      *                      2. generalize for any size input (ie. make constant size randomness array dynamic in some way).
      *           
      * parameter: IBigNumbers.BigNumber memory a
      * parameter: IBigNumbers.BigNumber[] randomness
      * returns: bool indicating primality.
      */
    function is_prime(IBigNumbers.BigNumber memory a, IBigNumbers.BigNumber[3] memory randomness) internal view returns (bool){
        IBigNumbers.BigNumber memory  zero = IBigNumbers.BigNumber(ZERO,false,0); 
        IBigNumbers.BigNumber memory   one = IBigNumbers.BigNumber(ONE,false,1); 
        IBigNumbers.BigNumber memory   two = IBigNumbers.BigNumber(TWO,false,2); 

        if (cmp(a, one, true) != 1){ 
            return false;
        } // if value is <= 1
                    
        // first look for small factors
        if (is_odd(a)==0) {
            return (cmp(a, two,true)==0); // if a is even: a is prime if and only if a == 2
        }
                 
        IBigNumbers.BigNumber memory a1 = sub(a,one);

        if(cmp(a1,zero,true)==0) return false;
        
        uint k = get_k(a1);
        IBigNumbers.BigNumber memory a1_odd = init(a1.val, a1.neg); 
        _shr(a1_odd, k);

        int j;
        uint num_checks = prime_checks_for_size(a.bitlen);
        IBigNumbers.BigNumber memory check;
        for (uint i = 0; i < num_checks; i++) {
            
            check = add(randomness[i], one);   
            // now 1 <= check < a.

            j = witness(check, a, a1, a1_odd, k);

            if(j==-1 || j==1) return false;
                
        }

        //if we've got to here, a is likely a prime.
        return true;
    }

    function get_k(IBigNumbers.BigNumber memory a1) private pure returns (uint k){
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

    function prime_checks_for_size(uint bit_size) private pure returns(uint checks){

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

    
    function witness(IBigNumbers.BigNumber memory w, IBigNumbers.BigNumber memory a, IBigNumbers.BigNumber memory a1, IBigNumbers.BigNumber memory a1_odd, uint k) internal view returns (int){
        // returns -  0: likely prime, 1: composite number (definite non-prime).
        IBigNumbers.BigNumber memory one = IBigNumbers.BigNumber(ONE,false,1); 
        IBigNumbers.BigNumber memory two = IBigNumbers.BigNumber(TWO,false,2); 

        w = modexp(w, a1_odd, a); // w := w^a1_odd mod a

        if (cmp(w,one,true)==0) return 0; // probably prime.                
                           
        if (cmp(w, a1,true)==0) return 0; // w == -1 (mod a), 'a' is probably prime
                                 
         for (;k != 0; k=k-1) {
             w = modexp(w,two,a); // w := w^2 mod a

             if (cmp(w,one,true)==0) return 1; // // 'a' is composite, otherwise a previous 'w' would have been == -1 (mod 'a')
                                    
             if (cmp(w, a1,true)==0) return 0; // w == -1 (mod a), 'a' is probably prime
                      
         }
        /*
         * If we get here, 'w' is the (a-1)/2-th power of the original 'w', and
         * it is neither -1 nor +1 -- so 'a' cannot be prime
         */
        return 1;
    }

    // ******************************** end is_prime functions ************************************   
    /** @dev shr: right shift IBigNumbers.BigNumber memory 'dividend' by 'value' bits.
             copies input value to new memory location before shift and calls _shr function after. 
      * @param bn value to shift
      * @param bits amount of bits to shift by
      * @return r result
      */
    function shr(IBigNumbers.BigNumber memory bn, uint bits) internal view returns(IBigNumbers.BigNumber memory){
        return _shr(_init(bn.val, bn.neg, bn.bitlen), bits);

    }

    /** @dev shr: right shift IBigNumbers.BigNumber memory 'dividend' by 'value' bits.
             Shifts input value in-place, ie. does not create new memory. wrapper function above does this.
        right shift does not necessarily have to copy into a new memory location. where the user wishes the modify the existing value they have in place, they can use this.  
      * @param bn value to shift
      * @param bits amount of bits to shift by
      * @return r result
      */
    function _shr(IBigNumbers.BigNumber memory bn, uint bits) internal view returns(IBigNumbers.BigNumber memory){

        //uint length = bn.val.length;
        uint length;
        assembly { length := mload(mload(bn)) }

        // if bits is >= the bitlength of the value the result is always 0
        if(bits >= length * 8) return IBigNumbers.BigNumber(ZERO,false,0); 
        
        // set bitlen initially as we will be potentially modifying 'bits'
        bn.bitlen = bn.bitlen-(bits);

        // handle shifts greater than 256:
        // if bits is greater than 256 we can simply remove any trailing words, by altering the BN length. we also update 'bits' so that it is now in the range 0..256.
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
                  let insize      := mload(in)
                  let out         := add(in,     bytes_shift)
                  let outsize     := sub(insize, bytes_shift)
                  let success     := staticcall(450, 0x4, in, insize, out, outsize)
                  mstore8(add(out, 0x1f), 0) // maintain our BN layout following identity call:
                  mstore(in, insize)         // set current length byte to 0, and reset old length. TODO maybe can swap bytes here
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

    function shl(IBigNumbers.BigNumber memory bn, uint bits) internal view returns(IBigNumbers.BigNumber memory r) {
        
        // we start by creating an empty bytes array of the size of the output, based on 'bits'.
        // TODO cleanup this mess.
        uint length = bn.val.length;
        uint bitlen_mod = bn.bitlen % 256;
        uint extra_words = ((bits / 256) + (bits % 256 >= (256 - ( bitlen_mod )) ? 1 : 0)) * 0x20; 
        uint total_words = extra_words + length;

        r.bitlen = bn.bitlen+(bits);
        r.neg = bn.neg;
        bits %= 256;

        
        bytes memory bn_shift;
        uint bn_shift_ptr;
        // the following efficiently creates an empty byte array of size 'total_words'
        assembly {
            let freemem_ptr := mload(0x40)               // get pointer to free memory
            mstore(freemem_ptr, total_words)             // store bytes length
            let mem_end := add(freemem_ptr, total_words) // end of memory
            mstore(mem_end, 0)                           // store 0 at memory end
            bn_shift := freemem_ptr                      // set pointer to bytes
            bn_shift_ptr := add(bn_shift, 0x20)          // get bn_shift pointer
            mstore(0x40, add(mem_end, 0x20))             // update freemem pointer
        }

        // use identity for cheap copy if bits is multiple of 8.
        if(bits % 8 == 0) {
            // calculate the position of the first byte in the result.
            uint bytes_pos = ((256-(((bn.bitlen-1)+bits) % 256))-1) / 8;
            assembly {
              let in          := add(add(mload(bn), 0x20), div(sub(256, bitlen_mod), 8))
              let out         := add(bn_shift_ptr, bytes_pos)
              let success     := staticcall(450, 0x4, in, length, out, length)
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
       if((bitlen_mod+bits) > 256){
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


    /** @dev hash: sha3 hash a BigNumber.
      *            we hash each BigNumber WITHOUT it's first word - first word is a pointer to the start of the bytes value,
      *            and so is different for each struct.
      *             
      * parameter: IBigNumbers.BigNumber memory a
      * returns: bytes32 hash.
      */
    function hash(IBigNumbers.BigNumber memory a) internal pure returns(bytes32 _hash) {
        //amount of words to hash = all words of the value and three extra words: neg, bitlen & value length.     
        assembly {
            _hash := keccak256( add(a,0x20), add (mload(mload(a)), 0x60 ) ) 
        }
    }

    /** @dev get_bit_length: get the bit length of an IBigNumbers.BigNumber memory value input.
      *           
      * parameter: bytes a
      * returns: uint res.
      */
    function get_bit_length(bytes memory val) internal pure returns(uint res){
        uint msword; 
        assembly {
            msword := mload(add(val,0x20))                   // get msword of input
        }                  
        res = get_word_length(msword);                       // get bitlen of msword, add to size of remaining words.
        assembly {                                           
            res := add(res, mul(sub(mload(val), 0x20) , 8))  // res += (val.length-32)*8;  
        }
    }

    /** @dev get_word_length: get the word length of a uint input - ie. log2_256 (most significant bit of 256 bit value (one EVM word))
      *                       credit: Tjaden Hess @ ethereum.stackexchange             
      *           
      * parameter: uint x
      * returns: uint y.
      */
  function get_word_length(uint x) internal pure returns (uint y){
      assembly {
          switch eq(x, 0)
          case 1 {
              y := 0
          }
          default {
            let arg := x
            x := sub(x,1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
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
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
            // where x is a power of two, result needs to be incremented. we use the power of two trick here: if(arg & arg-1 == 0) ++y;
            if eq(and(arg, sub(arg, 1)), 0) {
                y := add(y, 1) 
           }
         }  
    }
  }
}
