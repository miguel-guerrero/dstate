
This directory contains an example of a memory to memory
mattrix multiplication block to show-case some of the 
features of dstate

The original algorithm in C looks something like this:

a[aROWS][aCOLS] * b[aCOLS][bCOLS] = c[aROWS][bCOLS]

where bROWS is implicily equal to aCOLS

```C
    for (i=0; i<aROWS; i++) {
        for (j=0; j<bCOLS; j++) {
            acc = 0;
            for (k=0; k<aCOLS; k++) {
                acc += a[i][k] * b[k][j];
            }
            c[i][j] = acc;
        }
    }
```

Each of the mattrices is defined by 4 parameters:

BASE, ROWS, COLS, STRIDE

Where BASE is the address of element [0, 0], ROWS and COLS
the dimensions and STRIDE >= COLS, provides the spacing
between the first element of 2 consecutive rows (i.e.
we allow for padding at the end of a row if desired)

Based on this another way to represent the loop above would be:

```C
    for (i=0; i<aROWS; i++) {
        for (j=0; j<bCOLS; j++) {
            acc = 0;
            for (k=0; k<aCOLS; k++) {
                acc += a[i*aSTRIDE+k] * b[k*bSTRIDE+j];
            }
            c[i*cSTRIDE+j] = acc;
        }
    }
```

where arrays a, b and c are assumed to be in aBASE, cBASE and dBASE addresses

To make the algorithm closer to HW implementable, we replace array accesses with
explicit memory read/write calls

```C
    for (i=0; i<aROWS; i++) {
        for (j=0; j<bCOLS; j++) {
            acc = 0;
            for (k=0; k<aCOLS; k++) {
                acc += MEM_read(aBASE+i*aSTRIDE+k) * MEM_read(bBASE+k*bSTRIDE+j);
            }
            MEM_write(c+i*cSTRIDE+j, acc);
        }
    }
```

Last, we can remove the index multiplies by incrementally taking care of it:

```C
    for (i=0, a_i0=aBASE, c_i0=cBASE; i<aROWS; i++, a_i0 += aSTRIDE, c_i0 += cSTRIDE) {
        for (j=0, b_0j=bBASE, c_ij=c_i0; j<bCOLS; j++, b_0j++, c_ij++) {
            acc = 0;
            for (k=0, a_ik=a_i0, b_kj=b_0j; k<aCOLS; k++, a_ik++, b_kj += bSTRIDE) {
                acc += MEM_read(a_ik) * MEM_read(b_kj);
            }
            MEM_write(c_ij, acc);
        }
    }
```

or putting it in a different way:

```C
    a_i0 = aBASE
    c_i0 = cBASE
    for (i=0; i<aROWS; i++) {
        c_ij = c_i0;
        b_0j = bBASE
        for (j=0; j<bCOLS; j++) {
            a_ik = a_i0;
            b_kj = b_0j;
            acc = 0;
            for (k=0; k<aCOLS; k++) {
                acc += MEM_read(a_ik) * MEM_read(b_kj);
                a_ik++;
                b_kj += bSTRIDE;
            }
            MEM_write(c_ij, acc);
            b_0j++;
            c_ij++;
        }
        a_i0 += aSTRIDE;
        c_i0 += cSTRIDE;
    }
```

At this point the algorithm can be written to HW adding operand precission
and clock boundaries with **`clock**. Look at in.v for the detailed implementation.
