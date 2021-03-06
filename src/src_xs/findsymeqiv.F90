


! Copyright (C) 2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.


subroutine findsymeqiv(tfbz, vpl, vplr, nsc, sc, ivgsc)
  use modmain
use modinput
  implicit none
  ! arguments
  logical, intent(in) :: tfbz
  real(8), intent(in) :: vpl(3), vplr(3)
  integer, intent(out) :: nsc, sc(maxsymcrys), ivgsc(3, maxsymcrys)
  ! local variables
  integer :: isym, lspl, iv(3)
  real(8) :: s(3, 3), v1(3), t1
  real(8), external :: r3taxi
  ! symmetries that transform non-reduced q-point to reduced one, namely
  ! vpl = s^-1 * vplr + G_s
  nsc=0
  do isym=1, nsymcrys
     lspl=lsplsymc(isym)
     s(:, :)=dble(symlat(:, :, lspl))
     call r3mtv(s, vplr, v1)
     if (tfbz) then
	call vecfbz(input%structure%epslat, bvec, v1, iv)
     else
	call r3frac(input%structure%epslat, v1, iv)
     end if
     t1=r3taxi(vpl, v1)
     if (t1.lt.input%structure%epslat) then
	nsc=nsc+1
	sc(nsc)=isym
	ivgsc(:, nsc)=-iv(:)
     end if
  end do
  if (nsc.eq.0) then
     write(*, *)
     write(*, '("Error(findsymeqiv): p-points are not equivalent by symmetry")')
     write(*, '(" vpl  :", 3g18.10)') vpl
     write(*, '(" vplr :", 3g18.10)') vplr
     write(*, *)
     call terminate
  end if
end subroutine findsymeqiv
