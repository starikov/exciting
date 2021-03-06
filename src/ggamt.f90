


! Copyright (C) 2002-2005 J. K. Dewhurst, S. Sharma and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

!BOP
! !ROUTINE: ggamt
! !INTERFACE:


subroutine ggamt(is, ia, grhomt, gupmt, gdnmt, g2upmt, g2dnmt, g3rhomt, g3upmt, g3dnmt)
! !USES:
use modinput
use modmain
! !INPUT/OUTPUT PARAMETERS:
!   is      : species number (in,integer)
!   ia      : atom number (in,integer)
!   grhomt  : |grad rho| (out,real(lmmaxvr,nrmtmax))
!   gupmt   : |grad rhoup| (out,real(lmmaxvr,nrmtmax))
!   gdnmt   : |grad rhodn| (out,real(lmmaxvr,nrmtmax))
!   g2upmt  : grad^2 rhoup (out,real(lmmaxvr,nrmtmax))
!   g2dnmt  : grad^2 rhodn (out,real(lmmaxvr,nrmtmax))
!   g3rhomt : (grad rho).(grad |grad rho|) (out,real(lmmaxvr,nrmtmax))
!   g3upmt  : (grad rhoup).(grad |grad rhoup|) (out,real(lmmaxvr,nrmtmax))
!   g3dnmt  : (grad rhodn).(grad |grad rhodn|) (out,real(lmmaxvr,nrmtmax))
! !DESCRIPTION:
!   Computes $|\nabla\rho|$, $|\nabla\rho^{\uparrow}|$,
!   $|\nabla\rho^{\downarrow}|$, $\nabla^2\rho^{\uparrow}$,
!   $\nabla^2\rho^{\downarrow}$, $\nabla\rho\cdot(\nabla|\nabla\rho|)$,
!   $\nabla\rho^{\uparrow}\cdot(\nabla|\nabla\rho^{\uparrow}|)$ and
!   $\nabla\rho^{\downarrow}\cdot(\nabla|\nabla\rho^{\downarrow}|)$
!   for a muffin-tin charge density, as required by the generalised gradient
!   approximation functional for spin-polarised densities. In the case of spin
!   unpolarised calculations, $|\nabla\rho|$, $\nabla^2\rho$ and
!   $\nabla\rho\cdot(\nabla|\nabla\rho|)$ are returned in the arrays
!   {\tt gupmt}, {\tt g2upmt} and {\tt g3upmt}, respectively, while
!   {\tt grhomt}, {\tt gdnmt}, {\tt g2dnmt}, {\tt g3rhomt} and {\tt g3dnmt} are
!   not referenced. The input densities are in terms of real spherical harmonic
!   expansions but the returned functions are in spherical coordinates. See
!   routines {\tt potxc}, {\tt modxcifc}, {\tt gradrfmt}, {\tt genrlm} and
!   {\tt genshtmat}.
!
! !REVISION HISTORY:
!   Created April 2004 (JKD)
!EOP
!BOC
implicit none
! arguments
integer, intent(in) :: is
integer, intent(in) :: ia
real(8), intent(out) :: grhomt(lmmaxvr, nrmtmax)
real(8), intent(out) :: gupmt(lmmaxvr, nrmtmax)
real(8), intent(out) :: gdnmt(lmmaxvr, nrmtmax)
real(8), intent(out) :: g2upmt(lmmaxvr, nrmtmax)
real(8), intent(out) :: g2dnmt(lmmaxvr, nrmtmax)
real(8), intent(out) :: g3rhomt(lmmaxvr, nrmtmax)
real(8), intent(out) :: g3upmt(lmmaxvr, nrmtmax)
real(8), intent(out) :: g3dnmt(lmmaxvr, nrmtmax)
! local variables
integer::ias, nr, ir, i, itp
! allocatable arrays
real(8), allocatable :: rfmt1(:, :)
real(8), allocatable :: rftp1(:, :, :)
real(8), allocatable :: rftp2(:, :, :)
real(8), allocatable :: rftp3(:)
real(8), allocatable :: grfmt1(:, :, :)
real(8), allocatable :: grfmt2(:, :, :)
allocate(rfmt1(lmmaxvr, nrmtmax))
allocate(rftp1(lmmaxvr, nrmtmax, 3))
allocate(rftp2(lmmaxvr, nrmtmax, 3))
allocate(rftp3(lmmaxvr))
allocate(grfmt1(lmmaxvr, nrmtmax, 3))
allocate(grfmt2(lmmaxvr, nrmtmax, 3))
ias=idxas(ia, is)
nr=nrmt(is)
if (associated(input%groundstate%spin)) then
! rhoup for spin-polarised case
  rfmt1(:, 1:nr)=0.5d0*(rhomt(:, 1:nr, ias)+magmt(:, 1:nr, ias, ndmag))
else
! rho for spin-unpolarised case
  rfmt1(:, 1:nr)=rhomt(:, 1:nr, ias)
end if
! |grad rhoup|
call gradrfmt(input%groundstate%lmaxvr, nr, spr(:, is), lmmaxvr, nrmtmax, rfmt1, grfmt1)
do ir=1, nr
  do i=1, 3
    call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rbshtvr, lmmaxvr, grfmt1(:, ir, i), 1, 0.d0, &
     rftp1(:, ir, i), 1)
  end do
  do itp=1, lmmaxvr
    gupmt(itp, ir)=sqrt(rftp1(itp, ir, 1)**2+rftp1(itp, ir, 2)**2+rftp1(itp, ir, 3)**2)
  end do
end do
! grad^2 rhoup
g2upmt(:, 1:nr)=0.d0
do i=1, 3
  call gradrfmt(input%groundstate%lmaxvr, nr, spr(:, is), lmmaxvr, nrmtmax, grfmt1(:, :, i), grfmt2)
  do ir=1, nr
    call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rbshtvr, lmmaxvr, grfmt2(:, ir, i), 1, 1.d0, &
     g2upmt(:, ir), 1)
  end do
end do
! (grad rhoup).(grad |grad rhoup|)
do ir=1, nr
  call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rfshtvr, lmmaxvr, gupmt(:, ir), 1, 0.d0, &
   rfmt1(:, ir), 1)
end do
call gradrfmt(input%groundstate%lmaxvr, nr, spr(:, is), lmmaxvr, nrmtmax, rfmt1, grfmt1)
g3upmt(:, 1:nr)=0.d0
do i=1, 3
  do ir=1, nr
    call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rbshtvr, lmmaxvr, grfmt1(:, ir, i), 1, 0.d0, &
     rftp3, 1)
    do itp=1, lmmaxvr
      g3upmt(itp, ir)=g3upmt(itp, ir)+rftp1(itp, ir, i)*rftp3(itp)
    end do
  end do
end do
if (associated(input%groundstate%spin)) then
! rhodn
  rfmt1(:, 1:nr)=0.5d0*(rhomt(:, 1:nr, ias)-magmt(:, 1:nr, ias, ndmag))
! |grad rhodn|
  call gradrfmt(input%groundstate%lmaxvr, nr, spr(:, is), lmmaxvr, nrmtmax, rfmt1, grfmt1)
  do ir=1, nr
    do i=1, 3
      call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rbshtvr, lmmaxvr, grfmt1(:, ir, i), 1, &
       0.d0, rftp2(:, ir, i), 1)
    end do
    do itp=1, lmmaxvr
      gdnmt(itp, ir) = sqrt(rftp2(itp, ir, 1) ** 2 + rftp2(itp, ir, 2) ** 2 &
       +rftp2(itp, ir, 3) ** 2)
    end do
  end do
! grad^2 rhodn
  g2dnmt(:, 1:nr)=0.d0
  do i=1, 3
    call gradrfmt(input%groundstate%lmaxvr, nr, spr(:, is), lmmaxvr, nrmtmax, grfmt1(:, :, i), grfmt2)
    do ir=1, nr
      call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rbshtvr, lmmaxvr, grfmt2(:, ir, i), 1, &
       1.d0, g2dnmt(:, ir), 1)
    end do
  end do
! (grad rhodn).(grad |grad rhodn|)
  do ir=1, nr
    call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rfshtvr, lmmaxvr, gdnmt(:, ir), 1, 0.d0, &
     rfmt1(:, ir), 1)
  end do
  call gradrfmt(input%groundstate%lmaxvr, nr, spr(:, is), lmmaxvr, nrmtmax, rfmt1, grfmt1)
  g3dnmt(:, 1:nr)=0.d0
  do i=1, 3
    do ir=1, nr
      call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rbshtvr, lmmaxvr, grfmt1(:, ir, i), 1, &
       0.d0, rftp3, 1)
      do itp=1, lmmaxvr
	g3dnmt(itp, ir)=g3dnmt(itp, ir)+rftp2(itp, ir, i)*rftp3(itp)
      end do
    end do
  end do
! |grad rho|
  do ir=1, nr
    do itp=1, lmmaxvr
      grhomt(itp, ir) = sqrt((rftp1(itp, ir, 1) + rftp2(itp, ir, 1)) ** 2 &
			 +(rftp1(itp, ir, 2) + rftp2(itp, ir, 2)) ** 2 &
			 +(rftp1(itp, ir, 3) + rftp2(itp, ir, 3)) ** 2)
    end do
  end do
! (grad rho).(grad |grad rho|)
  do ir=1, nr
    call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rfshtvr, lmmaxvr, grhomt(:, ir), 1, 0.d0, &
     rfmt1(:, ir), 1)
  end do
  call gradrfmt(input%groundstate%lmaxvr, nr, spr(:, is), lmmaxvr, nrmtmax, rfmt1, grfmt1)
  g3rhomt(:, 1:nr)=0.d0
  do i=1, 3
    do ir=1, nr
      call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rbshtvr, lmmaxvr, grfmt1(:, ir, i), 1, &
       0.d0, rftp3, 1)
      do itp=1, lmmaxvr
	g3rhomt(itp, ir) = g3rhomt(itp, ir) &
	 +(rftp1(itp, ir, i) + rftp2(itp, ir, i)) * rftp3(itp)
      end do
    end do
  end do
end if
deallocate(rfmt1, rftp1, rftp2, rftp3, grfmt1, grfmt2)
return
end subroutine
!EOC
