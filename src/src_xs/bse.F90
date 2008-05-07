
! Copyright (C) 2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

subroutine bse
  use modmain
  use modxs
  use m_genwgrid
  use m_getpmat
  use m_genfilname
  use m_getunit
  implicit none
  ! local variables
  character(*), parameter :: thisnam='bse'
  integer, parameter :: iqmt=1
  character(256) :: fnamesc,fnameex,fnamepm
  real(8), parameter :: epsortho=1.d-12
  integer :: iknr,jknr,iqr,iq,recl,iw
  integer :: ngridkt(3),iv2(3),unsc,unex,s1,s2,hamsiz,nexc
  integer :: ist1,ist2,ist3,ist4,ikkp,oct
  integer :: iv,ic,lwork
  logical :: nosymt,reducekt
  real(8) :: vklofft(3),abstol,de
  real(8), allocatable :: rwork(:),beval(:),spectrkk(:),w(:),oszsa(:)
  integer, allocatable :: iwork(:),ifail(:),sor(:)
  complex(8), allocatable :: excli(:,:,:,:),sccli(:,:,:,:),ham(:,:),work(:)
  complex(8), allocatable :: bevec(:,:),pm(:,:,:),pmat(:),oszs(:),spectr(:)
  integer :: ikkp_,iknr_,jknr_,iq_,iqr_,nst1_,nst2_,nst3_,nst4_

  integer :: nvdif,ncdif,il,iu,nbeval,info
  real(8) :: vl,vu,egap

  ! external functions  integer, external :: iplocnr
  logical, external :: tqgamma
  integer, external :: l2int
  real(8), external :: dlamch

  ! reset file extension to default
  call genfilname(setfilext=.true.)


!TODO: symmetrize head of DM for spectrum
!TODO: loop over optical components? use "optcomp"

oct=1

egap=1.d8

  ! type of contributions to BSE-Hamlitonian
  ! H = H_diag + 2H_x + H_c
  ! H_diag .......... diagonal term containing IP-energy-differences
  ! H_x ............. exchange term
  ! H_c ............. correlation term
  ! value of bsetype corresponds to
  ! ip      ........... H = H_diag                     IP-spectrum
  ! rpa     ........... H = H_diag + 2H_x              RPA-spectrum
  ! singlet ........... H = H_diag + 2H_x + H_c        correlated, spin-singlet
  ! triplet ........... H = H_diag + H_c               correlated, spin-triplet

  !----------------!
  !   initialize   !
  !----------------!
  ! save global variables
  nosymt=nosym
  reducekt=reducek
  ngridkt(:)=ngridk(:)
  vklofft(:)=vkloff(:)
  ! map variables for screened Coulomb interaction
  call initbse
  nosym=nosymscr
  ! no symmetries implemented for screened Coulomb interaction
  reducek=.false.
  ! q-point set of screening corresponds to (k,kp)-pairs
  ngridk(:)=ngridq(:)
  vkloff(:)=vkloffbse(:)
  if (nemptyscr.eq.-1) nemptyscr=nempty
  emattype=1
  call init0
  call init1
  call init2xs
  ! read Fermi energy from file
  call readfermi
  call genfilname(dotext='_SCR.OUT',setfilext=.true.)
  call initoccbse
  call findocclims(0,istocc0,istocc,istunocc0,istunocc,isto0,isto,istu0,istu)
  call ematbdcmbs(emattype)

  write(*,'("number of states below Fermi energy:",i6)') nstbef
  write(*,'("number of states above Fermi energy:",i6)') nstabf

nvdif=nstval-nstbef
ncdif=nstcon-nstabf

write(*,*) 'nvdif',nvdif
write(*,*) 'ncdif',ncdif
write(*,*) 'oct',oct

if ((nvdif.lt.0).or.(ncdif.lt.0)) stop 'bse: bad nstbef,nstabf'

  ! size of BSE-Hamiltonian
  hamsiz=nstbef*nstabf*nkptnr

  write(*,'(a,4i6)') 'nst1,2,3,4',nst1,nst2,nst3,nst4
  allocate(sccli(nst1,nst2,nst1,nst2))
  allocate(excli(nst1,nst2,nst1,nst2))
  ! allocate BSE-Hamiltonian (large matrix, up to several GB)
  allocate(ham(hamsiz,hamsiz))
  ham(:,:)=zzero

  inquire(iolength=recl) ikkp,iknr,jknr,iq,iqr,nst1,nst2,nst3,nst4, &
       sccli(:,:,:,:)
  call genfilname(basename='SCCLI',dotext='.OUT',filnam=fnamesc)
  call genfilname(basename='EXCLI',dotext='.OUT',filnam=fnameex)
  call getunit(unsc)
  open(unsc,file=trim(fnamesc),form='unformatted',action='read', &
       status='old',access='direct',recl=recl)
  call getunit(unex)
  open(unex,file=trim(fnameex),form='unformatted',action='read', &
       status='old',access='direct',recl=recl)

write(*,*) 'shape(sccli)',shape(sccli)
write(*,*) 'record length for SCI',recl

  ! read in energies
  do iknr=1,nkptnr
     call getevalsv(vkl(1,iknr),evalsv(1,iknr))
  end do
  write(*,*) 'reading energies done'


  ! set up BSE-Hamiltonian
  do iknr=1,nkptnr
     do jknr=iknr,nkptnr
        ikkp=ikkp+1
        iv2(:)=ivknr(:,jknr)-ivknr(:,iknr)
        iv2(:)=modulo(iv2(:),ngridk(:))
        ! q-point (reduced)
        iqr=iqmapr(iv2(1),iv2(2),iv2(3))
        ! q-point (non-reduced)
        iq=iqmap(iv2(1),iv2(2),iv2(3))


!write(*,*) 'setting up Hamiltonian for (k,kp)-pair:',ikkp
        select case(trim(bsetype))
        case('singlet','triplet')
           ! read screened Coulomb interaction
           read(unsc,rec=ikkp) ikkp_,iknr_,jknr_,iq_,iqr_,nst1_,nst2_,nst3_, &
                nst4_,sccli
!!$           if ((ikkp.ne.ikkp_).or.(iknr.ne.iknr_).or.(jknr.ne.jknr_).or. &
!!$                (iq.ne.iq_).or.(iqr.ne.iqr_).or.(nst1.ne.nst1_).or. &
!!$                (nst2.ne.nst2_).or.(nst3.ne.nst3_).or.(nst4.ne.nst4_)) then
!!$              write(*,*)
!!$              write(*,'("Error(kernxc_bse): wrong indices for screened Coulomb&
!!$                   & interaction")')
!!$              write(*,'(" indices (ikkp,iknr,jknr,iq,iqr,nst1,nst2,nst3,&
!!$                   &nst4)")')
!!$              write(*,'(" current:",i6,3x,2i4,2x,2i4,2x,4i4)') ikkp,iknr,jknr,&
!!$                   iq,iqr,nst1,nst2,nst3,nst4
!!$              write(*,'(" file   :",i6,3x,2i4,2x,2i4,2x,4i4)') ikkp_,iknr_,&
!!$                   jknr_,iq_,iqr_,nst1_,nst2_,nst3_,nst4_
!!$              write(*,*)
!!$              call terminate
!!$           end if
        end select

        ! read exchange Coulomb interaction
        select case(trim(bsetype))
        case('rpa','singlet')
           read(unex,rec=ikkp) ikkp_,iknr_,jknr_,iq_,iqr_,nst1_,nst2_,nst3_, &
                nst4_,excli
!!$           if ((ikkp.ne.ikkp_).or.(iknr.ne.iknr_).or.(jknr.ne.jknr_).or. &
!!$                (iq.ne.iq_).or.(iqr.ne.iqr_).or.(nst1.ne.nst1_).or. &
!!$                (nst2.ne.nst2_).or.(nst3.ne.nst3_).or.(nst4.ne.nst4_)) then
!!$              write(*,*)
!!$              write(*,'("Error(kernxc_bse): wrong indices for exchange Coulomb&
!!$                   & interaction")')
!!$              write(*,'(" indices (ikkp,iknr,jknr,iq,iqr,nst1,nst2,nst3,&
!!$                   &nst4)")')
!!$              write(*,'(" current:",i6,3x,2i4,2x,2i4,2x,4i4)') ikkp,iknr,jknr,&
!!$                   iq,iqr,nst1,nst2,nst3,nst4
!!$              write(*,'(" file   :",i6,3x,2i4,2x,2i4,2x,4i4)') ikkp_,iknr_,&
!!$                   jknr_,iq_,iqr_,nst1_,nst2_,nst3_,nst4_
!!$              write(*,*)
!!$              call terminate
!!$           end if
        end select

        do ist1=1+nvdif,nst1
           do ist2=1,nst2-ncdif
              do ist3=1+nvdif,nst1
                 do ist4=1,nst2-ncdif
                    s1=hamidx(ist1-nvdif,ist2,iknr,nstbef,nstabf)
                    s2=hamidx(ist3-nvdif,ist4,jknr,nstbef,nstabf)
                    ! add diagonal term
                    if (s1.eq.s2) then
                       de=evalsv(ist2+istocc,iknr)-evalsv(ist1,iknr)+scissor
                       ham(s1,s2)=ham(s1,s2)+de
                       egap=min(egap,de)
                    end if
                    ! add exchange term
                    select case(trim(bsetype))
                    case('rpa','singlet')
                       ham(s1,s2)=ham(s1,s2)+ &
                            2.d0*excli(ist1,ist2,ist3,ist4)
                    end select
                    ! add correlation term
                    select case(trim(bsetype))
                    case('singlet','triplet')
                       ham(s1,s2)=ham(s1,s2)-               &
                            sccli(ist1,ist2,ist3,ist4)
                    end select
                 end do
              end do
           end do
        end do

        ! end loop over (k,kp)-pairs
     end do
  end do

  deallocate(excli,sccli)


  abstol=2.d0*dlamch('S')
  lwork=(32+1)*hamsiz
  allocate(work(lwork),rwork(7*hamsiz),iwork(5*hamsiz),ifail(hamsiz))
  allocate(beval(hamsiz),bevec(hamsiz,hamsiz))
  

  write(*,*) 'call to zheevx..............'
  write(*,*) 'Hamiltonian size is: ', hamsiz

  ! LAPACK 3.0 call
  call zheevx('V','A','U',hamsiz,ham,hamsiz,vl,vu,il,iu, &
       abstol,nbeval,beval,bevec,hamsiz,work,lwork,rwork, &
       iwork,ifail,info)

  write(*,'(a,i8)') 'Info(bse): nbeval',nbeval

  if (info.ne.0) then
     write(*,*)
     write(*,'("Error(bse): zheevx returned non-zero info:",i6)') info
     write(*,*)
     call terminate
  end if

  write(*,*) 'zheevx finished..............'

  ! deallocate Hamiltonian array
  deallocate(ham,work,rwork,iwork,ifail)

  ! read momentum matrix elements
  call genfilname(basename='PMAT_XS',dotext='.OUT',filnam=fnamepm)
  allocate(pm(3,nstsv,nstsv),pmat(hamsiz))
  do iknr=1,nkptnr
     call getpmat(iknr,vkl,.true.,trim(fnamepm),pm)
     do ist1=1+nvdif,nstsv-nstcon
        do ist2=nstval+1,nstsv-ncdif
           s1=hamidx(ist1-nvdif,ist2-nstval,iknr,nstbef,nstabf)
           pmat(s1)=pm(oct,ist1,ist2)

write(985,'(i6,3x,3i6,2g18.10)') s1,iknr,ist1,ist2,pmat(s1)

        end do
     end do
  end do
  deallocate(pm)

  ! calculate oscillators for spectrum  
  ! number of excitons to consider
  nexc=hamsiz
  allocate(oszs(nexc),oszsa(nexc),sor(nexc))
  oszs(:)=zzero
  do s1=1,nexc
     do iknr=1,nkptnr
        do iv=1,nstbef
           do ic=1,nstabf
              s2=hamidx(iv,ic,iknr,nstbef,nstabf)
              oszs(s1)=oszs(s1)+bevec(s2,s1)*pmat(s2)/(evalsv(ic+istocc,iknr)- &
                   evalsv(iv+nvdif,iknr))
           end do
        end do
     end do
  end do
  deallocate(bevec)

  ! calculate spectrum
  allocate(w(nwdos),spectr(nwdos),spectrkk(nwdos))
  call genwgrid(nwdf,wdos,acont,0.d0,w_real=w)
  spectr(:)=zzero
  spectrkk(:)=zzero
  do iw=1,nwdos
     do s1=1,nexc
        ! Lorentzian lineshape
        spectr(iw)=spectr(iw) + abs(oszs(s1))**2 * ( &
             1.d0/(w(iw)-beval(s1)+zi*brdtd) + &
             1.d0/(-w(iw)-beval(s1)-zi*brdtd) )
     end do
  end do
  spectr(:)=l2int(oct.eq.oct)*1.d0-spectr(:)*8.d0*pi/omega/nkptnr
  call kramkron(oct,oct,epslat,nwdos,dble(w),aimag(spectr),spectrkk)
  do s2=1,hamsiz
     write(983,'(i8,5g18.10)') s2,beval(s2)*escale,(beval(s2)-egap)*escale, &
          abs(oszs(s2))
  end do



  oszsa=abs(oszs)
  call sortidx(hamsiz,oszsa,sor)
  sor=sor(hamsiz:1:-1)
!  oszs=oszs(sor)
  do s1=1,hamsiz
     s2=sor(s1)
     write(984,'(i8,4g18.10)') s1,beval(sor(s2))*escale, &
          (beval(sor(s2))-egap)*escale,abs(oszs(s2))
  end do


do iw=1,nwdos
   write(788,'(i6,4g18.10)') iw,escale*w(iw),spectr(iw),spectrkk(iw)
end do

!///////////////////////////////////////////////////////////////////////////////
contains

  integer function hamidx(iv,ic,ik,nv,nc)
    use modxs
    implicit none
    integer, intent(in) :: iv,ic,ik,nv,nc
    hamidx=iv + nv*(ic-1) + nv*nc*(ik-1)
  end function hamidx



end subroutine bse
