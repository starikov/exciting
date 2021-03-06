

#include "maxdefinitions.inc"
module modmain
use mod_atoms
use mod_lattice
use mod_muffin_tin
use mod_spin
use mod_Gvector
use mod_symmetry
use mod_kpoint
use mod_SHT
use mod_qpoint
use mod_Gkvector
use mod_potential_and_density
use mod_charge_and_moment
use mod_APW_LO
use mod_eigensystem
use mod_eigenvalue_occupancy
use mod_corestate
use mod_energy
use mod_force
use mod_plotting
use mod_DOS_optics_response
use mod_LDA_LU
use mod_RDMFT
use mod_misc
use mod_timing
use mod_constants
use mod_phonon
use mod_OEP_HF
use mod_convergence
use mod_names
integer, parameter::maxspecies=_MAXSPECIES_
integer, parameter::maxatoms= _MAXATOMS_
integer, parameter::maxlapw=_MAXLAPW_
end module

