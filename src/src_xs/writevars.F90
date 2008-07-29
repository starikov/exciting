
! Copyright (C) 2004-2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

module m_writevars
  implicit none
contains

  subroutine writevars(un,iq)
    use modmain
    use modxs
    implicit none
    ! arguments
    integer, intent(in) :: iq,un
    ! local variables
    character(10) :: dat,tim
    ! write prologue to file
    call date_and_time(date=dat,time=tim)
    write(un,*)
    write(un,'("## Date (YYYY-MM-DD): ",a4,"-",a2,"-",a2)') &
         dat(1:4),dat(5:6),dat(7:8)
    write(un,'("## Time (hh:mm:ss)  : ",a2,":",a2,":",a2)') &
         tim(1:2),tim(3:4),tim(5:6)
    write(un,'("# version           : ",i1.1,".",i1.1,".",i3.3)') version
    write(un,'("# version (xs)      : ",i1.1,".",i3.3)') versionxs
    write(un,'(a,2f12.6)') '# efermi (H,eV)     :',efermi,h2ev*efermi
    write(un,'(a,3f12.6)') '# vql               :',vql(:,iq)
    write(un,'(a,3f12.6)') '# vqc               :',vqc(:,iq)
    write(un,'(a,2i8)') '# optcomp           :',optcomp(1,1),optcomp(2,1)
    write(un,'(a,i8)') '# fxctype           :',fxctype
    write(un,'(a,f12.6)') '# alphalrc          :',alphalrc
    write(un,'(a,f12.6)') '# alphalrcdyn       :',alphalrcdyn
    write(un,'(a,f12.6)') '# betalrcdyn        :',betalrcdyn
    write(un,'(a,l8)') '# intraband         :',intraband
    write(un,'(a,l8)') '# aresdf            :',aresdf
    write(un,'(a,l8)') '# acont             :',acont
    write(un,'(a,i8)') '# nwacont           :',nwacont
    write(un,'(a,2f12.6)') '# broad (H,eV)      :',broad,h2ev*broad
    write(un,'(a,2f12.6)') '# scissor (H,eV)    :',scissor,h2ev*scissor
    write(un,'(a,i8)') '# nwdos             :',nwdos
    write(un,'(a,i8)') '# ngq               :',ngq(iq)
    write(un,'(a,f12.6)') '# gqmax             :',gqmax
    write(un,'(a,f12.6)') '# gmaxvr            :',gmaxvr
    write(un,'(a,f12.6)') '# rgkmax            :',rgkmax
    write(un,'(a,f12.6)') '# gkmax             :',gkmax
    write(un,'(a,3i8)') '# ngridk            :',ngridk
    write(un,'(a,3f12.6)') '# vkloff            :',vkloff
    write(un,'(a,l8)') '# reducek           :',reducek
    write(un,'(a,i8)') '# nmatmax           :',nmatmax
    write(un,'(a,i8)') '# ngkmax            :',ngkmax
    write(un,'(a,i8)') '# nlotot            :',nlotot
    write(un,'(a,i8)') '# nlomax            :',nlomax
    write(un,'(a,i8)') '# nst1              :',nst1
    write(un,'(a,i8)') '# nst2              :',nst2
    write(un,'(a,i8)') '# nstsv             :',nstsv
    write(un,'(a,2f12.6)') '# evlmincut (H,eV)  :',evlmincut,h2ev*evlmincut
    write(un,'(a,2f12.6)') '# evlmaxcut (H,eV)  :',evlmaxcut,h2ev*evlmaxcut
    write(un,'(a,2f12.6)') '# evlmin (H,eV)     :',evlmin,h2ev*evlmin
    write(un,'(a,2f12.6)') '# evlmax (H,eV)     :',evlmax,h2ev*evlmax
    write(un,'(a,i5,2f12.6)') '# evlhpo (H,eV)     :',istocc0,evlhpo,h2ev*evlhpo
    write(un,'(a,i5,2f12.6)') '# evllpu (H,eV)     :',istunocc0,evllpu, &
         h2ev*evllpu
    write(un,'(a,l8)') '# ksgap             :',ksgap
    write(un,'(a,i8)') '# lmaxapw           :',lmaxapw
    write(un,'(a,i8)') '# lmaxapwwf         :',lmaxapwwf
    write(un,'(a,i8)') '# lmaxmat           :',lmaxmat
    write(un,'(a,i8)') '# lmaxvr            :',lmaxvr
    write(un,'(a,i8)') '# lmaxinr           :',lmaxinr
    write(un,'(a,i8)') '# lolmax            :',lolmax
    write(un,'(a,i8)') '# lmaxemat          :',lmaxemat
    write(un,'(a,i8)') '# lradstp           :',lradstp
    write(un,'(a,l8)') '# tevout            :',tevout
    write(un,'(a,l8)') '# fastpmat          :',fastemat
    write(un,'(a,l8)') '# fastemat          :',fastemat
    write(un,'(a,l8)') '# nosym             :',nosym
    write(un,'(a,l8)') '# symwings          :',symwings
    write(un,'(a,l8)') '# tsymdfq0dn        :',tsymdfq0dn
    write(un,'(a,9f12.6)') '# symdfq0 (row1)    :',symdfq0(1,:)
    write(un,'(a,9f12.6)') '# symdfq0 (row2)    :',symdfq0(2,:)
    write(un,'(a,9f12.6)') '# symdfq0 (row3)    :',symdfq0(3,:)
    write(un,*)
  end subroutine writevars

end module m_writevars