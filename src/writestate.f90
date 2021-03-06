


! Copyright (C) 2002-2005 J. K. Dewhurst, S. Sharma and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

!BOP
! !ROUTINE: writestate
! !INTERFACE:


subroutine writestate
! !USES:
use modinput
use modmain
! !DESCRIPTION:
!   Writes the charge density, potentials and other relevant variables to the
!   file {\tt STATE.OUT}. Note to developers: changes to the way the variables
!   are written should be mirrored in {\tt readstate}.
!
! !REVISION HISTORY:
!   Created May 2003 (JKD)
!EOP
!BOC
implicit none
! local variables
integer::is
open(50, file='STATE'//trim(filext), action='WRITE', form='UNFORMATTED')
write(50) version
write(50) associated(input%groundstate%spin)
write(50) nspecies
write(50) lmmaxvr
write(50) nrmtmax
do is=1, nspecies
  write(50) natoms(is)
  write(50) nrmt(is)
  write(50) spr(1:nrmt(is), is)
end do
write(50) ngrid
write(50) ngvec
write(50) ndmag
write(50) nspinor
write(50) ldapu
write(50) lmmaxlu
! write the density
write(50) rhomt, rhoir
! write the Coulomb potential
write(50) vclmt, vclir
! write the exchange-correlation potential
write(50) vxcmt, vxcir
! write the effective potential
write(50) veffmt, veffir, veffig
! write the magnetisation and effective magnetic fields
if (associated(input%groundstate%spin)) then
  write(50) magmt, magir
  write(50) bxcmt, bxcir
end if
! write the LDA+U potential matrix elements
if (ldapu.ne.0) then
  write(50) vmatlu
end if
close(50)
return
end subroutine
!EOC
