


! Copyright (C) 2004-2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.


subroutine tetcalccwq(iq)
  use modmain
use modinput
  use modxs
  use modtetra
  use modmpi
  use m_genwgrid
  use m_puttetcw
  use m_getunit
  use m_filedel
  use m_genfilname
  implicit none
  ! arguments
  integer, intent(in) :: iq
  ! local variables
  character(*), parameter :: thisnam='tetcalccwq'
  character(256) :: filnam, filnamt
  complex(8), allocatable :: w(:)
  real(8), parameter :: epstetra=1.d-8
  real(8), allocatable :: eb(:, :)
  real(8), allocatable :: wreal(:)
  real(8), allocatable :: cwsurft2(:, :), cwt2(:, :), cwat2(:, :)
  real(8), allocatable :: cwsurft1(:), cwt1(:), cwat1(:)
  real(8), allocatable :: cwsurf(:, :, :), cw(:, :, :), cwa(:, :, :)
  real(8) :: wt
  integer :: ik, ist1, ist2
  integer :: iw, wi, wf, nwdfp, un, recl, irec
  ! calculate k+q and G+k+q related variables
  call init1offs(qvkloff(1, iq))
  ! generate link array for tetrahedra
  call gentetlinkp(vql(1, iq), input%xs%tetra%qweights)
  ! initial and final w-point
  wi=wpari
  wf=wparf
  nwdfp=wf-wi+1
  if (tscreen) then
     ! generate filenames
     call genfilname(basename = 'TETW', iq = iq, rank = rank, procs = procs, &
	  appfilext = .true., filnam = filnam)
     call genfilname(basename = 'TETWT', iq = iq, rank = rank, procs = procs, &
	  appfilext = .true., filnam = filnamt)
  else
     ! set q-dependent file extension
     call genfilname(iqmt=iq, setfilext=.true.)
     ! generate filenames
     call genfilname(basename = 'TETW', iqmt = iq, rank = rank, procs = procs, &
	  filnam = filnam)
     call genfilname(basename = 'TETWT', iqmt = iq, rank = rank, procs = procs, &
	  filnam = filnamt)
  end if
  ! find highest (partially) occupied and lowest (partially) unoccupied states
  call findocclims(iq, istocc0, istocc, istunocc0, istunocc, isto0, isto, istu0, istu)
  ! find band combinations
  call ematbdcmbs(input%xs%emattype)
  ! allocate arrays
  allocate(eb(nstsv, nkpt))
  allocate(cw(nstsv, nstsv, nkpt))
  allocate(cwa(nstsv, nstsv, nkpt))
  allocate(cwsurf(nstsv, nstsv, nkpt))
  allocate(cwt2(nst1, nst2), cwat2(nst1, nst2), cwsurft2(nst1, nst2))
  allocate(w(nwdf))
  allocate(wreal(nwdfp))
  ! get the eigenvalues from file
  do ik=1, nkpt
     call getevalsv(vkl(1, ik), evalsv(1, ik))
  end do
  eb(:, :)=evalsv(:, :)
  ! scissors shift
  where (eb.gt.efermi) eb=eb+input%xs%scissor
  ! generate complex energy grid
  call genwgrid(nwdf, input%xs%dosWindow%intv, input%xs%tddft%acont, 0.d0, w_cmplx=w)
  wreal(:)=dble(w(wi:wf))
  ! TODO: replace zero frequency by very small number *** check if needed
  if (wreal(1).lt.epstetra) wreal(1)=epstetra
  call getunit(un)
  inquire(iolength=recl) cwt2, cwat2, cwsurft2
  ! open temporary file for writing
  open(un, file = trim(filnamt), form = 'unformatted', &
       action = 'write', status = 'replace', access = 'direct', recl = recl)
  ! calculate weights
  do iw=1, nwdfp
     if ((modulo(iw, max(nwdfp/10, 1)).eq.0).or.(iw.eq.nwdfp)) &
	  write( * , '("Info(tetcalccwq): tetrahedron weights for ", I6, " of ", &
	  &I6, " w-points")') iw, nwdfp
     wt=wreal(iw)
     ! switch 2 below in tetcw defines bulk integration for real part
     ! resonant contribution
     call tetcwifc(nkpt, nstsv, eb, efermi, wt, 2, cw)
     ! anti-resonant contribution
     call tetcwifc(nkpt, nstsv, eb, efermi, -wt, 2, cwa)
     ! switch 4 below in tetcw defines surface integration for imag. part
     call tetcwifc(nkpt, nstsv, eb, efermi, wt, 4, cwsurf)
     do ik=1, nkpt
	irec=(ik-1)*nwdfp+iw
	cwsurft2(:, :)=cwsurf(istl1:istu1, istl2:istu2, ik)
	cwt2(:, :)=cw(istl1:istu1, istl2:istu2, ik)
	cwat2(:, :)=cwa(istl1:istu1, istl2:istu2, ik)
	write(un, rec=irec) cwt2, cwat2, cwsurft2
     end do
     ! synchronize for common number of w-points to all processes
     if (iw <= nwdf/procs) call barrier
  end do
  close(un)
  deallocate(cw, cwa, cwsurf)
  allocate(cw(nwdfp, nst1, nst2))
  allocate(cwa(nwdfp, nst1, nst2))
  allocate(cwsurf(nwdfp, nst1, nst2))
  allocate(cwsurft1(nwdfp), cwt1(nwdfp), cwat1(nwdfp))
  ! open temporary file for reading
  open(un, file = trim(filnamt), form = 'unformatted', action = 'read', &
       status = 'old', access = 'direct', recl = recl)
  irec=0
  do ik=1, nkpt
     do iw=1, nwdfp
	irec=irec+1
	read(un, rec=irec) cwt2, cwat2, cwsurft2
	cw(iw, :, :)=cwt2(:, :)
	cwa(iw, :, :)=cwat2(:, :)
	cwsurf(iw, :, :)=cwsurft2(:, :)
     end do
     do ist1=1, nst1
	do ist2=1, nst2
	   cwsurft1(:)=cwsurf(:, ist1, ist2)
	   cwt1(:)=cw(:, ist1, ist2)
	   cwat1(:)=cwa(:, ist1, ist2)
           ! routine cares for record position
	   call puttetcw(iq, ik, ist1, ist2, nst1, nst2, filnam, cwt1, cwat1, cwsurft1)
	end do
     end do
  end do
  close(un)
  call filedel(trim(filnamt))
  deallocate(cwt2, cwat2, cwsurft2)
  deallocate(cw, cwa, cwsurf, eb)
  deallocate(cwt1, cwat1, cwsurft1)
  deallocate(w, wreal)
  write(unitout, '(a)') 'Info('//trim(thisnam)//'): weights for tetrahedron &
       &method finished.'
end subroutine tetcalccwq
