

#include "maxdefinitions.inc"
module mod_DOS_optics_response
!----------------------------------------------------------!
!     density of states, optics and response variables     !
!----------------------------------------------------------!
! number of energy intervals in the DOS/optics function
!replaced by inputstructureinteger::nwdos
! effective size of k/q-point grid for integrating the Brillouin zone
!replaced by inputstructureinteger::ngrdos
! smoothing level for DOS/optics function
!replaced by inputstructureinteger::nsmdos
! energy interval for DOS/optics function
real(8)::wdos(2)
! scissors correction
!replaced by inputstructure!replaced by inputstructure!replaced by inputstructurereal(8)::scissor
! number of optical matrix components required
integer::noptcomp
! required optical matrix components
!replaced by inputstructureinteger::optcomp(3, 27)
! usegdft is .true. if the generalised DFT correction is to be used
!replaced by inputstructurelogical::usegdft
! intraband is .true. if the intraband term is to be added to the optical matrix
!replaced by inputstructurelogical::intraband
! lmirep is .true. if the (l,m) band characters should correspond to the
! irreducible representations of the site symmetries
!<sag>
! Lorentzian lineshape in optics
logical :: optltz
! broadening for Lorentzian lineshape
real(8) :: optswidth
!</sag>
!replaced by inputstructurelogical::lmirep
! spin-quantisation axis in Cartesian coordinates used when plotting the
! spin-resolved DOS (z-axis by default)
!replaced by inputstructurereal(8)::sqados(3)
! q-vector in lattice coordinates for calculating the matrix elements
! < i,k+q | exp(iq.r) | j,k >
!replaced by inputstructurereal(8)::vecql(3)
end module

