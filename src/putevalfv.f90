


! Copyright (C) 2007 J. K. Dewhurst, S. Sharma and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.


subroutine putevalfv(ik, evalfv)
  use modmain
  use modmpi
  implicit none
  ! arguments
  integer, intent(in) :: ik
  real(8), intent(in) :: evalfv(nstfv, nspnfv)

  ! local variables
  integer::recl, koffset   
   character(256) ::filetag
   character(256), external:: outfilenamestring

  !find the record length
  inquire(iolength=recl) vkl(:, ik), nstfv, nspnfv, evalfv
!$OMP CRITICAL
filetag='EVALFV'
if (splittfile.or.(rank.eq.0)) then
  open(70, file = outfilenamestring(filetag, ik), action = 'WRITE', &
       form = 'UNFORMATTED', access = 'DIRECT', recl = recl)
 if (splittfile) then
 koffset=ik-firstk(procofk(ik))+1
 else
 koffset =ik
 endif
write(70, rec=koffset)vkl(:, ik), nstfv, nspnfv, evalfv
  close(70)

endif
!$OMP END CRITICAL
  return
end subroutine putevalfv
