<p align="center">
  <img src="docs/images/logo_raptor.svg" alt="RAPTOR logo" width="180">
</p>

<h1 align="center">RAPTOR</h1>

<p align="center">
  <b>R</b>apid <b>A</b>lgorithm for <b>P</b>seudospectral <b>T</b>rajectory <b>O</b>ptimization and <b>R</b>obustification
</p>

<p align="center">
  <a href="https://raptor-solver.github.io/"><img alt="Documentation" src="https://img.shields.io/badge/docs-online-10264f"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue"></a>
  <img alt="MATLAB R2023b or newer" src="https://img.shields.io/badge/MATLAB-R2023b%2B-e16737">
  <a href="https://arxiv.org/abs/2610.17842"><img alt="arXiv: 2610.17842" src="https://img.shields.io/badge/arXiv-2610.17842-b31b1b"></a>
  <a href="https://github.com/raptor-solver/raptor-matlab/actions/workflows/tests.yml"><img alt="Tests" src="https://github.com/raptor-solver/raptor-matlab/actions/workflows/tests.yml/badge.svg"></a>
  <!--
  Badges to enable after the first GitHub release (and its Zenodo archive):
  <a href="https://github.com/raptor-solver/raptor-matlab/releases"><img alt="Latest release" src="https://img.shields.io/github/v/release/raptor-solver/raptor-matlab"></a>
  <a href="https://doi.org/10.5281/zenodo.XXXXXXX"><img alt="DOI" src="https://zenodo.org/badge/DOI/10.5281/zenodo.XXXXXXX.svg"></a>
  -->
</p>

RAPTOR is a MATLAB toolbox for solving continuous-time optimal control
problems with pseudospectral methods. Problems are defined through an
object-oriented interface, discretized into a sparse nonlinear program (NLP),
and solved with IPOPT, SNOPT or WORHP. Each solution is checked by
integrating the dynamics with the optimal controls.

**Documentation:** https://raptor-solver.github.io/

## Features

RAPTOR solves multi-phase optimal control problems of the form

```math
\begin{aligned}
\min \quad & \sum_{k=1}^{K} \left[ \Phi_k\big(t_0, x(t_0), t_f, x(t_f), p, q\big) + \int_{t_0}^{t_f} L_k\big(t, x, u, p, q\big)\, \mathrm{d}t \right] \\
\text{subject to} \quad & \dot{x} = f_k(t, x, u, p, q) && \text{dynamics} \\
& g_{\min} \le g_k(t, x, u, p, q) \le g_{\max} && \text{path constraints} \\
& \dot{h}_{\min} \le \tfrac{\mathrm{d}}{\mathrm{d}t}\, h_k(t, x, u, p, q) \le \dot{h}_{\max} && \text{differential constraints} \\
& \psi_{\min} \le \psi_k\big(t_0, x(t_0), t_f, x(t_f), p, q\big) \le \psi_{\max} && \text{boundary constraints} \\
& \ell_{\min} \le \ell\big(\text{end of phase } k,\ \text{start of phase } k'\big) \le \ell_{\max} && \text{linkage constraints} \\
& z_{\min} \le z \le z_{\max}, \quad z \in \{t_0, t_f, x, u, p, q\} && \text{bounds}
\end{aligned}
```

where, in each phase $k = 1, \dots, K$, $t \in [t_0, t_f]$ is the time,
$x(t)$ the states, $u(t)$ the controls and $p$ the static parameters of the
phase, while $q$ are static parameters shared by all phases (the phase index
is omitted inside each phase).

- Single- and multi-phase problems with Mayer and Lagrange costs, and path,
  differential, boundary and linkage constraints
- Lagrange and Birkhoff pseudospectral methods with Legendre polynomials and
  Gauss-Radau, flipped Gauss-Radau or Gauss-Lobatto nodes
- Global (single-segment) or hp (multi-segment) collocation grids
- Sparse Jacobians from central or complex-step differences, with
  automatic sparsity detection
- Scaling methods (bounds projection, Ruiz equilibration, Jacobian row
  normalization, manual), which can be combined
- Interfaces to IPOPT (included), SNOPT and WORHP
- Post-processing: costates and Hamiltonian estimates, accuracy check by
  numerical integration, automatic plots

## Requirements

- MATLAB R2023b or newer (tested on R2023b, R2025b and R2026a)
- An NLP solver. IPOPT is included for Windows and Linux, through
  [mexIPOPT](https://github.com/ebertolazzi/mexIPOPT). SNOPT and WORHP can be
  used if you install them and have a licence: see
  [NLP Solvers](https://raptor-solver.github.io/user-guide/nlp-solvers/) for
  the setup.

## Installation

```bash
git clone https://github.com/raptor-solver/raptor-matlab.git
```

In MATLAB, from the repository root folder:

```matlab
RAPTOR_init();   % adds RAPTOR to the path for this session
savepath;        % optional: keep it on the path after restarting MATLAB
```

## Quick start

Run the first example:

```matlab
cd examples/00-doubleIntegrator
main
```

A minimal problem looks like this (3D double integrator, minimum control
effort, fixed endpoints; the two model functions are in
`examples/00-doubleIntegrator`):

```matlab
auxdata.mass = 1;
auxdata.control_weight = 1;

ocp   = raptor.api.v1.OptimalControlProblem("doubleIntegrator", auxdata, 0);
phase = ocp.addPhase("single", 6, 3, 0);          % 6 states, 3 controls

phase.dynamics.add(@double_integrator);           % xdot = f(x, u)
phase.costs.lagrange.add(@control_effort_cost);   % integral of |u|^2

phase.boundaryConditions.initial.time   = 0;
phase.boundaryConditions.final.time     = 11;
phase.boundaryConditions.initial.states = [1; 1; 1; 1; 1; 1];
phase.boundaryConditions.final.states   = [1; -1; 0; 0; 0; 0];

phase.initialGuess.continuous.controls = [0; 0; 0];
phase.initialGuess.linear();

phase.collocation.nodes  = "Gauss-Radau";
phase.collocation.nNodes = 24;   % or e.g. [8 8 8] for an hp grid with 3 segments

problem = raptor.build(ocp);
sol = problem.solve();
```

The [Quickstart](https://raptor-solver.github.io/getting-started/quickstart/)
in the documentation explains each step.

## Examples

The [`examples`](examples) folder contains 16 problems ordered by complexity,
from a double integrator to 6-DoF powered landing. They are described in the
[documentation](https://raptor-solver.github.io/examples/). To run all of
them as a test suite (each example is a test, which passes when the example
is solved successfully):

```matlab
addpath("tests");
runTests();
```

The same tests run automatically on GitHub for every pull request towards
`main` and whenever `main` is updated.

## Citing RAPTOR

The paper describing RAPTOR is available as an [arXiv preprint](https://arxiv.org/abs/2610.17842). If you use
RAPTOR in published work, please cite it using the reference below.

```bibtex
@misc{raptor,
  author        = {Minnozzi, Riccardo and Sagliano, Marco},
  title         = {Theoretical and Computational Advances in Birkhoff Pseudospectral Transcription for Aerospace Optimal Control},
  year          = {2026},
  eprint        = {2610.17842},
  archivePrefix = {arXiv},
  primaryClass  = {math.OC},
  url           = {https://arxiv.org/abs/2610.17842}
}
```

## License

RAPTOR is released under the [MIT License](LICENSE). The IPOPT files in
`third_party/ipopt` are taken from mexIPOPT and distributed under their own
licences (see [`third_party/ipopt/README.md`](third_party/ipopt/README.md)).

## Contact

For bug reports and questions, please open an
[issue](https://github.com/raptor-solver/raptor-matlab/issues), or write to
riccardo.minnozzi@unibo.it.

## Acknowledgements

Funded by the European Union ([ERC, STARGATE, 101169959](https://cordis.europa.eu/project/id/101169959)). Views and opinions expressed are however those of the author(s) only and do not necessarily reflect those of the European Union or the European Research Council. Neither the European Union nor the granting authority can be held responsible for them.