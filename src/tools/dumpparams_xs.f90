

! Copyright (C) 2008 S. Sagmeister and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

!BOP
! !ROUTINE: dumpparams_xs
! !INTERFACE:


subroutine dumpparams_xs(string, comment)
! !USES:
use modinput
  use modmain
  use modxs
! !DESCRIPTION:
!   Writes out all input parameters which can be specified in the input file
!   {\tt exciting.in}.
!   Only show those array elements that are within a corresponding cutoff.
!   Trailling whitespaces in string expressions are trimmed.
!   This routine refers only to the parameters related to the excited states
!   implementation.
!
! !REVISION HISTORY:
!   Created July 2008 (Sagmeister)
!EOP
!BOC
  implicit none
  ! arguments
  character(*), intent(in) :: string, comment
  ! local variables
  integer :: i
  call xssetversion
  open(unit=77, file=trim(string), action='write', position='append')
  write(77, *)
  write(77, '("! EXCITING version ", I1.1, ".", I1.1, ".", I3.3)') version
  write(77, '("! xs (eXited States) version ", I1.1, ".", I3.3)') versionxs
  write(77, '(a)') trim(comment)
  write(77, *)
  write(77, '("vgqlmt")')
  write(77, *)size(input%xs%qpointset%qpoint,2)
  do i=1,size(input%xs%qpointset%qpoint,2)
    write(77, *) input%xs%qpointset%qpoint(:, i)
  end do
  write(77, *)
  write(77, '("mdfqtype")')
  write(77, *) input%xs%tddft%mdfqtype
  write(77, *)
  write(77, '("gqmax")')
  write(77, *) input%xs%gqmax
  write(77, *)
  write(77, '("lmaxapwwf")')
  write(77, *) input%xs%lmaxapwwf
  write(77, *)
  write(77, '("fastpmat")')
  write(77, *) input%xs%fastpmat
  write(77, *)
  write(77, '("fastemat")')
  write(77, *) input%xs%fastemat
  write(77, *)
  write(77, '("emattype")')
  write(77, *) input%xs%emattype
  write(77, *)
  write(77, '("lmaxemat")')
  write(77, *) input%xs%lmaxemat
  write(77, *)
  write(77, '("torddf")')
  write(77, *) input%xs%tddft%torddf
  write(77, *)
  write(77, '("tordfxc")')
  write(77, *) input%xs%tddft%tordfxc
  write(77, *)
  write(77, '("acont")')
  write(77, *) input%xs%tddft%acont
  write(77, *)
  write(77, '("nwacont")')
  write(77, *) input%xs%tddft%nwacont
  write(77, *)
  write(77, '("broad")')
  write(77, *) input%xs%broad
  write(77, *)
  write(77, '("aresdf")')
  write(77, *) input%xs%tddft%aresdf
  write(77, *)
  write(77, '("epsdfde")')
  write(77, *) input%xs%tddft%epsdfde
  write(77, *)
  write(77, '("emaxdf")')
  write(77, *) input%xs%emaxdf
  write(77, *)
  write(77, '("dfoffdiag")')
  write(77, *) input%xs%dfoffdiag
  write(77, *)
  write(77, '("tetradf")')
  write(77, *) input%xs%tetra%tetradf
  write(77, *)
  write(77, '("kerndiag")')
  write(77, *) input%xs%tddft%kerndiag
  write(77, *)
  write(77, '("fxctype")')
  write(77, *) input%xs%tddft%fxctypenumber
  write(77, *)
  write(77, '("nexcitmax")')
  write(77, *) input%xs%BSE%nexcitmax
  write(77, *)
  write(77, '("alphalrc")')
  write(77, *) input%xs%tddft%alphalrc
  write(77, *)
  write(77, '("alphalrcdyn")')
  write(77, *) input%xs%tddft%alphalrcdyn
  write(77, *)
  write(77, '("betalrcdyn")')
  write(77, *) input%xs%tddft%betalrcdyn
  write(77, *)
  write(77, '("dftrans")')
  write(77, *) ndftrans
  do i=1, ndftrans
     write(77, *) dftrans(:, i)
  end do
  write(77, *)
  write(77, '("gather")')
  write(77, *) input%xs%gather
  write(77, *)
  write(77, '("symmorph")')
  write(77, *) input%xs%symmorph
  write(77, *)
  write(77, '("tevout")')
  write(77, *) input%xs%tevout
  write(77, *)
  write(77, '("appinfo")')
  write(77, *) input%xs%tappinfo
  write(77, *)
  write(77, '("dbglev")')
  write(77, *) input%xs%dbglev
  write(77, *)
  write(77, '("screentype")')
  write(77, *) "'"//trim(input%xs%screening%screentype)//"'"
  write(77, *)
  write(77, '("nosymscr")')
  write(77, *) input%xs%screening%nosym
  write(77, *)
  write(77, '("reducekscr")')
  write(77, *) input%xs%screening%reducek
  write(77, *)
  write(77, '("ngridkscr")')
  write(77, *) input%xs%screening%ngridk
  write(77, *)
  write(77, '("vkloffscr")')
  write(77, *) input%xs%screening%vkloff
  write(77, *)
  write(77, '("rgkmaxscr")')
  write(77, *) input%xs%screening%rgkmax
  write(77, *)
  write(77, '("nemptyscr")')
  write(77, *) input%xs%screening%nempty
  write(77, *)
  write(77, '("scrherm")')
  write(77, *) input%xs%BSE%scrherm
  write(77, *)
  write(77, '("bsetype")')
  write(77, *) "'"//trim(input%xs%BSE%bsetype)//"'"
  write(77, *)

  write(77, *)

  write(77, *)


  write(77, *)
  write(77, '("nstlce")')
  write(77, *) nbfce, nafce
  write(77, *)
  write(77, '("nstlbse")')
  write(77, *) nbfbse, nafbse
  close(77)
end subroutine dumpparams_xs
!EOC
