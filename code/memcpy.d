/// Daniel Vik's memcpy implementation, preprocessed with default config, adapted to D.
module code.memcpy;

alias uint UIntN;

void *fastMemcpy(void *dest, const void *src, size_t count)
{
    ubyte* dst8 = cast(ubyte*)dest;
    ubyte* src8 = cast(ubyte*)src;

    if (count < 8) {
        {
            switch (count)
            {

            case 7: *(dst8++) = *(src8++); goto case;
            case 6: *(dst8++) = *(src8++); goto case;
            case 5: *(dst8++) = *(src8++); goto case;
            case 4: *(dst8++) = *(src8++); goto case;
            case 3: *(dst8++) = *(src8++); goto case;
            case 2: *(dst8++) = *(src8++); goto case;
            case 1: *(dst8++) = *(src8++); goto case;
            case 0:
            default: break;
            }
        }
        return dest;
    }

    while ((cast(UIntN)dst8 & (4L - 1)) != 0) {
        *(dst8++) = *(src8++);
        count--;
    }

    switch (((cast(UIntN)src8) ) & (4L - 1))
    {
    case 0: {

        UIntN* dstN = cast(UIntN*)(dst8 );
        UIntN* srcN = cast(UIntN*)(src8 );
        size_t length = count / 4L;
        while (length & 7)
        {
            {
                *(dstN++) = *(srcN++);
            }
            length--;
        } length /= 8;
        while (length--)
        {

            {
                dstN[0] = srcN[0];
            }
            {
                dstN[1] = srcN[1];
            }
            {
                dstN[2] = srcN[2];
            }
            {
                dstN[3] = srcN[3];
            }
            {
                dstN[4] = srcN[4];
            }
            {
                dstN[5] = srcN[5];
            }
            {
                dstN[6] = srcN[6];
            }
            {
                dstN[7] = srcN[7];
            }
            ((dstN) += (8));
            ((srcN) += (8));
        }
        src8 = (cast(ubyte*)srcN + 0);
        dst8 = (cast(ubyte*)dstN + 0);
        {
            ;
            ;
            switch (count & (4L - 1))
            {
            case 7: *(dst8++) = *(src8++); goto case;
            case 6: *(dst8++) = *(src8++); goto case;
            case 5: *(dst8++) = *(src8++); goto case;
            case 4: *(dst8++) = *(src8++); goto case;
            case 3: *(dst8++) = *(src8++); goto case;
            case 2: *(dst8++) = *(src8++); goto case;
            case 1: *(dst8++) = *(src8++); goto case;
            case 0: default: break;
            }
        } return dest;
    }

    case 1: {
        UIntN* dstN = cast(UIntN*)(((cast(UIntN)dst8) ) & ~(4L - 1));
        UIntN* srcN = cast(UIntN*)(((cast(UIntN)src8) ) & ~(4L - 1));
        size_t length = count / 4L;
        UIntN srcWord = *(srcN++);
        UIntN dstWord;
        while (length & 7) {
            {
                dstWord = srcWord >> 8 * 1;
                srcWord = *(srcN++);
                dstWord |= srcWord << 8 * (4L - 1);
                *(dstN++) = dstWord;
            } length--;
        } length /= 8;
        while (length--) {
            {
                dstWord = srcWord >> 8 * 1;
                srcWord = srcN[0];
                dstWord |= srcWord << 8 * (4L - 1);
                dstN[0] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 1;
                srcWord = srcN[1];
                dstWord |= srcWord << 8 * (4L - 1);
                dstN[1] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 1;
                srcWord = srcN[2];
                dstWord |= srcWord << 8 * (4L - 1);
                dstN[2] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 1;
                srcWord = srcN[3];
                dstWord |= srcWord << 8 * (4L - 1);
                dstN[3] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 1;
                srcWord = srcN[4];
                dstWord |= srcWord << 8 * (4L - 1);
                dstN[4] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 1;
                srcWord = srcN[5];
                dstWord |= srcWord << 8 * (4L - 1);
                dstN[5] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 1;
                srcWord = srcN[6];
                dstWord |= srcWord << 8 * (4L - 1);
                dstN[6] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 1;
                srcWord = srcN[7];
                dstWord |= srcWord << 8 * (4L - 1);
                dstN[7] = dstWord;
            } ((dstN) += (8));
            ((srcN) += (8));
        } src8 = (cast(ubyte*)srcN + (1 - 4L));
        dst8 = (cast(ubyte*)dstN + 0);
        {
            ;
            ;
            switch (count & (4L - 1))
            {
            case 7: *(dst8++) = *(src8++); goto case;
            case 6: *(dst8++) = *(src8++); goto case;
            case 5: *(dst8++) = *(src8++); goto case;
            case 4: *(dst8++) = *(src8++); goto case;
            case 3: *(dst8++) = *(src8++); goto case;
            case 2: *(dst8++) = *(src8++); goto case;
            case 1: *(dst8++) = *(src8++); goto case;
            case 0: default: break;
            }
        } return dest;
    }
    case 2: {
        UIntN* dstN = cast(UIntN*)(((cast(UIntN)dst8) ) & ~(4L - 1));
        UIntN* srcN = cast(UIntN*)(((cast(UIntN)src8) ) & ~(4L - 1));
        size_t length = count / 4L;
        UIntN srcWord = *(srcN++);
        UIntN dstWord;
        while (length & 7) {
            {
                dstWord = srcWord >> 8 * 2;
                srcWord = *(srcN++);
                dstWord |= srcWord << 8 * (4L - 2);
                *(dstN++) = dstWord;
            } length--;
        } length /= 8;
        while (length--) {
            {
                dstWord = srcWord >> 8 * 2;
                srcWord = srcN[0];
                dstWord |= srcWord << 8 * (4L - 2);
                dstN[0] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 2;
                srcWord = srcN[1];
                dstWord |= srcWord << 8 * (4L - 2);
                dstN[1] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 2;
                srcWord = srcN[2];
                dstWord |= srcWord << 8 * (4L - 2);
                dstN[2] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 2;
                srcWord = srcN[3];
                dstWord |= srcWord << 8 * (4L - 2);
                dstN[3] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 2;
                srcWord = srcN[4];
                dstWord |= srcWord << 8 * (4L - 2);
                dstN[4] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 2;
                srcWord = srcN[5];
                dstWord |= srcWord << 8 * (4L - 2);
                dstN[5] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 2;
                srcWord = srcN[6];
                dstWord |= srcWord << 8 * (4L - 2);
                dstN[6] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 2;
                srcWord = srcN[7];
                dstWord |= srcWord << 8 * (4L - 2);
                dstN[7] = dstWord;
            } ((dstN) += (8));
            ((srcN) += (8));
        } src8 = (cast(ubyte*)srcN + (2 - 4L));
        dst8 = (cast(ubyte*)dstN + 0);
        {
            ;
            ;
            switch (count & (4L - 1))
            {
            case 7: *(dst8++) = *(src8++); goto case;
            case 6: *(dst8++) = *(src8++); goto case;
            case 5: *(dst8++) = *(src8++); goto case;
            case 4: *(dst8++) = *(src8++); goto case;
            case 3: *(dst8++) = *(src8++); goto case;
            case 2: *(dst8++) = *(src8++); goto case;
            case 1: *(dst8++) = *(src8++); goto case;
            case 0: default: break;
            }
        } return dest;
    }
    case 3: {
        UIntN* dstN = cast(UIntN*)(((cast(UIntN)dst8) ) & ~(4L - 1));
        UIntN* srcN = cast(UIntN*)(((cast(UIntN)src8) ) & ~(4L - 1));
        size_t length = count / 4L;
        UIntN srcWord = *(srcN++);
        UIntN dstWord;
        while (length & 7) {
            {
                dstWord = srcWord >> 8 * 3;
                srcWord = *(srcN++);
                dstWord |= srcWord << 8 * (4L - 3);
                *(dstN++) = dstWord;
            } length--;
        } length /= 8;
        while (length--) {
            {
                dstWord = srcWord >> 8 * 3;
                srcWord = srcN[0];
                dstWord |= srcWord << 8 * (4L - 3);
                dstN[0] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 3;
                srcWord = srcN[1];
                dstWord |= srcWord << 8 * (4L - 3);
                dstN[1] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 3;
                srcWord = srcN[2];
                dstWord |= srcWord << 8 * (4L - 3);
                dstN[2] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 3;
                srcWord = srcN[3];
                dstWord |= srcWord << 8 * (4L - 3);
                dstN[3] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 3;
                srcWord = srcN[4];
                dstWord |= srcWord << 8 * (4L - 3);
                dstN[4] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 3;
                srcWord = srcN[5];
                dstWord |= srcWord << 8 * (4L - 3);
                dstN[5] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 3;
                srcWord = srcN[6];
                dstWord |= srcWord << 8 * (4L - 3);
                dstN[6] = dstWord;
            }
            {
                dstWord = srcWord >> 8 * 3;
                srcWord = srcN[7];
                dstWord |= srcWord << 8 * (4L - 3);
                dstN[7] = dstWord;
            } ((dstN) += (8));
            ((srcN) += (8));
        } src8 = (cast(ubyte*)srcN + (3 - 4L));
        dst8 = (cast(ubyte*)dstN + 0);
        {
            ;
            ;
            switch (count & (4L - 1))
            {
            case 7: *(dst8++) = *(src8++); goto case;
            case 6: *(dst8++) = *(src8++); goto case;
            case 5: *(dst8++) = *(src8++); goto case;
            case 4: *(dst8++) = *(src8++); goto case;
            case 3: *(dst8++) = *(src8++); goto case;
            case 2: *(dst8++) = *(src8++); goto case;
            case 1: *(dst8++) = *(src8++); goto case;
            case 0: default: break;
            }
        } return dest;
    }
    default:
    	assert(0);
    }
}

unittest
{
	char[13] a = "Hello, world!";
	char[13] b;
	fastMemcpy(b.ptr, a.ptr, a.length);
	assert(a == b);
}
