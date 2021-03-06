

! Copyright (C) 2004-2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

module modxs
! !DESCRIPTION:
!   Global variables for the {\tt XS} (eXcited States) implementation
!   in the {\tt EXCITING}-code.
!
! !REVISION HISTORY:
!
!  Created June 2004 (Sagmeister)
  implicit none

  !----------------------------!
  !     symmetry variables     !
  !----------------------------!
  ! maximum allowed number of symmetry operations (private to this module)
  integer, private, parameter :: maxsymcrs=192
  ! true if only symmorphic space-group operations are to be considered
  ! allow only symmetries without non-primitive translations
!replaced by inputstructure  logical :: symmorph
  ! map to inverse crystal symmetry
  integer :: scimap(maxsymcrs)

  !------------------------------!
  !     q-point set variables    !
  !------------------------------!
  ! total number of q-points (reduced set)
  integer::nqptr
  ! locations of q-points on integer grid (reduced set)
  integer, allocatable :: ivqr(:,:)
  ! map from non-reduced grid to reduced set (reduced set)
  integer, allocatable :: iqmapr(:,:,:)
  ! q-points in lattice coordinates (reduced set)
  real(8), allocatable :: vqlr(:,:)
  ! q-points in Cartesian coordinates (reduced set)
  real(8), allocatable :: vqcr(:,:)
  ! q-point weights (reduced set)
  real(8), allocatable :: wqptr(:)
  ! number of Q-points for momentum transfer
  !integer ::size(input%xs%qpointset%qpoint,2)
  ! finite momentum transfer G+q-vector
 ! real(8), allocatable :: input%xs%qpointset%qpoint(:,:)
  ! finite momentum transfer q-vector
  real(8), allocatable :: vqlmt(:,:)
  ! finite momentum transfer G-vector
  integer, allocatable :: ivgmt(:,:)
  ! treatment of macroscopic dielectric function for Q-point outside of
  ! Brillouin zone
!replaced by inputstructure  integer :: mdfqtype
  ! index of current q-point
  integer :: iqcu
  data iqcu / 0 /

  ! number of crystal symmetries for the little group of q
  integer, allocatable :: nsymcrysq(:)
  ! map from little group of q to spacegroup
  integer, allocatable :: scqmap(:,:)
  ! wrapping vectors for elements of the small group of q
  integer, allocatable :: ivscwrapq(:,:,:)

  !----------------------------------!
  !     G+q-vector set variables     !
  !----------------------------------!
  ! G-vector grid sizes of (G+q)-vectors
  integer::ngridgq(3)
  ! integer grid intervals for each direction for G-vectors
  integer::intgqv(3, 2)
  ! maximum |G+q| cut-off for APW functions
!replaced by inputstructure  real(8)::gqmax
  ! number of G+q-vectors
  integer, allocatable :: ngq(:)
  ! maximum number of G+q-vectors over all q-points
  integer::ngqmax
  ! index from G+q-vectors to G-vectors
  integer, allocatable :: igqig(:,:)
  ! map from integer grid to G+q-vector array
  integer, allocatable :: ivgigq(:,:,:,:)
  ! G+q-vectors in lattice coordinates
  real(8), allocatable :: vgql(:,:,:)
  ! G+q-vectors in Cartesian coordinates
  real(8), allocatable :: vgqc(:,:,:)
  ! length of G+q-vectors
  real(8), allocatable :: gqc(:,:)
  ! (theta, phi) coordinates of G+q-vectors
  real(8), allocatable :: tpgqc(:,:,:)
  ! structure factor for the G+q-vectors
  complex(8), allocatable :: sfacgq(:,:,:)
  ! spherical harmonics of the G-vectors
  complex(8), allocatable :: ylmgq(:,:,:)

  !---------------------------------!
  !     k-point set  variables      !
  !---------------------------------!
  ! number of k-points for q=0
  integer :: nkpt0
  ! k-points in lattice coordinates for q=0
  real(8), allocatable :: vkl0(:,:)

  ! maximum number of space group operations in stars over all k
  integer :: nsymcrysstrmax
  ! number of space group operations for stars
  integer, allocatable :: nsymcrysstr(:)
  ! star of space group operations for k-points
  integer, allocatable :: scmapstr(:,:)
  ! star of k-point indices of non-reduced set
  integer, allocatable :: ikstrmapiknr(:,:)
  ! map from non-reduced k-point set to reduced one
  integer, allocatable :: strmap(:)
  ! map from non-reduced k-point set to associated symmetry in star
  integer, allocatable :: strmapsymc(:)


  !-------------------------!
  !     k+q-point set       !
  !-------------------------!
  ! offset for k+q-point set derived from q-point
  real(8),allocatable :: qvkloff(:,:)
  ! map from k-point index to k+q point index for same k
  integer, allocatable :: ikmapikq(:,:)

  !-----------------------------------------!
  !     G+k-vector set  variables (q=0)     !
  !-----------------------------------------!
  ! number of G+k-vectors for augmented plane waves
  integer, allocatable :: ngk0(:,:)
  ! maximum number of G+k-vectors over all k-points
  integer::ngkmax0
  ! index from G+k-vectors to G-vectors
  integer, allocatable :: igkig0(:,:,:)
  ! G+k-vectors in lattice coordinates
  real(8), allocatable :: vgkl0(:,:,:,:)
  ! G+k-vectors in Cartesian coordinates
  real(8), allocatable :: vgkc0(:,:,:,:)
  ! length of G+k-vectors
  real(8), allocatable :: gkc0(:,:,:)
  ! (theta, phi) coordinates of G+k-vectors
  real(8), allocatable :: tpgkc0(:,:,:,:)
  ! structure factor for the G+k-vectors
  complex(8), allocatable :: sfacgk0(:,:,:,:)

  !-----------------------------------------!
  !     potential and density variables     !
  !-----------------------------------------!
  ! square root of Coulomb potential in G-space
  real(8), allocatable :: sptclg(:,:)

  !---------------------------------------!
  !     Hamiltonian and APW variables     !
  !---------------------------------------!
  ! maximum nmat over all k-points (q=0)
  integer::nmatmax0
  ! order of overlap and Hamiltonian matrices for each k-point (q=0)
  integer, allocatable :: nmat0(:,:)
  ! first-variational eigenvectors
  complex(8), allocatable :: evecfv(:,:,:)
  ! second variational eigenvectors
  complex(8), allocatable :: evecsv(:,:)
  ! first-variational eigenvectors (q=0)
  complex(8), allocatable :: evecfv0(:,:,:)
  ! first variational eigenvalues
  real(8), allocatable :: evalfv(:,:)
  ! second-variational eigenvalues
  real(8), allocatable :: evalsv0(:,:)
  ! expansion coefficients of APW functions
  complex(8), allocatable :: apwcmt(:,:,:,:)
  ! expansion coefficients of APW functions (q=0)
  complex(8), allocatable :: apwcmt0(:,:,:,:)
  ! expansion coefficients of local orbitals functions
  complex(8), allocatable :: locmt(:,:,:,:)
  ! expansion coefficients of local orbitals functions (q=0)
  complex(8), allocatable :: locmt0(:,:,:,:)

  !--------------------------------------------!
  !     eigenvalue and occupancy variables     !
  !--------------------------------------------!
  ! eigenvalue differences (resonant part)
  real(8), allocatable :: deou(:,:)
  ! eigenvalue differences (anti-resonant part)
  real(8), allocatable :: deuo(:,:)
  ! occupation numbers (q=0)
  real(8), allocatable :: occsv0(:,:)
  ! occupation number differences (first band combination)
  real(8), allocatable :: docc12(:,:)
  ! occupation number differences (second band combination)
  real(8), allocatable :: docc21(:,:)
  ! highest (at least partially) occupied state
  integer, allocatable :: isto0(:), isto(:)
  ! lowest (at least partially) unoccupied state
  integer, allocatable :: istu0(:), istu(:)
  ! maximum isto over k-points
  integer :: istocc0, istocc
  ! minimum istu over k-points
  integer :: istunocc0, istunocc
  ! number of (at least partially) occupied valence states
  integer :: nstocc0,nstocc
  ! number of (at least partially) unoccupied valence states
  integer :: nstunocc0,nstunocc
  ! highest (at least partially) occupied state energy
  real(8) :: evlhpo
  ! lowest (at least partially) unoccupied state energy
  real(8) :: evllpu
  ! lower and upper limits and numbers for band indices combinations
  integer :: nst1,istl1,istu1,nst2,istl2,istu2
  ! lower and upper limits and numbers for band indices combinations, 2nd block
  integer :: nst3,istl3,istu3,nst4,istl4,istu4
  ! minimum and maximum energies over k-points
  real(8) :: evlmin,evlmax,evlmincut,evlmaxcut
  ! true if system has a Kohn-Sham gap
  logical :: ksgap

  !--------------------------------------------------!
  !     matrix elements of exponential expression    !
  !--------------------------------------------------!
  ! fast method to calculate APW-lo, lo-APW and lo-lo parts in MT
!replaced by inputstructure  logical :: fastemat
  ! type of matrix element generation (band-combinations)
!replaced by inputstructure  integer :: emattype
  ! maximum angular momentum for Rayleigh expansion of exponential
!replaced by inputstructure  integer :: lmaxemat
  ! (lmaxemat+1)^2
  integer :: lmmaxemat
  ! maximum angular momentum for APW functions (for matrix elements)
!replaced by inputstructure  integer :: lmaxapwwf
  ! (lmaxapwwf+1)^2
  integer :: lmmaxapwwf
  ! Gaunt coefficients array
  real(8), allocatable :: xsgnt(:,:,:)
  ! radial integrals coefficients (APW-APW)
  complex(8), allocatable :: intrgaa(:,:,:,:,:)
  ! radial integrals coefficients (lo-APW)
  complex(8), allocatable :: intrgloa(:,:,:,:,:)
  ! radial integrals coefficients (APW-lo)
  complex(8), allocatable :: intrgalo(:,:,:,:,:)
  ! radial integrals coefficients (lo-lo)
  complex(8), allocatable :: intrglolo(:,:,:,:,:)
  ! radial integrals (APW-APW)
  real(8), allocatable :: riaa(:,:,:,:,:,:,:)
  ! radial integrals (lo-APW)
  real(8), allocatable :: riloa(:,:,:,:,:,:)
  ! radial integrals (lo-lo)
  real(8), allocatable :: rilolo(:,:,:,:,:)
  ! helper matrix
  complex(8), allocatable :: xih(:,:)
  ! helper matrix
  complex(8), allocatable :: xihir(:,:)
  ! helper matrix
  complex(8), allocatable :: xiohalo(:,:)
  ! helper matrix
  complex(8), allocatable :: xiuhloa(:,:)
  ! matrix elements array (resonant part)
  complex(8), allocatable :: xiou(:,:,:)
  ! matrix elements array (anti-resonant part)
  complex(8), allocatable :: xiuo(:,:,:)

  !---------------------------------!
  !     momentum matrix elements    !
  !---------------------------------!
  ! fast method to calculate matrix elements
!replaced by inputstructure  logical :: fastpmat
  ! radial integrals coefficients (APW-APW)
  real(8), allocatable :: ripaa(:,:,:,:,:,:)
  ! radial integrals coefficients (APW-lo)
  real(8), allocatable :: ripalo(:,:,:,:,:,:)
  ! radial integrals coefficients (lo-APW)
  real(8), allocatable :: riploa(:,:,:,:,:,:)
  ! radial integrals coefficients (lo-lo)
  real(8), allocatable :: riplolo(:,:,:,:,:,:)
  ! momentum matrix elements (resonant part)
  complex(8), allocatable :: pmou(:,:,:)
  ! momentum matrix elements (anti-resonant part)
  complex(8), allocatable :: pmuo(:,:,:)

  !------------------------------------------!
  !     response and dielectric functions    !
  !------------------------------------------!
  ! time ordering of response function (time-ordered/retarded)
!replaced by inputstructure  character(32) :: torddf
  ! factor for time-ordering
  real(8) :: tordf
  ! true if analytic continuation to the real axis is to be performed
!replaced by inputstructure  logical :: acont
  ! number of energy intervals
  integer :: nwdf
  ! number of energy intervals (on imaginary axis) for analytic continuation
!replaced by inputstructure  integer :: nwacont
  ! broadening for Kohn Sham response function
!replaced by inputstructure  real(8) :: broad
  ! true if Lindhard like function is calculated (trivial matrix elements)
!replaced by inputstructure  logical :: lindhard
  ! true if to consider the anti-resonant part for the dielectric function
!replaced by inputstructure  logical :: aresdf
  ! true if only diagonal part of xc-kernel is used
!replaced by inputstructure  logical :: kerndiag
  ! true if off-diagonal tensor components of dielectric function are calculated
!replaced by inputstructure  logical :: dfoffdiag
  ! symmetrization tensor
  real(8) :: symt2(3,3,3,3)
  ! true if tetrahedron method is used for dielectric function/matrix
!replaced by inputstructure  logical :: tetradf
  ! sampling type for Brillouin zone (0 Lorentzian broadening, 1 tetrahedron
  ! method)
  integer :: bzsampl
  ! choice of weights and nodes for tetrahedron method and non-zero Q-point
!replaced by inputstructure  integer :: tetraqweights
  ! number of band transitions for analysis
  integer :: ndftrans
  ! k-point and band combination analysis
  integer, allocatable :: dftrans(:,:)
  ! smallest energy difference for which the inverse square will be considered
!replaced by inputstructure  real(8) :: epsdfde
  ! cutoff energy for dielectric function
!replaced by inputstructure  real(8) :: emaxdf

  !----------------------------!
  !     xc-kernel variables    !
  !----------------------------!
  ! time ordering of xc-kernel function (time-ordered/retarded)
!replaced by inputstructure  character(32) :: tordfxc
  ! factor for time-ordering
  real(8) :: torfxc
  ! true if to consider the anti-resonant part
!replaced by inputstructure  logical :: aresfxc
  ! maximum angular momentum for Rayleigh expansion of exponential in
  ! ALDA-kernel
!replaced by inputstructure  integer :: lmaxalda
  ! muffin-tin real space exchange-correlation kernel
  complex(8), allocatable :: fxcmt(:,:,:)
  ! interstitial real space exchange-correlation kernel
  complex(8), allocatable :: fxcir(:)
  ! exchange-correlation kernel functional type
!replaced by inputstructure  integer :: fxctype
  ! exchange-correlation kernel functional description
  character(256)::fxcdescr
  ! exchange-correlation kernel functional spin treatment
  integer :: fxcspin
  ! alpha-parameter for the asymptotic long range part of the kernel
  ! (see [Reining PRL 2002])
!replaced by inputstructure  real(8) :: alphalrc
  ! alpha-parameter for the asymptotic long range part of the kernel
  ! (see [Botti PRB 2005])
!replaced by inputstructure  real(8) :: alphalrcdyn
  ! beta-parameter for the asymptotic long range part of the kernel
  ! (see [Botti PRB 2005])
!replaced by inputstructure  real(8) :: betalrcdyn
  ! split parameter for degeneracy in energy differences of BSE-kernel
!replaced by inputstructure  real(8) :: fxcbsesplit

  !---------------------------!
  !     exciton variables     !
  !---------------------------!
  ! maximum number of excitons
!replaced by inputstructure  integer :: nexcitmax
  ! number of excitons
  integer :: nexcit(3)
  ! exciton energies
  real(8), allocatable :: excite(:,:)
  ! exciton oscillator strengths
  real(8), allocatable :: excito(:,:)

  !-----------------------------!
  !     screening variables     !
  !-----------------------------!
  ! true if one of the screening tasks is executed
  logical :: tscreen
  ! true if q-point set is taken from first Brillouin zone
!replaced by inputstructure  logical :: fbzq
  ! screening type: can be either "full", "diag", "noinvdiag" or "constant"
!replaced by inputstructure  character(32) :: screentype
  ! nosym is .true. if no symmetry information should be used
!replaced by inputstructure  logical::nosymscr
  ! reducek is .true. if k-points are to be reduced (with crystal symmetries)
!replaced by inputstructure  logical::reducekscr
  ! k-point grid sizes
!replaced by inputstructure  integer :: ngridkscr(3)
  ! k-point offset
!replaced by inputstructure  real(8) :: vkloffscr(3)
  ! smallest muffin-tin radius times gkmax
!replaced by inputstructure  real(8) :: rgkmaxscr
  ! number of empty states
!replaced by inputstructure  integer :: nemptyscr
  ! Hermitian treatment
!replaced by inputstructure  integer :: scrherm
  ! dielectric tensor in the RPA
  complex(8) :: dielten(3,3)
  ! dielectric tensor in the independent particle approximation
  complex(8) :: dielten0(3,3)
  ! averaging type for singular term in screenend Coulomb interaction
  character(256) :: sciavtype
  ! average of body for screened Coulomb interaction at Gamma-point
!replaced by inputstructure  logical :: sciavbd
  ! average of head, wings and body for screened Coulomb interaction at
  ! non-zero q-point
!replaced by inputstructure!replaced by inputstructure!replaced by inputstructure  logical :: sciavqhd, sciavqwg, sciavqbd
  ! maximum angular momentum for angular average of dielectric tensor
!replaced by inputstructure  integer :: lmaxdielt
  ! (lmaxdielt+1)^2
  integer :: lmmaxdielt
  ! number of points for Lebedev Laikov meshes
!replaced by inputstructure  integer :: nleblaik
  ! true if Lebedev Laikov meshes are to be used
  logical :: tleblaik

  !------------------------------------------!
  !     Bethe-Salpeter (kernel) variables    !
  !------------------------------------------!
  ! type of BSE-Hamiltonian
!replaced by inputstructure  character(32) :: bsetype
  ! true if effective singular part of direct term of BSE Hamiltonian is to be used
!replaced by inputstructure  logical :: bsedirsing
  ! nosym is .true. if no symmetry information should be used
!replaced by inputstructure  logical::nosymbse
  ! reducek is .true. if k-points are to be reduced (with crystal symmetries)
!replaced by inputstructure  logical::reducekbse
  ! k-point offset
!replaced by inputstructure  real(8) :: vkloffbse(3)
  ! smallest muffin-tin radius times gkmax
!replaced by inputstructure  real(8) :: rgkmaxbse
logical::tfxcbse
  ! number of states below Fermi energy (Coulomb - and exchange term)
  integer :: nbfce
  ! number of states above Fermi energy (Coulomb - and exchange term)
  integer :: nafce
  ! number of states below Fermi energy
  integer :: nbfbse
  ! number of states above Fermi energy
  integer :: nafbse
  ! diagonal of BSE kernel (mean value, lower, upper limit and range)
  complex(8) :: bsed,bsedl,bsedu,bsedd

  !-----------------------!
  !     I/O variables     !
  !-----------------------!
  ! file name for resume file
  character(256) :: fnresume
  ! last value of filext
  character(256) :: filextrevert
  ! file unit for output
  integer :: unitout
  ! file units to be connected at the same time
  integer :: unit1, unit2, unit3, unit4, unit5, unit6, unit7, unit8, unit9
  ! filename for output
  character(256) :: xsfileout
  ! weights for Brillouin zone integration
  character(256) :: fnwtet
  ! momentum matrix elements
  character(256) :: fnpmat, fnpmat_t
  ! exponential factor matrix elements
  character(256) :: fnemat, fnemat_t
  ! exponential factor matrix elements timing
  character(256) :: fnetim
  ! Kohn-Sham response function timing
  character(256) :: fnxtim
  ! Kohn-Sham response function
  character(256) :: fnchi0, fnchi0_t
  ! macroscopic dielectric function
  character(256) :: fneps
  ! loss function
  character(256) :: fnloss
  ! optical conductivity
  character(256) :: fnsigma
  ! sumrules for optics
  character(256) :: fnsumrules


  !------------------------------------------!
  !     xs-parameters related to GS ones     !
  !------------------------------------------!
!replaced by inputstructure  logical :: nosymxs
!replaced by inputstructure  integer :: ngridkxs(3)
!replaced by inputstructure  real(8) :: vkloffxs(3)
!replaced by inputstructure  logical :: reducekxs
!replaced by inputstructure  integer :: ngridqxs(3)
!replaced by inputstructure  logical :: reduceqxs
!replaced by inputstructure  real(8) :: rgkmaxxs
!replaced by inputstructure  real(8) :: swidthxs
!replaced by inputstructure  integer :: lmaxapwxs
!replaced by inputstructure  integer :: lmaxmatxs
!replaced by inputstructure  integer :: nemptyxs


  !--------------------------!
  !     backup variables     !
  !--------------------------!
  ! filename extension
  character(256) :: filext_b
  ! nosym is .true. if no symmetry information should be used
  logical::nosym_b
  ! smallest muffin-tin radius times gkmax
  real(8) :: rgkmax_b
  ! number of empty states
  integer :: nempty_b
  ! reducek is .true. if k-points are to be reduced (with crystal symmetries)
  logical::reducek_b
  ! k-point grid sizes
  integer :: ngridk_b(3)
  ! k-point offset
  real(8) :: vkloff_b(3)
  ! q-point grid sizes
  integer :: ngridq_b(3)
  ! reducek is .true. if q-points are to be reduced (with crystal symmetries)
  logical::reduceq_b
  ! type of matrix element generation (band-combinations)
  integer :: emattype_b
  real(8) :: swidth_b
  integer :: lmaxapw_b
  integer :: lmaxmat_b

  !------------------------------!
  !     parallel environment     !
  !------------------------------!
  ! maximum number of processors allowed to use
  integer, parameter :: maxproc=1000
  ! parallelization type (values are 'q', 'k', 'w')
  character(1) :: partype
  ! current initial q-point index
  integer :: qpari
  ! current final q-point index
  integer :: qparf
  ! current initial k-point index
  integer :: kpari
  ! current final k-point index
  integer :: kparf
  ! current initial (k,kp) pair index
  integer :: ppari
  ! current final (k,kp) pair index
  integer :: pparf
  ! current initial w-point index
  integer :: wpari
  ! current final w-point index
  integer :: wparf

  !--------------------------!
  !     Timing variables     !
  !--------------------------!
  ! initial and final timings for wall clock
  integer :: systim0i, systim0f, cntrate, systimcum
  ! initial and final timings for CPU timing
  real(8) :: cputim0i, cputim0f, cputimcum
  ! muffin-tin timings
  real(8) :: cmt0,cmt1,cmt2,cmt3,cmt4
  real(8) :: cpumtaa,cpumtalo,cpumtloa,cpumtlolo

  !-----------------------------!
  !     numerical constants     !
  !-----------------------------!
  ! Kronecker delta
  integer, parameter :: krondelta(3,3)=reshape((/1,0,0, 0,1,0, 0,0,1/),(/3,3/))
  ! conversion from hartree to electron volt
  real(8), parameter :: h2ev=27.2114d0

  !---------------------------------!
  !     miscellaneous variables     !
  !---------------------------------!
  ! spherical covering set in Cartesian coordinates
  real(8), allocatable :: sphcov(:,:)
  ! spherical covering set in tetha/phi angles
  real(8), allocatable :: sphcovtp(:,:)
  ! xs code version
  integer :: versionxs(2)
  ! true if energies output in eV
!replaced by inputstructure  logical :: tevout
  ! scaling factor for writing energies
  real(8) :: escale
  ! debugging level
!replaced by inputstructure  integer :: dbglev
  ! true if to append info to output file
!replaced by inputstructure  logical :: tappinfo
  ! gather option
!replaced by inputstructure  logical :: gather
!  data gather /.false./
  ! string for messages
  character(1024) :: msg
  data msg / 'no message' /
  ! number of times the main excited states routine was called
  integer :: calledxs
  data calledxs / 0 /
  ! true if only symmetries are recalculated in "init0"
  logical :: init0symonly
  data init0symonly /.false./
  ! true if to skip allocations of radial functions in "init1"
  logical :: init1norealloc
  data init1norealloc /.false./
  ! true if state (density and potential) is only allowed to be read from
  ! STATE.OUT file (no other file extension allowed)
  logical :: isreadstate0
  data isreadstate0 /.false./

end module modxs

