


! Copyright (C) 2007 J. K. Dewhurst, S. Sharma and E. K. U. Gross.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.


subroutine genkinmat
! generates kinetic matrix elements for all states and k-points
use modinput
use modmain
implicit none
! local variables
integer::is, ia, ias, idm
integer::ik, ist, ir, irc
! allocatable arrays
real(8), allocatable :: rfmt(:, :, :)
real(8), allocatable :: rvfmt(:, :, :, :)
real(8), allocatable :: evalfv(:, :)
complex(8), allocatable :: apwalm(:, :, :, :)
complex(8), allocatable :: evecfv(:, :)
complex(8), allocatable :: evecsv(:, :)
complex(8), allocatable :: wfmt(:, :, :, :, :)
complex(8), allocatable :: wfir(:, :, :)
complex(8), allocatable :: vmat(:, :)
complex(8), allocatable :: bmat(:, :)
complex(8), allocatable :: c(:, :)
! allocate local arrays
allocate(rfmt(lmmaxvr, nrcmtmax, natmtot))
allocate(evalfv(nstfv, nspnfv))
if (associated(input%groundstate%spin)) allocate(rvfmt(lmmaxvr, nrcmtmax, natmtot, ndmag))
allocate(apwalm(ngkmax, apwordmax, lmmaxapw, natmtot))
allocate(evecfv(nmatmax, nstfv))
allocate(evecsv(nstsv, nstsv))
allocate(wfmt(lmmaxvr, nrcmtmax, natmtot, nspinor, nstsv))
allocate(wfir(ngrtot, nspinor, nstsv))
allocate(vmat(nstsv, nstsv))
allocate(bmat(nstsv, nstsv))
allocate(c(nstsv, nstsv))
! convert muffin-tin effective potential and magnetic field to spherical
! coordinates
do is=1, nspecies
  do ia=1, natoms(is)
    ias=idxas(ia, is)
    irc=0
    do ir=1, nrmt(is), input%groundstate%lradstep
      irc=irc+1
      call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rbshtvr, lmmaxvr, veffmt(:, ir, ias), 1, &
       0.d0, rfmt(:, irc, ias), 1)
      do idm=1, ndmag
	call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rbshtvr, lmmaxvr, &
	 bxcmt(:, ir, ias, idm), 1, 0.d0, rvfmt(:, irc, ias, idm), 1)
      end do
    end do
  end do
end do
! loop over k-points
do ik=1, nkpt
! solve the first- and second-variational secular equations
  call seceqn(ik, evalfv, evecfv, evecsv)
! write the first variational eigenvalues/vectors to file (this ensures the
! phase in eigenvectors is the same for subsequent matrix element evaluations)
  call putevalfv(ik, evalfv)
  call putevecfv(ik, evecfv)
! find the matching coefficients
  call match(ngk(1, ik), gkc(:, 1, ik), tpgkc(:, :, 1, ik), sfacgk(:, :, 1, ik), apwalm)
! calculate the wavefunctions for all states of the input k-point
  call genwfsv(.false., ngk(1, ik), igkig(:, 1, ik), evalsv(:, ik), apwalm, evecfv, &
   evecsv, wfmt, wfir)
! compute effective potential matrix elements
  call genvmatk(rfmt, veffir, wfmt, wfir, kinmatc(:, :, ik))
  kinmatc(:, :, ik)=-kinmatc(:, :, ik)
! add second-variational eigenvalues along the diagonal
  do ist=1, nstsv
    kinmatc(ist, ist, ik)=kinmatc(ist, ist, ik)+evalsv(ist, ik)
  end do
! compute the exchange-correlation magnetic field matrix elements
  if (associated(input%groundstate%spin)) then
    call genbmatk(rvfmt, bxcir, wfmt, wfir, bmat)
    kinmatc(:, :, ik)=kinmatc(:, :, ik)-bmat(:, :)
  end if
! rotate kinetic matrix elements to Cartesian basis
  call zgemm('N', 'C', nstsv, nstsv, nstsv, zone, kinmatc(:, :, ik), nstsv, evecsv, &
   nstsv, zzero, c, nstsv)
  call zgemm('N', 'N', nstsv, nstsv, nstsv, zone, evecsv, nstsv, c, nstsv, zzero, &
   kinmatc(:, :, ik), nstsv)
end do
if (associated(input%groundstate%spin)) deallocate(rvfmt)
deallocate(rfmt, evalfv, apwalm, evecfv, evecsv)
deallocate(wfmt, wfir, vmat, bmat, c)
return
end subroutine
