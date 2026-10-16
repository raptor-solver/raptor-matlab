# IPOPT for RAPTOR

The files in this folder are taken from
[mexIPOPT](https://github.com/ebertolazzi/mexIPOPT) (version 1.1.6) by
Enrico Bertolazzi, and are included only so that RAPTOR works out of the box
with [IPOPT](https://github.com/coin-or/Ipopt). They can be rebuilt, or
replaced with a newer version, from the mexIPOPT repository.

| File | Content |
| --- | --- |
| `ipopt.m`, `ipopt_auxdata.m` | MATLAB interface, selecting the mex file for the current platform |
| `windows/` | mex file for Windows (MinGW build, IPOPT 3.14.4) and the libraries it needs |
| `linux/` | mex files for Linux (`ipopt_linux_4` for gcc 7-8, `ipopt_linux_5` for gcc 9 or newer) |
| `license.txt` | mexIPOPT license |

Notes:

- All the files are unmodified, except for the Linux mex file selection in
  `ipopt.m` (marked with `RAPTOR:`). The original version only checks the
  first digit of the C compiler version configured in MATLAB, so it rejects
  gcc 10 or newer, and fails when no compiler is configured. The modified
  version reads the full version, and uses `ipopt_linux_5` when no compiler
  is configured.
- No mex file is available for macOS: build it from the mexIPOPT repository
  and place it in this folder.

mexIPOPT is distributed under the BSD 2-Clause license (`license.txt`).
IPOPT (EPL-2.0) and the libraries in `windows/` (MUMPS, METIS, BLAS, LAPACK
and the GCC runtime libraries) are distributed under their own licenses.
