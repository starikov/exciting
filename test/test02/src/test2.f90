program test
use inputdom
use modinput
use scl_xml_out_Module
implicit none
call loadinputDOM()
call setdefault
input=getstructinput(inputnp)
call ifparseerrorstop()
call destroyDOM()
call initatomcounters()
call initlattice
call readspeciesxml
call scl_xml_out_create()
call tasklauncher()
call scl_xml_out_close()

call write_evec_formatted()

call scl_xml_out_close()
!call finalizeoutput()
end program
