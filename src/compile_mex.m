function compile_mex()
    outdir = fullfile(fileparts(mfilename('fullpath')), '..', 'bin');
    if ~exist(outdir, 'dir'), mkdir(outdir); end

    mex('-outdir', outdir, 'movsum_c.c');
    mex('-outdir', outdir, 'movsum_ignore_nan_c.c');
    mex('-outdir', outdir, 'diff_c.c');
    mex('-outdir', outdir, 'product_c.c');
    mex('-outdir', outdir, 'movquantil_c.c');
end
