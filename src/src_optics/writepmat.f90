


! Copyright (C) 2002-2005 J. K. Dewhurst, S. Sharma and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

!BOP
! !ROUTINE: writepmat
! !INTERFACE:


subroutine writepmat
! !USES:
use modinput
use modmain
! !DESCRIPTION:
!   Calculates the momentum matrix elements using routine {\tt genpmat} and
!   writes them to direct access file {\tt PMAT.OUT}.
!
! !REVISION HISTORY:
!   Created November 2003 (Sharma)
!EOP
!BOC
implicit none
! local variables
integer::ik, recl
complex(8), allocatable :: apwalm(:, :, :, :)
complex(8), allocatable :: evecfv(:, :)
complex(8), allocatable :: evecsv(:, :)
complex(8), allocatable :: pmat(:, :, :)
!<sag> -------------------------------------------------------------------------
complex(8), allocatable :: apwcmt(:, :, :, :)
complex(8), allocatable :: locmt(:, :, :, :)
real(8), allocatable :: ripaa(:, :, :, :, :, :)
real(8), allocatable :: ripalo(:, :, :, :, :, :)
real(8), allocatable :: riploa(:, :, :, :, :, :)
real(8), allocatable :: riplolo(:, :, :, :, :, :)
!</sag> ------------------------------------------------------------------------
! initialise universal variables
call init0
call init1
allocate(apwalm(ngkmax, apwordmax, lmmaxapw, natmtot))
allocate(evecfv(nmatmax, nstfv))
allocate(evecsv(nstsv, nstsv))
! allocate the momentum matrix elements array
allocate(pmat(3, nstsv, nstsv))
! read in the density and potentials from file
call readstate
! find the new linearisation energies
call linengy
! generate the APW radial functions
call genapwfr
! generate the local-orbital radial functions
call genlofr
!<sag> -------------------------------------------------------------------------
allocate(ripaa(apwordmax, lmmaxapw, apwordmax, lmmaxapw, natmtot, 3))
allocate(apwcmt(nstsv, apwordmax, lmmaxapw, natmtot))
if (nlotot.gt.0) then
   allocate(ripalo(apwordmax, lmmaxapw, nlomax, -lolmax:lolmax, natmtot, 3))
   allocate(riploa(nlomax, -lolmax:lolmax, apwordmax, lmmaxapw, natmtot, 3))
   allocate(riplolo(nlomax, -lolmax:lolmax, nlomax, -lolmax:lolmax, natmtot, 3))
   allocate(locmt(nstsv, nlomax, -lolmax:lolmax, natmtot))
end if
! calculate gradient of radial functions times spherical harmonics
call pmatrad(ripaa, ripalo, riploa, riplolo)
!</sag> ------------------------------------------------------------------------
! find the record length
inquire(iolength=recl) pmat
open(50, file = 'PMAT.OUT', action = 'WRITE', form = 'UNFORMATTED', access = 'DIRECT', &
 status = 'REPLACE', recl = recl)
do ik=1, nkpt
! get the eigenvectors from file
  call getevecfv(vkl(:, ik), vgkl(:, :, :, ik), evecfv)
  call getevecsv(vkl(:, ik), evecsv)
! find the matching coefficients
  call match(ngk(1, ik), gkc(:, 1, ik), tpgkc(:, :, 1, ik), sfacgk(:, :, 1, ik), apwalm)
!<sag> -------------------------------------------------------------------------
! generate APW expansion coefficients for muffin-tin
  call genapwcmt(input%groundstate%lmaxapw, ngk(1, ik), 1, nstfv, apwalm, evecfv, apwcmt)
! generate local orbital expansion coefficients for muffin-tin
  if (nlotot.gt.0) call genlocmt(ngk(1, ik), 1, nstfv, evecfv, locmt)
! calculate the momentum matrix elements
  call genpmat2(ngk(1, ik), igkig(:, 1, ik), vgkc(:, :, 1, ik), ripaa, ripalo, &
       riploa, riplolo, apwcmt, locmt, evecfv, evecsv, pmat)
!</sag> ------------------------------------------------------------------------
! calculate the momentum matrix elements
!!$  call genpmat(ngk(1,ik),igkig(:,1,ik),vgkc(:,:,1,ik),apwalm,evecfv,evecsv,pmat)
! write the matrix elements to direct-access file
  write(50, rec=ik) pmat
end do
close(50)
write(*, *)
write(*, '("Info(writepmat):")')
write(*, '(" momentum matrix elements written to file PMAT.OUT")')
write(*, *)
deallocate(apwalm, evecfv, evecsv, pmat)
!<sag> -------------------------------------------------------------------------
deallocate(ripaa, apwcmt)
if (nlotot.gt.0) deallocate(ripalo, riploa, riplolo, locmt)
!</sag> ------------------------------------------------------------------------
end subroutine
!EOC
