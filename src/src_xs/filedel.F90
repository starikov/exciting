


! Copyright (C) 2005-2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

module m_filedel
  implicit none
contains


subroutine filedel(fnam)
    use m_getunit
    implicit none
    ! arguments
    character(*), intent(in) :: fnam
    ! local variables
    integer, parameter :: verb=0
    integer :: un
    logical :: existent, opened
    ! check if file exists
    inquire(file=trim(fnam), exist=existent)
    if ((verb.gt.0).and.(.not.existent)) then
       write(*, '("Warning(filedel): attempted to delete non-existent file: ", &
	    &a)') trim(fnam)
       return
    end if
    ! check if file is opened
    inquire(file=trim(fnam), opened=opened, number=un)
    ! close file if opened
    if (opened) then
       close(un)
    end if
    ! open file for writing
    call getunit(un)
    open(un, file=trim(fnam), action='write')
    ! delete file
    close(un, status='delete')
  end subroutine filedel

end module m_filedel
