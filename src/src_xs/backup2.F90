


! Copyright (C) 2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.


subroutine backup2
  use modmain
use modinput
  use modxs
  implicit none
  ngridq_b(:)=ngridq(:)
  if(associated(input%phonons))then
  reduceq_b=input%phonons%reduceq
  endif
end subroutine backup2
