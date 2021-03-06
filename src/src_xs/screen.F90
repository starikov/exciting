


! Copyright (C) 2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.


subroutine screen
  use modxs
use modinput
  use m_genfilname
  implicit none
  ! local variables
  integer :: nwdft
  nwdft=nwdf
  call genfilname(dotext='_SCR.OUT',setfilext=.true.)
  ! call dielectric function with only one frequency point
  call df
  ! alternative for checking only:
  nwdf=nwdft
  write(unitout,'(a)') "Info(screen): Screening finished"
end subroutine screen
