program main
use inputdom
use modinput
use scl_xml_out_Module
use modmpi

implicit none
 call initMPI()
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
 call finitMPI()
end program

