
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

Where BASE is the address of element 0, 0, ROWS and COLS
the dimensions and STRIDE >= COLS, provides the spacing
between the first element of 2 consecutive rows (i.e.
we allow for padding at the end of a row if desired)

