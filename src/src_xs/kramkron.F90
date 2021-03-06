


! Copyright (C) 2007-2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

!BOP
! !ROUTINE: kramkron
! !INTERFACE:


subroutine kramkron(i1, i2, eps, n, w, im, re)
! !INPUT/OUTPUT PARAMETERS:
!   i1,i2 : tensor components of dielectric function tensor (in,integer)
!   eps   : zero frequency tolerance
!   n     : number of frequency points (in,integer)
!   w     : frequency grid (in,real(n))
!   im    : imaginary part of dielectric function tensor component (in,real(n))
!   re    : real part of dielectric function tensor component (out,real(n))
! !DESCRIPTION:
!   Algorithm taken from routine {\tt linopt}.
!
! !REVISION HISTORY:
!   Created November 2007 (Sagmeister)
!EOP
!BOC
  implicit none
  ! arguments
  integer, intent(in) :: i1, i2
  real(8), intent(in) :: eps
  integer, intent(in) :: n
  real(8), intent(in) :: w(n), im(n)
  real(8), intent(out) :: re(n)
  ! local variables
  real(8), parameter :: pi=3.1415926535897932385d0
  integer :: iw, jw
  real(8) :: t1, t2
  real(8), allocatable :: fw(:), g(:), cf(:, :)
  allocate(fw(n), g(n), cf(3, n))
  t1=0.d0
  g(:)=0.d0
  if (i1.eq.i2) t1=1.d0
  do iw=1, n
     do jw=1, n
	t2=w(jw)**2-w(iw)**2
        ! tolerance for range of integrand part w'/(w^2-w'^2)
	if (abs(t2).gt.eps) then
	   fw(jw)=w(jw)*im(jw)/t2
	else
	   fw(jw)=0.d0
	end if
     end do
     call fderiv(-1, n, w, fw, g, cf)
     re(iw)=t1+(2.d0/pi)*g(n)
  end do
  deallocate(fw, g, cf)
end subroutine kramkron
