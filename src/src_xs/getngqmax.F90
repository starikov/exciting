
! Copyright (C) 2002-2005 J. K. Dewhurst, S. Sharma and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

!BOP
! !ROUTINE: getngqmax
! !INTERFACE:
subroutine getngqmax
! !USES:
use modmain
use modtddft
! !DESCRIPTION:
!   Determines the largest number of ${\bf G+k}$-vectors with length less than
!   {\tt gkmax} over all the ${\bf k}$-points and stores it in the global
!   variable {\tt ngkmax}. This variable is used for allocating arrays.
!   Based upon getngkmax.
!
! !REVISION HISTORY:
!   Created October 2006 (Sagmeister)
!EOP
!BOC
implicit none
! local variables
integer ispn,iq,i,ig
real(8) v1(3),v2(3),t1,t2
t1=gqmax**2
ngqmax=0
do iq=1,nqpt
   v1(:)=vqc(:,iq)
   i=0
   do ig=1,ngvec
      v2(:)=vgc(:,ig)+v1(:)
      t2=v2(1)**2+v2(2)**2+v2(3)**2
      if (t2.lt.t1) i=i+1
   end do
   ngqmax=max(ngqmax,i)
end do
return
end subroutine getngqmax
!EOC