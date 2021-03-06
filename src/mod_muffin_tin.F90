

#include "maxdefinitions.inc"
module mod_muffin_tin
!---------------------------------------------------------------!
!     muffin-tin radial mesh and angular momentum variables     !
!---------------------------------------------------------------!
! radial function integration and differentiation polynomial order
!replaced by inputstructureinteger::nprad
! number of muffin-tin radial points for each species
integer::nrmt(_MAXSPECIES_)
! maximum nrmt over all the species
integer::nrmtmax
! autormt is .true. for automatic determination of muffin-tin radii
!replaced by inputstructurelogical::autormt
! parameters for determining muffin-tin radii automatically
!replaced by inputstructurereal(8)::rmtapm(2)
! muffin-tin radii
real(8)::rmt(_MAXSPECIES_)
! species for which the muffin-tin radius will be used for calculating gkmax
!replaced by inputstructureinteger::isgkmax
! radial step length for coarse mesh
!replaced by inputstructureinteger::lradstp
! number of coarse radial mesh points
integer::nrcmt(_MAXSPECIES_)
! maximum nrcmt over all the species
integer::nrcmtmax
! coarse muffin-tin radial mesh
real(8), allocatable :: rcmt(:, :)
! maximum allowable angular momentum for augmented plane waves

! maximum angular momentum for augmented plane waves
!replaced by inputstructureinteger::lmaxapw
! (lmaxapw+1)^2
integer::lmmaxapw
! maximum angular momentum for potentials and densities
!replaced by inputstructureinteger::lmaxvr
! (lmaxvr+1)^2
integer::lmmaxvr
! maximum angular momentum used when evaluating the Hamiltonian matrix elements
!replaced by inputstructureinteger::lmaxmat
! (lmaxmat+1)^2
integer::lmmaxmat
! fraction of muffin-tin radius which constitutes the inner part
!replaced by inputstructurereal(8)::fracinr
! maximum angular momentum in the inner part of the muffin-int
!replaced by inputstructureinteger::lmaxinr
! (lmaxinr+1)^2
integer::lmmaxinr
! number of radial points to the inner part of the muffin-tin
integer::nrmtinr(_MAXSPECIES_)
! index to (l,m) pairs
integer, allocatable :: idxlm(:, :)
!------------------------------!
!     tolerance parameters     !
!------------------------------!
! energy convergence tolerance for Dirac equation solver
real(8) :: epsedirac
! potential convergence tolerance for atomistic calculation
real(8) :: epspotatom
end module

