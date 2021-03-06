


! Copyright (C) 2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.


subroutine putbsediag(fname)
  use modxs
  use m_getunit
  implicit none
  ! arguments
  character(*), intent(in) :: fname
  ! local variables
  integer :: un
  call getunit(un)
  open(un, file=trim(fname), action='write', form='formatted', status='replace')
  write(un, '(2g18.10, " : BSE kernel diagonal mean value")') bsed
  write(un, '(2g18.10, " : BSE kernel diagonal lower limit")') bsedl
  write(un, '(2g18.10, " : BSE kernel diagonal upper limit")') bsedu
  write(un, '(2g18.10, " : BSE kernel diagonal window size")') bsedd
  write(un, *)
  write(un, '(2g18.10, " : BSE kernel diagonal mean value (eV)")') bsed*h2ev
  write(un, '(2g18.10, " : BSE kernel diagonal lower limit (eV)")') bsedl*h2ev
  write(un, '(2g18.10, " : BSE kernel diagonal upper limit (eV)")') bsedu*h2ev
  write(un, '(2g18.10, " : BSE kernel diagonal window size (eV)")') bsedd*h2ev
  write(un, *)
  write(un, '(g18.10, " : BSE kernel diagonal deviation (%)")') dble(bsedd)/ &
       dble(bsed)*100.d0
  close(un)
end subroutine putbsediag
