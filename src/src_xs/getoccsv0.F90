


! Copyright (C) 2007-2008 S. Sagmeister J. K. Dewhurst, S. Sharma and 
! C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.


subroutine getoccsv0(vpl, occsvp)
  use modmain
  use modxs
  ! arguments
  real(8), intent(in) :: vpl(3)
  real(8), intent(out) :: occsvp(nstsv)
  ! local variables
  real(8), allocatable :: vklt(:, :)
  character(256) :: filextt

  ! copy varialbes of k+(q=0) to default variables
  allocate(vklt(3, nkptnr))
  vklt(:, :)=vkl(:, :); vkl(:, :)=vkl0(:, :)
  filextt=filext

  ! call to getevalsv with changed (G+)k-point sets / matrix size
  call genfilextread(task)
  call getoccsv(vpl, occsvp)

  ! restore original variables
  vkl(:, :)=vklt(:, :)
  filext=filextt
  deallocate(vklt)

end subroutine getoccsv0
