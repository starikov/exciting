
! Copyright (C) 2004-2007 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

module m_dfq
  implicit none
contains

  subroutine dfq(iq)
    use modmain
    use modtddft
    use modtetra
    use modmpi
    use m_genwgrid
    use m_gensymdf
    use m_getpemat
    use m_getdevalsv
    use m_dfqoschd
    use m_dfqoscwg
    use m_dfqoscbo
    use m_dftim
    use m_tetcalccwq
    use m_gettetcw
    use m_chi0upd
    use m_putx0
    use m_getunit
    use m_filedel
    use m_genfilname
    implicit none
    ! arguments
    integer, intent(in) :: iq
    ! local variables
    character(*), parameter :: thisnam = 'dfq'
    real(8), parameter :: epstetra=1.d-8
    character(256) :: filextt,string
    complex(8), allocatable :: w(:)
    complex(8), allocatable :: chi0(:,:,:),hou(:,:),huo(:,:)
    complex(8), allocatable :: chi0w(:,:,:,:),chi0h(:,:)
    complex(8), allocatable :: xou(:),xouc(:),xuo(:),xuoc(:),wou(:),wuo(:)
    complex(8) :: wout
    real(8), allocatable :: derndou(:,:,:),dernduo(:,:,:)
    real(8), allocatable :: wreal(:),cw(:),cwa(:),cwsurf(:)
    real(8) :: brd,vkloff_save(3)
    real(8) :: cpu0,cpu1,cpuread,cpuosc,cpuupd,cputot
    integer :: oc1, oc2, n,igq,i,j,ik,iw,wi,wf,iv,ic,ml(3),nwdfp,ikt
    integer :: oct,un
    logical :: tq0, tetrat

    tetrat=tetra
    bzsampl=0
    if (tetra) bzsampl=1

    ! filenames for input
    call genfilname(basename='TETW',iq=iq,filnam=fnwtet)
    call genfilname(basename='EMAT',iq=iq,filnam=fnemat)
    call genfilname(basename='DEVALSV',iq=iq,filnam=fndevalsv)
    ! filenames for output
    call genfilname(basename='X0',bzsampl=bzsampl,acont=acont,nar=.not.aresdf,&
         iq=iq,filnam=fnchi0)
    call genfilname(basename='X0',bzsampl=bzsampl,acont=acont,nar=.not.aresdf,&
         iq=iq,procs=procs,rank=rank,filnam=fnchi0_t)
    call genfilname(nodotpar=.true.,basename='X0_TIMING',iq=iq,&
         procs=procs,rank=rank,filnam=fnxtim)

    ! initial and final w-point
    wi=wpari
    wf=wparf
    nwdfp=wf-wi+1

    ! file extension for q-point
    call genfilname(iq=iq,setfilext=.true.)
    ! save k-point offset
    vkloff_save = vkloff
    ! shift k-mesh by q-point    
    vkloff(:)=qvkloff(:,iq)

    ! calculate k+q and G+k+q related variables
    call init1td

    ! check if q=0
    tq0 = tq1gamma.and.(iq.eq.1)
    if (tq0) then
       write(unitout,'(a)') 'Info('//trim(thisnam)//'): Gamma q-point: using &
            &momentum matrix elements for dielectric function'
    end if

    ! write out matrix size of response function
    write(unitout,'(a,i6)') 'Info('//thisnam//'): number of G+q vectors &
         &(local field effects):',ngq(iq)

    ! remove timing files from previous runs
    call filedel(trim(fnxtim))

    ! allocations
    allocate(w(nwdf))
    allocate(wreal(nwdfp))
    ! generate complex energy grid
    call genwgrid(nwdf,wdos,acont,0.d0,w_cmplx=w)
    wreal(:)=w(wi:wf)
    if (wreal(1).lt.epstetra) wreal(1)=epstetra

    ! matrix size for response function
    n=ngq(iq)

    ! allocate arrays for head and wings
    allocate(chi0h(3,nwdfp))
    allocate(chi0w(n,2,3,nwdfp))

    ! allocations
    allocate(wou(nwdf))
    allocate(wuo(nwdf))
    allocate(chi0(n,n,nwdfp))
    ! allocate arrays for eigenvalue differences
    if(allocated(deou)) deallocate(deou)
    if(allocated(deuo)) deallocate(deuo)
    allocate(deou(nstval,nstcon))
    allocate(deuo(nstcon,nstval))
    ! allocate matrix elements arrays
    if (allocated(xiou)) deallocate(xiou)
    if (allocated(xiuo)) deallocate(xiuo)
    if (allocated(pmou)) deallocate(pmou)
    if (allocated(pmuo)) deallocate(pmuo)
    allocate(xiou(nstval,nstcon,n))
    allocate(xiuo(nstcon,nstval,n))
    allocate(pmou(3,nstval,nstcon))
    allocate(pmuo(3,nstcon,nstval))
    ! allocate temporary arrays
    allocate(xou(n))
    allocate(xouc(n))
    allocate(xuo(n))
    allocate(xuoc(n))
    allocate(hou(n,n))
    allocate(huo(n,n))

    if (tetrat) then
       allocate(cw(nwdf),cwa(nwdf),cwsurf(nwdf))
    end if

    ! zero broadening for analytic contiunation
    brd = brdtd
    if (acont) brd = zzero

    ! initializations
    chi0(:,:,:)=zzero
    chi0w(:,:,:,:)=zzero
    chi0h(:,:)=zzero

    ! loop over k-points
    call getunit(un)
    ikt=0
    do ik=1,nkpt

       ! if checkpoint true -> read X0
       ! set chkpt=false

       cpuosc=0.d0
       cpuupd=0.d0
       call cpu_time(cpu0)

       ! read Kohn-Sham energy differences
       call getdevalsv(iq,ik,.true.,trim(fndevalsv),deou,deuo)
       ! read Kohn-Sham energy differences (random k-point set)
       ! get matrix elements (exp. expr. or momentum)
       call getpemat(iq,ik,trim(fnpmat),trim(fnemat),nstval,nstcon,xiou,xiuo,&
            pmou,pmuo)

       ! turn off antiresonant terms for Kohn-Sham response function
       if (.not.aresdf) then
          xiuo(:,:,:)=zzero
          pmuo(:,:,:)=zzero
       end if

       call cpu_time(cpu1)
       cpuread=cpu1-cpu0

       do iv=1,nstval
          do ic=1,nstcon
             call cpu_time(cpu0)

             ! user request termination
             call terminate_inqr('dfq')

             ! read weights for tetrahedron method
             if (tetrat)  then
                call gettetcw(iq,ik,iv,ic,nwdf,trim(fnwtet),cw,cwa, &
                     cwsurf)
                wou(wi:wf)=cmplx(cw(wi:wf),cwsurf(wi:wf),8)*2.d0/omega
                wuo(wi:wf)=cmplx(cwa(wi:wf),0.d0,8)*2.d0/omega
             else
                ! denominator
                wou(:)=2*wkpt(ik)/omega/(w(:)+deou(iv,ic)-scissor+zi*brd)
                wuo(:)=-2*wkpt(ik)/omega/(w(:)+deuo(ic,iv)+scissor+zi*brd)
             end if

             hou(:,:)=zzero
             huo(:,:)=zzero
             ! calculate oscillators
             if (.not.tq0) then
                ! whole
                call dfqoscbo(n,xiou(iv,ic,:),xiuo(ic,iv,:),hou,huo)
             end if

             if (tq0.and.(n.gt.1)) then
                ! body
                call dfqoscbo(n-1,xiou(iv,ic,2:),xiuo(ic,iv,2:), &
                     hou(2:,2:),huo(2:,2:))
             end if

             ! loop over longitudinal Cartesian (diagonal) components of
             ! response function
             do oct=1,3
                ! symmetrization matrix for dielectric function
                call gensymdf(oct,oct)
                optcomp(1,1)=oct
                optcomp(2,1)=oct

                if (tq0) then
                   ! head
                   call dfqoschd(pmou(:,iv,ic),pmuo(:,ic,iv),hou(1,1),huo(1,1))
                   do iw=wi,wf
                      wout=wou(iw)
                      ! be careful with gauge in the w-variable
                      ! one has to subtract the scissor's shift
                      if (tetrat) wout=cmplx(dble(wou(iw)),aimag(wou(iw))*&
                           deou(iv,ic)**2/(wreal(iw-wi+1)-scissor)**2)
                      chi0h(oct,iw-wi+1)=chi0h(oct,iw-wi+1)+ &
                           wout*hou(1,1)+wuo(iw)*huo(1,1)
                   end do
                end if

                if (tq0.and.(n.gt.1)) then
                   ! wings
                   call dfqoscwg(1,pmou(:,iv,ic),pmuo(:,ic,iv),xiou(iv,ic,2:),&
                        xiuo(ic,iv,2:),hou(1,2:),huo(1,2:))
                   call dfqoscwg(2,pmou(:,iv,ic),pmuo(:,ic,iv),xiou(iv,ic,2:),&
                        xiuo(ic,iv,2:),hou(2:,1),huo(2:,1))
                   do iw=wi,wf
                      wout=wou(iw)
                      ! be careful with gauge in the w-variable
                      ! one has to subtract the scissor's shift
                      if (tetrat) wout=cmplx(dble(wou(iw)),aimag(wou(iw))*&
                           deou(iv,ic)/(-wreal(iw-wi+1)+scissor))
                      chi0w(2:,1,oct,iw-wi+1)=chi0w(2:,1,oct,iw-wi+1)+&
                           wout*hou(1,2:)+wuo(iw)*huo(1,2:)
                      chi0w(2:,2,oct,iw-wi+1)=chi0w(2:,2,oct,iw-wi+1)+&
                           wout*hou(2:,1)+wuo(iw)*huo(2:,1)
                   end do
                end if

                call cpu_time(cpu1)
                cpuosc=cpuosc+cpu1-cpu0

             end do !oct

             ! updating of response function
             do iw=wi,wf
                ! * most time-consuming part of routine *
                call chi0upd(n,wou(iw),wuo(iw),hou,huo,&
                     chi0(:,:,iw-wi+1))
             end do

             call cpu_time(cpu0)
             cpuupd=cpuupd+cpu0-cpu1

          end do ! ic
       end do ! iv
       cputot=cpuread+cpuosc+cpuupd

       ! timing information
       call dftim(iq,ik,trim(fnxtim),cpuread,cpuosc,cpuupd, &
            cputot)
#ifdef MPI
       ! synchronize
       call barrier(rank=rank,procs=procs,un=un,async=0,string='.barrier')
#endif
    end do ! ik

    do j=0,procs-1
       if (rank==j) then
          do iw=wi,wf
             call putx0(tq0,iq,iw-wi+1,trim(fnchi0_t),'',&
                  chi0(:,:,iw-wi+1),chi0w(:,:,:,iw-wi+1),chi0h(:,iw-wi+1))
          end do
       end if
       call barrier(rank=rank,procs=procs,un=un,async=0,string='.barrier')
    end do

    deallocate(chi0h)
    deallocate(chi0w)
    deallocate(deou,deuo,wou,wuo)
    deallocate(xiou,xiuo,pmou,pmuo)
    deallocate(w,wreal,chi0)
    deallocate(xou,xouc,xuo,xuoc,hou,huo)
    if (tetrat) deallocate(cw,cwa,cwsurf)

    ! restore offset
    vkloff(:) = vkloff_save(:)
    ! restore file extension
    call genfilname(setfilext=.true.)

  end subroutine dfq

end module m_dfq