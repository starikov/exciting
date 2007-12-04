
! Copyright (C) 2002-2005 J. K. Dewhurst, S. Sharma and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

subroutine oepmain
  use modmain
  use modmpi
  implicit none
  ! local variables
  integer is,ia,ias,ik
  integer ir,irc,it,idm
  real(8) tau,resp
  ! allocatable arrays
  real(8), allocatable :: rfmt(:,:,:)
  real(8), allocatable :: rfir(:)
  real(8), allocatable :: rvfmt(:,:,:,:)
  real(8), allocatable :: rvfir(:,:)
  complex(8), allocatable :: vnlcv(:,:,:,:)
  complex(8), allocatable :: vnlvv(:,:,:)
  complex(8), allocatable :: dvxmt(:,:,:)
  complex(8), allocatable :: dvxir(:)
  complex(8), allocatable :: dbxmt(:,:,:,:)
  complex(8), allocatable :: dbxir(:,:)
  complex(8), allocatable :: zflm(:)
#ifdef MPI
  complex(8), allocatable :: buffer(:)
  complex(8), allocatable :: buffer2d(:,:)
  complex(8), allocatable :: buffer3d(:,:,:)
  complex(8), allocatable :: buffer4d(:,:,:,:)
#endif
  ! external functions
  real(8) rfinp
  complex(8) zfint
  external rfinp,zfint
  if (iscl.lt.1) return
  ! calculate nonlocal matrix elements
  allocate(vnlcv(ncrmax,natmtot,nstsv,nkpt))
  allocate(vnlvv(nstsv,nstsv,nkpt))
  call oepvnl(vnlcv,vnlvv)
  ! allocate local arrays
  allocate(rfmt(lmmaxvr,nrmtmax,natmtot))
  allocate(rfir(ngrtot))
  allocate(dvxmt(lmmaxvr,nrcmtmax,natmtot))
  allocate(dvxir(ngrtot))
  allocate(zflm(lmmaxvr))
  if (spinpol) then
     allocate(rvfmt(lmmaxvr,nrmtmax,natmtot,ndmag))
     allocate(rvfir(ngrtot,ndmag))
     allocate(dbxmt(lmmaxvr,nrcmtmax,natmtot,ndmag))
     allocate(dbxir(ngrtot,ndmag))
  end if
  ! zero the potential
  zvxmt(:,:,:)=0.d0
  zvxir(:)=0.d0
  if (spinpol) then
     zbxmt(:,:,:,:)=0.d0
     zbxir(:,:)=0.d0
  end if
  resp=0.d0
  ! initial step size
  tau=tauoep(1)
  ! start iteration loop
  do it=1,maxitoep
     if (mod(it,10).eq.0) then
        write(*,'("Info(oepmain): done ",I6," iterations of ",I6)') it,maxitoep
     end if
     ! zero the residues
     dvxmt(:,:,:)=0.d0
     dvxir(:)=0.d0
     if (spinpol) then
        dbxmt(:,:,:,:)=0.d0
        dbxir(:,:)=0.d0
     end if
     ! calculate the k-dependent residues

#ifdef MPIEXXSUM
     do ik=firstk(rank),lastk(rank)
#endif
#ifndef MPIEXXSUM 
        !$OMP PARALLEL DEFAULT(SHARED)
        !$OMP DO   
        do ik=1,nkpt   
#endif
           call oepresk(ik,vnlcv,vnlvv,dvxmt,dvxir,dbxmt,dbxir)
        end do
#ifndef MPIEXXSUM      
        !$OMP END DO
        !$OMP END PARALLEL
#endif    
#ifdef MPIEXXSUM
        allocate(buffer3d(lmmaxvr,nrcmtmax,natmtot)) 
        buffer3d=0
        call MPI_allreduce(dvxmt,buffer3d,lmmaxvr*nrcmtmax*natmtot,&
             MPI_DOUBLE_COMPLEX,MPI_SUM,MPI_COMM_WORLD,ierr)
        dvxmt=buffer3d
        deallocate(buffer3d)
        allocate(buffer(ngrtot)) 
        buffer=0
        call MPI_allreduce(dvxir,buffer,ngrtot,MPI_DOUBLE_COMPLEX,&
             MPI_SUM,MPI_COMM_WORLD,ierr)
        dvxir=buffer
        deallocate(buffer)
        if (spinpol) then
           allocate(buffer4d(lmmaxvr,nrcmtmax,natmtot,ndmag))
           buffer4d=0
           call MPI_allreduce(dbxmt,buffer4d,lmmaxvr*nrcmtmax*natmtot*ndmag,&
                MPI_DOUBLE_COMPLEX,MPI_SUM,MPI_COMM_WORLD,ierr)
           dbxmt=buffer4d
           deallocate(buffer4d)

           allocate(buffer2d(ngrtot,ndmag))
           buffer2d=0
           call MPI_allreduce(dbxir,buffer2d,ngrtot*ndmag,MPI_DOUBLE_COMPLEX,&
                MPI_SUM,MPI_COMM_WORLD,ierr)
           dbxir=buffer2d
           deallocate(buffer2d)
        endif
#endif
        ! compute the real residues
        do is=1,nspecies
           do ia=1,natoms(is)
              ias=idxas(ia,is)
              irc=0
              do ir=1,nrmt(is),lradstp
                 irc=irc+1
                 call zflmconj(lmaxvr,dvxmt(1,irc,ias),zflm)
                 zflm(:)=zflm(:)+dvxmt(:,irc,ias)
                 call ztorflm(lmaxvr,zflm,rfmt(1,ir,ias))
                 do idm=1,ndmag
                    call zflmconj(lmaxvr,dbxmt(1,irc,ias,idm),zflm)
                    zflm(:)=zflm(:)+dbxmt(:,irc,ias,idm)
                    call ztorflm(lmaxvr,zflm,rvfmt(1,ir,ias,idm))
                 end do
              end do
           end do
        end do
        rfir(:)=2.d0*dble(dvxir(:))
        do idm=1,ndmag
           rvfir(:,idm)=2.d0*dble(dbxir(:,idm))
        end do
        ! symmetrise the residues
        call symrf(lradstp,rfmt,rfir)
        if (spinpol) call symrvf(lradstp,rvfmt,rvfir)
        ! magnitude of residues
        resoep=sqrt(abs(rfinp(lradstp,rfmt,rfmt,rfir,rfir)))
        do idm=1,ndmag
           resoep=resoep+sqrt(abs(rfinp(lradstp,rvfmt(1,1,1,idm),rvfmt(1,1,1,idm), &
                rvfir(1,idm),rvfir(1,idm))))
        end do
        resoep=resoep/omega
        ! adjust step size
        if (it.gt.1) then
           if (resoep.gt.resp) then
              tau=tau*tauoep(2)
           else
              tau=tau*tauoep(3)
           end if
        end if
        resp=resoep
        !--------------------------------------------!
        !     update complex potential and field     !
        !--------------------------------------------!
        do is=1,nspecies
           do ia=1,natoms(is)
              ias=idxas(ia,is)
              irc=0
              do ir=1,nrmt(is),lradstp
                 irc=irc+1
                 call rtozflm(lmaxvr,rfmt(1,ir,ias),zflm)
                 zvxmt(:,irc,ias)=zvxmt(:,irc,ias)-tau*zflm(:)
                 do idm=1,ndmag
                    call rtozflm(lmaxvr,rvfmt(1,ir,ias,idm),zflm)
                    zbxmt(:,irc,ias,idm)=zbxmt(:,irc,ias,idm)-tau*zflm(:)
                 end do
              end do
           end do
        end do
        zvxir(:)=zvxir(:)-tau*rfir(:)
        do idm=1,ndmag
           zbxir(:,idm)=zbxir(:,idm)-tau*rvfir(:,idm)
        end do
        ! end iteration loop
     end do
     ! generate the real potential and field
     do is=1,nspecies
        do ia=1,natoms(is)
           ias=idxas(ia,is)
           irc=0
           do ir=1,nrmt(is),lradstp
              irc=irc+1
              call ztorflm(lmaxvr,zvxmt(1,irc,ias),rfmt(1,ir,ias))
              do idm=1,ndmag
                 call ztorflm(lmaxvr,zbxmt(1,irc,ias,idm),rvfmt(1,ir,ias,idm))
              end do
           end do
        end do
     end do
     ! convert potential and field from a coarse to a fine radial mesh
     call rfmtctof(rfmt)
     do idm=1,ndmag
        call rfmtctof(rvfmt(1,1,1,idm))
     end do
     ! add to existing correlation potential and field
     do is=1,nspecies
        do ia=1,natoms(is)
           ias=idxas(ia,is)
           do ir=1,nrmt(is)
              vxcmt(:,ir,ias)=vxcmt(:,ir,ias)+rfmt(:,ir,ias)
              do idm=1,ndmag
                 bxcmt(:,ir,ias,idm)=bxcmt(:,ir,ias,idm)+rvfmt(:,ir,ias,idm)
              end do
           end do
        end do
     end do
     vxcir(:)=vxcir(:)+dble(zvxir(:))
     do idm=1,ndmag
        bxcir(:,idm)=bxcir(:,idm)+dble(zbxir(:,idm))
     end do
     deallocate(rfmt,rfir,vnlcv,vnlvv)
     deallocate(dvxmt,dvxir,zflm)
     if (spinpol) then
        deallocate(rvfmt,rvfir)
        deallocate(dbxmt,dbxir)
     end if
     return
   end subroutine oepmain

