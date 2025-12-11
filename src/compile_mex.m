function compile_mex()
    mex movsum_c.c
    mex movsum_ignore_nan_c.c
    mex diff_c.c
    mex product_c.c
    mex movquantil_c.c
end