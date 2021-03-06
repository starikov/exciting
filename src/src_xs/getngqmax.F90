


! Copyright (C) 2006-2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

!BOP
! !ROUTINE: getngqmax
! !INTERFACE:


subroutine getngqmax
! !USES:
use modinput
use modmain
use modxs
! !DESCRIPTION:
!   Determines the largest number of ${\bf G+q}$-vectors with length less than
!   {\tt gqmax} over all the ${\bf q}$-points and stores it in the global
!   variable {\tt ngqmax}. This variable is used for allocating arrays.
!   Based upon the routine {\tt getngkmax}.
!
! !REVISION HISTORY:
!   Created October 2006 (Sagmeister)
!EOP
!BOC
implicit none
! local variables
integer::iq, i, j, ig
real(8)::v1(3), v2(3), t1, t2
if (input%xs%gqmax.lt.input%structure%epslat) then
   intgqv(:, :)=0
   ngqmax=1
   ngridgq(:)=1
   return
end if
t1=input%xs%gqmax**2
intgqv(:, :)=0
ngqmax=0
do iq=1, nqpt
   v1(:)=vqc(:, iq)
   i=0
   do ig=1, ngvec
      v2(:)=vgc(:, ig)+v1(:)
      t2=v2(1)**2+v2(2)**2+v2(3)**2
      if (t2.lt.t1) then
	 i=i+1
	 do j=1, 3
	    intgqv(j, 1)=min(intgqv(j, 1), ivg(j, ig))
	    intgqv(j, 2)=max(intgqv(j, 2), ivg(j, ig))
	 end do
      end if
   end do
   ngqmax=max(ngqmax, i)
end do
ngridgq(:)=intgqv(:, 2)-intgqv(:, 1)+1
! debug output
if (input%xs%dbglev.gt.1) then
   write(*, '(a)') 'Debug(getngqmax): intgqv:'
   write(*, '(2i6)') intgqv(1, 1), intgqv(1, 2)
   write(*, '(2i6)') intgqv(2, 1), intgqv(2, 2)
   write(*, '(2i6)') intgqv(3, 1), intgqv(3, 2)
   write(*, *)
end if
if (ngqmax.lt.1) then
   write(*, *)
   write(*, '("Error(getngqmax): no G-vectors found - increase gqmax")')
   write(*, *)
   call terminate
end if
end subroutine getngqmax
!EOC
