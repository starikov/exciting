


! Copyright (C) 2002-2005 J. K. Dewhurst, S. Sharma and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.


subroutine oepmain
use modmain
use modinput
implicit none
! local variables
integer::is, ia, ias, ik
integer::ir, irc, it, idm
real(8)::tau, resp, t1
! allocatable arrays
real(8), allocatable :: rflm(:)
real(8), allocatable :: rfmt(:, :, :)
real(8), allocatable :: rfir(:)
real(8), allocatable :: rvfmt(:, :, :, :)
real(8), allocatable :: rvfir(:, :)
real(8), allocatable :: dvxmt(:, :, :)
real(8), allocatable :: dvxir(:)
real(8), allocatable :: dbxmt(:, :, :, :)
real(8), allocatable :: dbxir(:, :)
complex(8), allocatable :: vnlcv(:, :, :, :)
complex(8), allocatable :: vnlvv(:, :, :)
complex(8), allocatable :: zflm(:)
! external functions
real(8)::rfinp
complex(8) zfint
external rfinp, zfint
if (iscl.lt.1) return
! calculate nonlocal matrix elements
allocate(vnlcv(ncrmax, natmtot, nstsv, nkpt))
allocate(vnlvv(nstsv, nstsv, nkpt))
call oepvnl(vnlcv, vnlvv)
! allocate local arrays
allocate(rflm(lmmaxvr))
allocate(rfmt(lmmaxvr, nrmtmax, natmtot))
allocate(rfir(ngrtot))
allocate(dvxmt(lmmaxvr, nrcmtmax, natmtot))
allocate(dvxir(ngrtot))
allocate(zflm(lmmaxvr))
if (associated(input%groundstate%spin)) then
  allocate(rvfmt(lmmaxvr, nrmtmax, natmtot, ndmag))
  allocate(rvfir(ngrtot, ndmag))
  allocate(dbxmt(lmmaxvr, nrcmtmax, natmtot, ndmag))
  allocate(dbxir(ngrtot, ndmag))
end if
! zero the complex potential
zvxmt(:, :, :)=0.d0
zvxir(:)=0.d0
if (associated(input%groundstate%spin)) then
  zbxmt(:, :, :, :)=0.d0
  zbxir(:, :)=0.d0
end if
resp=0.d0
! initial step size
tau=input%groundstate%OEP%tauoep(1)
! start iteration loop
do it=1, input%groundstate%OEP%maxitoep
  if (mod(it, 10).eq.0) then
    write(*, '("Info(oepmain): done ", I4, " iterations of ", I4)') it, input%groundstate%OEP%maxitoep
  end if
! zero the residual
  dvxmt(:, :, :)=0.d0
  dvxir(:)=0.d0
  if (associated(input%groundstate%spin)) then
    dbxmt(:, :, :, :)=0.d0
    dbxir(:, :)=0.d0
  end if
! calculate the k-dependent residuals
!$OMP PARALLEL DEFAULT(SHARED)
!$OMP DO
  do ik=1, nkpt
    call oepresk(ik, vnlcv, vnlvv, dvxmt, dvxir, dbxmt, dbxir)
  end do
!$OMP END DO
!$OMP END PARALLEL
! convert muffin-tin residuals to spherical harmonics
  do is=1, nspecies
    do ia=1, natoms(is)
      ias=idxas(ia, is)
      irc=0
      do ir=1, nrmt(is), input%groundstate%lradstep
	irc=irc+1
	call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rfshtvr, lmmaxvr, dvxmt(:, irc, ias), &
	 1, 0.d0, rfmt(:, ir, ias), 1)
	do idm=1, ndmag
	  call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rfshtvr, lmmaxvr, &
	   dbxmt(:, irc, ias, idm), 1, 0.d0, rvfmt(:, ir, ias, idm), 1)
	end do
      end do
    end do
  end do
! symmetrise the residuals
  call symrf(input%groundstate%lradstep, rfmt, dvxir)
  if (associated(input%groundstate%spin)) call symrvf(input%groundstate%lradstep, rvfmt, dbxir)
! magnitude of residuals
  resoep=sqrt(abs(rfinp(input%groundstate%lradstep, rfmt, rfmt, dvxir, dvxir)))
  do idm=1, ndmag
    t1 = rfinp(input%groundstate%lradstep, rvfmt(:, :, :, idm), rvfmt(:, :, :, idm), dbxir(:, idm), &
     dbxir(:, idm))
    resoep=resoep+sqrt(abs(t1))
  end do
  resoep=resoep/omega
! adjust step size
  if (it.gt.1) then
    if (resoep.gt.resp) then
      tau=tau*input%groundstate%OEP%tauoep(2)
    else
      tau=tau*input%groundstate%OEP%tauoep(3)
    end if
  end if
  resp=resoep
!--------------------------------------------!
!     update complex potential and field     !
!--------------------------------------------!
  do is=1, nspecies
    do ia=1, natoms(is)
      ias=idxas(ia, is)
      irc=0
      do ir=1, nrmt(is), input%groundstate%lradstep
	irc=irc+1
! convert residual to spherical coordinates and subtract from complex potential
	call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rbshtvr, lmmaxvr, rfmt(:, ir, ias), 1, &
	 0.d0, rflm, 1)
	zvxmt(:, irc, ias)=zvxmt(:, irc, ias)-tau*rflm(:)
	do idm=1, ndmag
	  call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rbshtvr, lmmaxvr, &
	   rvfmt(:, ir, ias, idm), 1, 0.d0, rflm, 1)
	  zbxmt(:, irc, ias, idm)=zbxmt(:, irc, ias, idm)-tau*rflm(:)
	end do
      end do
    end do
  end do
  zvxir(:)=zvxir(:)-tau*dvxir(:)
  do idm=1, ndmag
    zbxir(:, idm)=zbxir(:, idm)-tau*dbxir(:, idm)
  end do
! end iteration loop
end do
! generate the real potential and field
do is=1, nspecies
  do ia=1, natoms(is)
    ias=idxas(ia, is)
    irc=0
    do ir=1, nrmt(is), input%groundstate%lradstep
      irc=irc+1
! convert to real spherical harmonics
      rflm(:)=dble(zvxmt(:, irc, ias))
      call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rfshtvr, lmmaxvr, rflm, 1, 0.d0, &
       rfmt(:, ir, ias), 1)
      do idm=1, ndmag
	rflm(:)=dble(zbxmt(:, irc, ias, idm))
	call dgemv('N', lmmaxvr, lmmaxvr, 1.d0, rfshtvr, lmmaxvr, rflm, 1, 0.d0, &
	 rvfmt(:, ir, ias, idm), 1)
      end do
    end do
  end do
end do
! convert potential and field from a coarse to a fine radial mesh
call rfmtctof(rfmt)
do idm=1, ndmag
  call rfmtctof(rvfmt(:, :, :, idm))
end do
! add to existing correlation potential and field
do is=1, nspecies
  do ia=1, natoms(is)
    ias=idxas(ia, is)
    do ir=1, nrmt(is)
      vxcmt(:, ir, ias)=vxcmt(:, ir, ias)+rfmt(:, ir, ias)
      do idm=1, ndmag
	bxcmt(:, ir, ias, idm)=bxcmt(:, ir, ias, idm)+rvfmt(:, ir, ias, idm)
      end do
    end do
  end do
end do
vxcir(:)=vxcir(:)+dble(zvxir(:))
do idm=1, ndmag
  bxcir(:, idm)=bxcir(:, idm)+dble(zbxir(:, idm))
end do
! symmetrise the exchange potential and field
call symrf(1, vxcmt, vxcir)
if (associated(input%groundstate%spin)) then
  call symrvf(1, bxcmt, bxcir)
end if
deallocate(rflm, rfmt, rfir, vnlcv, vnlvv)
deallocate(dvxmt, dvxir, zflm)
if (associated(input%groundstate%spin)) then
  deallocate(rvfmt, rvfir)
  deallocate(dbxmt, dbxir)
end if
return
end subroutine
