



! Copyright (C) 2002-2005 J. K. Dewhurst, S. Sharma and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.


subroutine wfplot (dostm)
use modmain
use modinput
implicit none
logical,intent(in)::dostm
! local variables
integer::ik, ist
real(8)::x, t1
! allocatable arrays
complex(8), allocatable :: evecfv(:, :)
complex(8), allocatable :: evecsv(:, :)
! external functions
real(8)::sdelta
external sdelta
! initialise universal variables
call init0
call init1
allocate(evecfv(nmatmax, nstfv))
allocate(evecsv(nstsv, nstsv))
! read the density and potentials from file
call readstate
! read Fermi energy from file
call readfermi
! find the new linearisation energies
call linengy
! generate the APW radial functions
call genapwfr
! generate the local-orbital radial functions
call genlofr
! set the occupancies
if (.not. dostm) then
  ik=kstlist(1, 1)
  ist=kstlist(2, 1)
  if ((ik.lt.1).or.(ik.gt.nkpt)) then
    write(*, *)
    write(*, '("Error(wfplot): k-point out of range : ", I8)') ik
    write(*, *)
    stop
  end if
  if ((ist.lt.1).or.(ist.gt.nstsv)) then
    write(*, *)
    write(*, '("Error(wfplot): state out of range : ", I8)') ist
    write(*, *)
    stop
  end if
! plotting a single wavefunction
  occsv(:, :)=0.d0
  occsv(ist, ik)=1.d0
else
! plotting an STM image by setting occupancies to be a delta function at the
! Fermi energy
  t1=1.d0/input%groundstate%swidth
  do ik=1, nkpt
! get the eigenvalues from file
    call getevalsv(vkl(:, ik), evalsv(:, ik))
    do ist=1, nstsv
      x=(efermi-evalsv(ist, ik))*t1
      occsv(ist, ik)=occmax*wkpt(ik)*sdelta(input%groundstate%stypenumber, x)*t1
    end do
  end do
end if
! set the charge density to zero
rhomt(:, :, :)=0.d0
rhoir(:)=0.d0
! compute the charge density with the new occupancies
do ik=1, nkpt
! get the eigenvectors from file
  call getevecfv(vkl(:, ik), vgkl(:, :, :, ik), evecfv)
  call getevecsv(vkl(:, ik), evecsv)
  call rhovalk(ik, evecfv, evecsv)
end do
! symmetrise the density for the STM plot
if (dostm) then
  call symrf(input%groundstate%lradstep, rhomt, rhoir)
end if
! convert the density from a coarse to a fine radial mesh
call rfmtctof(rhomt)
! write the wavefunction modulus squared plot to file
if(associated(input%properties%wfplot%plot1d)) then
  call plot1d("WF", 1, input%groundstate%lmaxvr, lmmaxvr, rhomt, rhoir,input%properties%wfplot%plot1d)
  write(*, *)
  write(*, '("Info(wfplot):")')
  write(*, '(" 1D wavefunction modulus squared written to WF1D.OUT")')
  write(*, '(" vertex location lines written to WFLINES.OUT")')
endif
if(associated(input%properties%wfplot%plot2d)) then
  call plot2d("WF", 1, input%groundstate%lmaxvr, lmmaxvr, rhomt, rhoir,input%properties%wfplot%plot2d)
  write(*, *)
  write(*, '("Info(wfplot):")')
  write(*, '(" 2D wavefunction modulus squared written to WF2D.OUT")')
  endif
if(dostm) then
  call plot2d("STM", 1, input%groundstate%lmaxvr, lmmaxvr, rhomt, rhoir,input%properties%STM%plot2d)
  write(*, *)
  write(*, '("Info(wfplot):")')
  write(*, '(" 2D STM image written to STM2D.OUT")')
  endif
if(associated(input%properties%wfplot%plot3d)) then
  call plot3d("WF", 1, input%groundstate%lmaxvr, lmmaxvr, rhomt, rhoir,input%properties%wfplot%plot3d)
  write(*, *)
  write(*, '("Info(wfplot):")')
  write(*, '(" 3D wavefunction modulus squared written to WF3D.OUT")')
endif
if (.not. dostm) then
  write(*, '(" for k-point ", I6, " and state ", I6)') kstlist(1, 1), kstlist(2, 1)
end if
write(*, *)
deallocate(evecfv, evecsv)
return
end subroutine
