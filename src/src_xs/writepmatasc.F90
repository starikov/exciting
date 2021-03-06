


! Copyright (C) 2004-2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.


subroutine writepmatasc
  use modmain
  use modxs
  use m_getunit
  use m_getpmat
  implicit none
  complex(8), allocatable :: pmat(:, :, :)
  integer :: un, ik, ist1, ist2, oct
  ! initialize global variables
  call init0
  call init1
  call init2
  allocate(pmat(3, nstsv, nstsv))
  call getunit(un)
  open(un, file='PMAT_XS_ASC.OUT', action='write')
  do ik=1, nkpt
     ! read momentum matrix elements if required
     call getpmat(ik, vkl, 1, nstsv, 1, nstsv, .true., 'PMAT_XS.OUT', pmat)
     do ist1=1, nstsv
	do ist2=1, nstsv
	   do oct=1, 3
	      write(un, '(3i8, i4, 4g18.10)') ik, ist1, ist2, oct, &
		   pmat(oct, ist1, ist2), &
		   abs(pmat(oct, ist1, ist2)), &
		   abs(pmat(oct, ist2, ist1) - conjg(pmat(oct, ist1, ist2)))
	   end do
	end do
     end do
  end do
  close(un)
  deallocate(pmat)
end subroutine writepmatasc
