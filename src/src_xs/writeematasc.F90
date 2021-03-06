


! Copyright (C) 2004-2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.


subroutine writeematasc
  use modmain
use modinput
  use modxs
  use m_getunit
  use m_getemat
  use m_genfilname
  implicit none
  character(256) :: filnam
  integer :: un, iq, ik, i, j, ib, jb, igq
  complex(8) :: zt
  call init0
  call init1
  call xssave0
  call init2
  call readfermi
  call getunit(un)
  ! loop over q-points
  do iq=1, nqpt
     call genfilname(iqmt=iq, setfilext=.true.)
     ! calculate k+q and G+k+q related variables
     call init1offs(qvkloff(1, iq))
     ! find highest (partially) occupied and lowest (partially) unoccupied
     ! states
     call findocclims(iq, istocc0, istocc, istunocc0, istunocc, isto0, isto, istu0, &
	  istu)
     ! set limits for band combinations
     call ematbdcmbs(input%xs%emattype)
     if (allocated(xiou)) deallocate(xiou)
     allocate(xiou(nst1, nst2, ngq(iq)))
     if (input%xs%emattype.ne.0) then
	if (allocated(xiuo)) deallocate(xiuo)
	allocate(xiuo(nst3, nst4, ngq(iq)))
     end if
     ! filename for matrix elements file
     call genfilname(basename = 'EMAT', asc = .true., iqmt = iq, etype = input%xs%emattype, &
	  filnam = filnam)
     open(un, file=trim(filnam), action='write')
     ! read matrix elements of exponential expression
     call genfilname(basename='EMAT', iqmt=iq, etype=input%xs%emattype, filnam=fnemat)
     ! loop over k-points
     do ik=1, nkpt
	if (input%xs%emattype.eq.0) then
	   call getemat(iq, ik, .true., trim(fnemat), ngq(iq), istl1, istu1, istl2, &
		istu2, xiou)
	else
	   call getemat(iq, ik, .true., trim(fnemat), ngq(iq), istl1, istu1, istl2, &
		istu2, xiou, istl3, istu3, istl4, istu4, xiuo)
	end if
	do igq=1, ngq(iq)
	   do i=1, nst1
	      ib=i+istl1-1
	      do j=1, nst2
		 jb=j+istl2-1
		 zt=xiou(i, j, igq)
		 write(un, '(5i8, 3g18.10)') iq, ik, igq, ib, jb, zt, abs(zt)**2
	      end do
	   end do
	end do
	do igq=1, ngq(iq)
	   do i=1, nst3
	      ib=i+istl3-1
	      do j=1, nst4
		 jb=j+istl4-1
		 zt=xiuo(i, j, igq)
		 write(un, '(5i8, 3g18.10)') iq, ik, igq, ib, jb, zt, abs(zt)**2
	      end do
	   end do
	end do
     end do ! ik
     close(un)
     deallocate(xiou)
     if (input%xs%emattype.ne.0) deallocate(xiuo)
     ! end loop over q-points
  end do
  call genfilname(setfilext=.true.)
end subroutine writeematasc
