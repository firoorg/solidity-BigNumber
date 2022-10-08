import { ethers } from 'ethers';

const func = process.argv[2];
switch(func){
    case "add": {
        const a_val = process.argv[3];
        const b_val = process.argv[4];
        const a_neg = (process.argv[5] === 'true');
        const b_neg = (process.argv[6] === 'true');
        let a = ethers.BigNumber.from(a_val)
        let b = ethers.BigNumber.from(b_val)
        if(a_neg) a = a.mul(-1);
        if(b_neg) b = b.mul(-1);
        let res = a.add(b)
        const neg = res.isNegative()
        if(neg) res = res.mul(-1)
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, res]));
        break;
    }
    case "sub": {
        const a_val = process.argv[3];
        const b_val = process.argv[4];
        const a_neg = (process.argv[5] === 'true');
        const b_neg = (process.argv[6] === 'true');
        let a = ethers.BigNumber.from(a_val)
        let b = ethers.BigNumber.from(b_val)
        if(a_neg) a = a.mul(-1);
        if(b_neg) b = b.mul(-1);
        let res = a.sub(b)
        const neg = res.isNegative()
        if(neg) res = res.mul(-1)
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, res]));
        break;
    }
    case "mul": {
        const a_val = process.argv[3];
        const b_val = process.argv[4];
        const a_neg = (process.argv[5] === 'true');
        const b_neg = (process.argv[6] === 'true');
        let a = ethers.BigNumber.from(a_val)
        let b = ethers.BigNumber.from(b_val)
        if(a_neg) a = a.mul(-1);
        if(b_neg) b = b.mul(-1);
        let res = a.mul(b)
        const neg = res.isNegative()
        if(neg) res = res.mul(-1)
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, res]));
        break;
    }
    case "div": {
        const a_val = process.argv[3];
        const b_val = process.argv[4];
        const a_neg = (process.argv[5] === 'true');
        const b_neg = (process.argv[6] === 'true');
        let a = ethers.BigNumber.from(a_val)
        let b = ethers.BigNumber.from(b_val)
        if(a_neg) a = a.mul(-1);
        if(b_neg) b = b.mul(-1);
        let res = a.div(b)
        const neg = res.isNegative()
        if(neg) res = res.mul(-1)
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, res]));
        break;
    }
    case "mod": {
        const a_val = process.argv[3];
        const n_val = process.argv[4];
        const a_neg = (process.argv[5] === 'true');
        let a = ethers.BigNumber.from(a_val)
        let n = ethers.BigNumber.from(n_val)
        if(a_neg) a = a.mul(-1);
        let res = a.mod(n)
        const neg = res.isNegative()
        if(neg) res = res.mul(-1)
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, res]));
        break;
    }
    case "shl": {
        const a_val = process.argv[3];
        const bits = Number(process.argv[4]);
        let a = ethers.BigNumber.from(a_val);
        let res = a.shl(bits)
        const neg = res.isNegative()
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, res]));
        break;
    }
    case "shr": {
        const a_val = process.argv[3];
        const bits = Number(process.argv[4]);
        let a = ethers.BigNumber.from(a_val);
        let res = a.shr(bits)
        const neg = res.isNegative()
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, res]));
        break;
    }
    case "cmp": {
        const a_val  = process.argv[3];
        const b_val  = process.argv[4];
        const a_neg  = (process.argv[5] === 'true');
        const b_neg  = (process.argv[6] === 'true');
        const signed = (process.argv[7] === 'true');

        let a = ethers.BigNumber.from(a_val);
        let b = ethers.BigNumber.from(b_val);
        if(signed){
            if(a_neg) a = a.mul(-1);
            if(b_neg) b = b.mul(-1);
        }
        let res = 0;
        if(a.gt(b)) res = 1;
        else if(a.lt(b)) res = -1;
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['int'], [res]));
        break;
    }
}
