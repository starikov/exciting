


! Copyright (C) 2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.


subroutine exccoulint
  use modmain
use modinput
  use modmpi
  use modxs
  use ioarray
  use m_xsgauntgen
  use m_findgntn0
  use m_writegqpts
  use m_genfilname
  use m_getunit
  implicit none
  ! local variables
  character(*), parameter :: thisnam='exccoulint'
  character(256) :: fnexcli
  integer, parameter :: iqmt=1
  real(8), parameter :: epsortho=1.d-12
  integer :: iknr,jknr,iqr,iq,igq1,n,un
  integer :: iv(3),j1,j2
  integer :: ist1,ist2,ist3,ist4,nst12,nst34,nst13,nst24,ikkp,nkkp
  real(8), allocatable :: potcl(:)
  complex(8), allocatable :: exclit(:,:),excli(:,:,:,:)
  complex(8), allocatable :: emat12(:,:),emat34(:,:)
  complex(8), allocatable :: emat12k(:,:,:,:)
  !---------------!
  !   main part   !
  !---------------!
  input%xs%emattype=1
  call init0
  call init1
  call init2
  ! read Fermi energy from file
  call readfermi
  ! save variables for the Gamma q-point
  call xssave0
  ! generate Gaunt coefficients
  call xsgauntgen(max(input%groundstate%lmaxapw, lolmax), input%xs%lmaxemat, max(input%groundstate%lmaxapw, lolmax))
  ! find indices for non-zero Gaunt coefficients
  call findgntn0(max(input%xs%lmaxapwwf, lolmax), max(input%xs%lmaxapwwf, lolmax), input%xs%lmaxemat, xsgnt)
  write(unitout,'(a,3i8)') 'Info('//thisnam//'): Gaunt coefficients generated &
       &within lmax values:', input%groundstate%lmaxapw, input%xs%lmaxemat, input%groundstate%lmaxapw
  write(unitout, '(a, i6)') 'Info('//thisnam//'): number of q-points: ', nqpt
  call flushifc(unitout)
  call genfilname(dotext='_SCR.OUT',setfilext=.true.)
  call findocclims(0,istocc0,istocc,istunocc0,istunocc,isto0,isto,istu0,istu)
  ! only for systems with a gap in energy
  if (.not.ksgap) then
     write(*,*)
     write(*,'("Error(",a,"): exchange Coulomb interaction works only for &
          &systems with KS-gap.")') trim(thisnam)
     write(*,*)
     call terminate
  end if
  ! check number of empty states
  if (input%xs%screening%nempty.lt.input%groundstate%nempty) then
     write(*,*)
     write(*,'("Error(",a,"): too few empty states in screening eigenvector &
          &file - the screening should include many empty states &
	  &(BSE/screening)", 2i8)') trim(thisnam), input%groundstate%nempty, input%xs%screening%nempty
     write(*,*)
     call terminate
  end if
  call ematbdcmbs(input%xs%emattype)
  nst12=nst1*nst2
  nst34=nst3*nst4
  nst13=nst1*nst3
  nst24=nst2*nst4
  call genfilname(dotext='_SCI.OUT',setfilext=.true.)
  if (rank.eq.0) then
     call writekpts
     call writeqpts
  end if
  n=ngq(iqmt)
  call ematrad(iqmt)
  call genfilname(dotext='_SCR.OUT',setfilext=.true.)
  allocate(potcl(n))
  allocate(excli(nst1,nst2,nst1,nst2))
  allocate(exclit(nst12,nst34))
  allocate(emat12k(nst1,nst2,n,nkptnr))
  allocate(emat12(nst12,n),emat34(nst34,n))
  potcl(:)=0.d0
  excli(:,:,:,:)=zzero
  !---------------------------!
  !     loop over k-points    !
  !---------------------------!
  call genparidxran('k',nkptnr)
  call init1offs(qvkloff(1,iqmt))
  call ematqalloc
  do iknr=kpari,kparf
     call chkpt(3,(/task,1,iknr/),'task,sub,k-point; matrix elements of plane &
          &wave')
     ! matrix elements for k and q=0
     call ematqk1(iqmt,iknr)
     emat12k(:,:,:,iknr)=xiou(:,:,:)
     deallocate(xiou,xiuo)
  end do
  ! communicate array-parts wrt. k-points
  call zalltoallv(emat12k,nst1*nst2*n,nkptnr)
  input%xs%emattype=1
  call ematbdcmbs(input%xs%emattype)
  !-------------------------------!
  !     loop over (k,kp) pairs    !
  !-------------------------------!
  nkkp=(nkptnr*(nkptnr+1))/2
  call genparidxran('p',nkkp)
  call genfilname(basename='EXCLI',asc=.true.,filnam=fnexcli)
  call getunit(un)
  if (rank.eq.0) open(un,file=trim(fnexcli),form='formatted',action='write', &
	status='replace')

  do ikkp=ppari,pparf
     call chkpt(3,(/task,2,ikkp/),'task,sub,(k,kp)-pair; exchange term of &
	  &associated(input%xs%BSE) - Hamiltonian')
     call kkpmap(ikkp,nkptnr,iknr,jknr)
     iv(:)=ivknr(:,jknr)-ivknr(:,iknr)
     iv(:)=modulo(iv(:), input%groundstate%ngridk(:))
     ! q-point (reduced)
     iqr=iqmapr(iv(1),iv(2),iv(3))
     ! q-point (non-reduced)
     iq=iqmap(iv(1),iv(2),iv(3))

     ! set G=0 term of Coulomb potential to zero [Ambegaokar-Kohn]
     potcl(1)=0.d0
     ! set up Coulomb potential
     do igq1=2,n
        call genwiqggp(0,iqmt,igq1,igq1,potcl(igq1))
     end do

     call genfilname(dotext='_SCR.OUT',setfilext=.true.)
     j1=0
     do ist2=1,nst2
        do ist1=1,nst1
           j1=j1+1
           emat12(j1,:)=emat12k(ist1,ist2,:,iknr)
        end do
     end do
     j2=0
     do ist4=1,nst2
        do ist3=1,nst1
           j2=j2+1
           emat34(j2,:)=emat12k(ist3,ist4,:,jknr)*potcl(:)
        end do
     end do

     ! calculate exchange matrix elements: V_{1234} = M_{12}^* M_{34}^T
     emat12=conjg(emat12)
     call zgemm('n','t', nst12, nst12, n, zone/omega/nkptnr, emat12, &
          nst12, emat34, nst12, zzero, exclit, nst12 )

     ! map back to individual band indices
     j2=0
     do ist4=1,nst2
        do ist3=1,nst1
           j2=j2+1
           j1=0
           do ist2=1,nst2
              do ist1=1,nst1
                 j1=j1+1
                 excli(ist1,ist2,ist3,ist4)=exclit(j1,j2)
              end do
           end do
        end do
     end do

     if ((rank.eq.0).and.(ikkp.le.3)) then
        do ist1=1,nst1
           do ist2=1,nst2
              do ist3=1,nst1
                 do ist4=1,nst2
                    write(un,'(i5,3x,3i4,2x,3i4,2x,4e18.10)') ikkp,iknr,ist1,&
                         ist2,jknr,ist3,ist4,excli(ist1,ist2,ist3,ist4),&
                         abs(excli(ist1,ist2,ist3,ist4))
                 end do
              end do
           end do
        end do
     end if

     ! parallel write
     call putbsemat('EXCLI.OUT',excli,ikkp,iknr,jknr,iq,iqr,nst1,nst2,nst4,nst3)
     call genfilname(dotext='_SCI.OUT',setfilext=.true.)

     ! end loop over (k,kp) pairs
  end do
  if (rank.eq.0) write(un,'("# ikkp, iknr,ist1,ist3, jknr,ist2,ist4,    Re(V),            Im(V),             |V|^2")')
  if (rank.eq.0) close(un)

  call barrier
  call findgntn0_clear
  deallocate(emat12k,exclit,emat12,emat34)
  deallocate(potcl,excli)

  write(unitout,'(a)') "Info("//trim(thisnam)//"): Exchange Coulomb interaction&
       & finished"
end subroutine exccoulint
