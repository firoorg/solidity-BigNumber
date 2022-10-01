import { ethers } from 'ethers';

const func = process.argv[2];
switch(func){
    case "add": {
        const a_val = process.argv[3];
        const b_val = process.argv[4];
        const a_neg = process.argv[5];
        const b_neg = process.argv[6];
        let a = ethers.BigNumber.from(a_val)
        let b = ethers.BigNumber.from(b_val)
        if(a_neg) a = a.mul(-1);
        if(b_neg) b = b.mul(-1);
        let res = a.add(b)
        const neg = res.isNegative()
        if(neg) res = res.mul(-1)
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, res]));
    }
}
