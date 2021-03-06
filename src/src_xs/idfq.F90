



! Copyright (C) 2007-2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.


subroutine idfq(iq)
  use modmain
use modinput
  use modxs
  use modfxcifc
  use modtetra
  use modmpi
  use m_genwgrid
  use m_dyson
  use m_dysonsym
  use m_getx0
  use m_getunit
  use m_genfilname
  implicit none
  ! arguments
  integer, intent(in) :: iq
  ! local variables
  character(*), parameter :: thisnam='idfq'
  character(256) :: filnam, filnam2
  complex(8), allocatable :: chi0(:, :), fxc(:, :), idf(:, :), mdf1(:), w(:)
  complex(8), allocatable :: chi0hd(:), chi0wg(:, :, :), chi0h(:, :)
  integer :: n, m, recl, j, iw, wi, wf, nwdfp, nc, oct1, oct2, octl, octu, igmt
  logical :: tq0
  integer, external :: l2int
  logical, external :: tqgamma
  ! sampling type for Brillouin zone sampling
  bzsampl=l2int(input%xs%tetra%tetradf)
  tq0=tqgamma(iq)
  ! number of components (3 for q=0)
  nc=1
  if (tq0) then
     nc=3
  end if
  ! limits for w-points
  wi=wpari
  wf=wparf
  nwdfp=wparf-wpari+1
  ! matrix size for local field effects
  n=ngq(iq)
  allocate(chi0(n, n), fxc(n, n), idf(n, n), w(nwdf), mdf1(nwdf), chi0hd(nwdf))
  allocate(chi0wg(n, 2, 3), chi0h(3, 3))
  fxc=zzero
  ! filename for response function file
  call genfilname(basename = 'X0', asc = .false., bzsampl = bzsampl, &
       acont = input%xs%tddft%acont, nar = .not.input%xs%tddft%aresdf, tord=input%xs%tddft%torddf, markfxcbse =&
    &tfxcbse, iqmt = iq, filnam = filnam)
  call genfilname(iqmt=iq, setfilext=.true.)
  call init1offs(qvkloff(1, iq))
  ! find highest (partially) occupied and lowest (partially) unoccupied states
  call findocclims(iq, istocc0, istocc, istunocc0, istunocc, isto0, isto, istu0, istu)
  ! find limits for band combinations
  call ematbdcmbs(input%xs%emattype)
  ! generate energy grid
  call genwgrid(nwdf, input%xs%dosWindow%intv, input%xs%tddft%acont, 0.d0, w_cmplx=w)
  ! record length
  inquire(iolength=recl) mdf1(1)
  call getunit(unit1)
  call getunit(unit2)
  ! neglect/include local field effects
  do m=1, n, max(n-1, 1)
     select case(input%xs%tddft%fxctypenumber)
     case(5)
        ! The ALDA kernel does not depend on q in principle, but the G-mesh
        ! depends through its cutoff for G+q on q. It is independent of w.
	call fxcifc(input%xs%tddft%fxctypenumber, iq=iq, ng=m, fxcg=fxc)
        ! add symmetrized Coulomb potential (is equal to unity matrix)
	forall(j=1:m)
	   fxc(j, j)=fxc(j, j)+1.d0
	end forall
     end select
     ! loop over longitudinal components for optics
     do oct1=1, nc
	if (input%xs%dfoffdiag) then
	   octl=1
	   octu=nc
	else
	   octl=oct1
	   octu=oct1
	end if
	do oct2=octl, octu
           ! filename for output file
	   call genfilname(basename = 'IDF', asc = .false., bzsampl = bzsampl, &
		acont = input%xs%tddft%acont, nar = .not.input%xs%tddft%aresdf, nlf = (m.eq.1), &
	fxctype = input%xs%tddft%fxctypenumber, &
		tq0 = tq0, oc1 = oct1, oc2 = oct2, iqmt = iq, procs = procs, rank = rank, &
		filnam = filnam2)
	   open(unit1, file = trim(filnam2), form = 'unformatted', &
		action = 'write', access = 'direct', recl = recl)
	   do iw=wi, wf
	      call chkpt(6, (/task, iq, m, oct1, oct2, iw/), 'task, q - point &
		   &index, loc. field., opt. comp. 1, opt. comp. 2, w - point; &
		   &Dyson equation')
              ! read Kohn-Sham response function
	      call getx0(tq0, iq, iw, trim(filnam), '', chi0, chi0wg, &
		   chi0h)
              ! assign components to main matrix for q=0
	      if (tq0) then
                 ! head
		 chi0(1, 1)=chi0h(oct1, oct2)
                 ! wings
		 if (m.gt.1) then
		    chi0(1, 2:)=chi0wg(2:, 1, oct1)
		    chi0(2:, 1)=chi0wg(2:, 2, oct2)
		 end if
	      end if
              ! generate xc-kernel
	      select case(input%xs%tddft%fxctypenumber)
	      case(0, 1, 2, 3, 4)
		 call fxcifc(input%xs%tddft%fxctypenumber, ng = m, iw = iw, w = w(iw), alrc = input%xs%tddft%alphalrc,&
   alrcd=input%xs%tddft%alphalrcdyn, blrcd=input%xs%tddft%betalrcdyn, fxcg = fxc)
	      case(7, 8)
		 call fxcifc(input%xs%tddft%fxctypenumber, oct = oct1, ng = m, iw = iw, w = w(iw), alrc =&
    &input%xs%tddft%alphalrc, &
		      alrcd=input%xs%tddft%alphalrcdyn, blrcd=input%xs%tddft%betalrcdyn, fxcg = fxc)
	      end select
              ! solve Dyson's equation for the interacting response function
	      select case(input%xs%tddft%fxctypenumber)
	      case(0, 1, 2, 3, 4)
                 ! add symmetrized Coulomb potential (is equal to unity matrix)
		 forall(j=1:m)
		    fxc(j, j)=fxc(j, j)+1.d0
		 end forall
		 call dyson(n, chi0, fxc, idf)
	      case(5)
		 call dyson(n, chi0, fxc, idf)
	      case (7, 8)
                 ! we do not expect the kernel to contain the symmetrized
                 ! Coulomb potential here, the kernel here is expected to be
                 ! multiplied with the KS response function from both sides.
                 ! [F. Sottile, PRL 2003]
		 call dysonsym(n, chi0, fxc, idf)
	      end select
              ! symmetrized inverse dielectric function (add one)
	      forall(j=1:m)
		 idf(j, j)=idf(j, j)+1.d0
	      end forall
              ! Adler-Wiser treatment of macroscopic dielectric function
	      igmt=ivgigq(ivgmt(1, iq), ivgmt(2, iq), ivgmt(3, iq), iq)
	      if (igmt.gt.n) then
		 write(*, *)
		 write(*, '("Error(", a, "): G-vector index for momentum transfer &
		      &out of range: ", i8)') trim(thisnam), igmt
		 write(*, *)
		 call terminate
	      end if
	      if (igmt.ne.1) then
		 write(unitout, *)
		 write(unitout, '("Info(", a, "): non-zero G-vector Fourier component &
		      &for momentum transfer:")') trim(thisnam)
		 write(unitout, '(" index and G-vector:", i8, 3g18.10)') igmt, ivgmt(:, iq)
		 write(unitout, *)
	      end if
	      mdf1(iw)=1.d0/idf(igmt, igmt)
              ! TODO: check if this is possible at all
              ! ??? mimic zero Kronecker delta in case of off-diagonal tensor
              ! components ???
	      if ((m.eq.1).and.(oct1.ne.oct2)) mdf1(iw)=mdf1(iw)-1.d0
              ! write macroscopic dielectric function to file
	      write(unit1, rec=iw-wi+1) mdf1(iw)
	   end do ! iw
	   close(unit1)
           ! end loop over optical components
	end do
     end do
  end do ! m
  ! deallocate
  deallocate(chi0, chi0wg, chi0h, fxc, idf, mdf1, w, chi0hd)
end subroutine idfq
