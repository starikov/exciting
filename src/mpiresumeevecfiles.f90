
! Copyright (C) 2006 J. K. Dewhurst, S. Sharma and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.
!
!BOP
! !ROUTINE: mpiresumeevec
! !INTERFACE:
subroutine    mpiresumeevecfiles
  use modmain
#ifdef MPI  
  use modmpi
  ! !DESCRIPTION:
  !  Routine reads the lokal EIGVECk1-k2.OUT files that were created to 
  !  avoid file system inconsistencies. And writes them into the standard
  !  EIGVEC.OUT File
  !
  ! !REVISION HISTORY:
  !   Created October SEPT 2006 (MULEOBEN)
  !   by Cristian Meisenbichler
  !EOP
  implicit none
  ! arguments
  integer:: ik,proc,nmatmax_,nstfv_,nspnfv_,nstsv_,recl
  character(256) filetag
  complex(8) :: evecfv(nmatmax,nstfv,nspnfv) 
  complex(8) :: evecsv (nstsv,nstsv)
  real(8):: evalfv(nstfv,nspnfv),vkl_(3),evalsvp(nstsv),occsvp(nstsv)
  character(256), external:: outfilenamestring
  if(procs.gt.1) call MPI_barrier(MPI_COMM_WORLD,ierr)
  if(procs.gt.1.and.splittfile)CALL SYSTEM("sync")
  if ((rank.eq.0).and.(procs.gt.1).and.splittfile)  then
     filetag='EVECFV' 
     inquire(iolength=recl) vkl_,nmatmax_,nstfv_,nspnfv_,evecfv
     open(71,file=trim(scrpath)//trim(filetag)//trim(filext)  ,action='WRITE', &
          form='UNFORMATTED',access='DIRECT',recl=recl)
     do proc=0,procs-1
        open(77,file=outfilenamestring(filetag,firstk(proc)),action='READ', &
             form='UNFORMATTED',access='DIRECT',recl=recl)
        do ik =firstk(proc),lastk(proc)
           read(77,rec=ik-firstk(procofk(ik))+1) vkl_,nmatmax_,nstfv_,nspnfv_,evecfv
           write(71,rec=ik) vkl_,nmatmax_,nstfv_,nspnfv_,evecfv
        end do
        close(77,status='DELETE')
     end do
     close(71) 

     filetag='EVECSV'
     inquire(iolength=recl) vkl_,nstsv_,evecsv
     open(71,file=trim(scrpath)//trim(filetag)//trim(filext)  ,action='WRITE', &
          form='UNFORMATTED',access='DIRECT',recl=recl)
     do proc=0,procs-1
        open(77,file=outfilenamestring(filetag,firstk(proc)),action='READ', &
             form='UNFORMATTED',access='DIRECT',recl=recl)
	do ik =firstk(proc),lastk(proc)
           read(77,rec=ik-firstk(procofk(ik))+1)  vkl_,nstsv_,evecsv
           write(71,rec=ik)  vkl_,nstsv_,evecsv
        end do
        close(77,status='DELETE')
     end do
     close(71) 



     filetag='EVALFV'
     inquire(iolength=recl)  vkl_,nstfv_,nspnfv_,evalfv
     open(71,file=trim(scrpath)//trim(filetag)//trim(filext)  ,action='WRITE', &
          form='UNFORMATTED',access='DIRECT',recl=recl)
     do proc=0,procs-1
        open(77,file=outfilenamestring(filetag,firstk(proc)),action='READ', &
             form='UNFORMATTED',access='DIRECT',recl=recl)
	do ik =firstk(proc),lastk(proc)
           read(77,rec=ik-firstk(procofk(ik))+1)   vkl_,nstfv_,nspnfv_,evalfv
           write(71,rec=ik)   vkl_,nstfv_,nspnfv_,evalfv
        end do
        close(77,status='DELETE')
     end do
     close(71)


     filetag='EVALSV'
     inquire(iolength=recl)  vkl_,nstsv_,evalsvp
     open(71,file=trim(scrpath)//trim(filetag)//trim(filext)  ,action='WRITE', &
          form='UNFORMATTED',access='DIRECT',recl=recl)
     do proc=0,procs-1
        open(77,file=outfilenamestring(filetag,firstk(proc)),action='READ', &
             form='UNFORMATTED',access='DIRECT',recl=recl)
	do ik =firstk(proc),lastk(proc)
           read(77,rec=ik-firstk(procofk(ik))+1)   vkl_,nstsv_,evalsvp
           write(71,rec=ik)   vkl_,nstsv_,evalsvp
        end do
        close(77,status='DELETE')
     end do
     close(71)


     filetag='OCCSV'
     inquire(iolength=recl)  vkl_,nstsv_,occsvp
     open(71,file=trim(scrpath)//trim(filetag)//trim(filext)  ,action='WRITE', &
          form='UNFORMATTED',access='DIRECT',recl=recl)
     do proc=0,procs-1
        open(77,file=outfilenamestring(filetag,firstk(proc)),action='READ', &
             form='UNFORMATTED',access='DIRECT',recl=recl)
	do ik =firstk(proc),lastk(proc)
           read(77,rec=ik-firstk(procofk(ik))+1)   vkl_,nstsv_,occsvp
           write(71,rec=ik)  vkl_,nstsv_,occsvp
        end do
        close(77,status='DELETE')
     end do
     close(71)
     CALL SYSTEM("sync")
     write(60,*)"resumed splitt files"
     call flushifc(60)
  endif

  if(procs.gt.1) call MPI_barrier(MPI_COMM_WORLD,ierr)
  if(procs.gt.1) CALL SYSTEM("sync")
 
  if(procs.gt.1)call MPI_barrier(MPI_COMM_WORLD,ierr)
#endif
 splittfile=0
  return
end subroutine mpiresumeevecfiles

