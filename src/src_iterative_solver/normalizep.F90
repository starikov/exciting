



subroutine  normalizep(n, m, overlap, evecfv, ldv)	
use modmain, only:zone, zzero

implicit none
integer, intent (in)::n, m, ldv
complex(8), intent(in)::overlap(n*(n+1)/2)
complex(8), intent(out)::evecfv(ldv, m)
complex(8)::tmp(n), z
complex(8), external::zdotc
integer::i
do i=1, m
		call zhpmv('U', n, zone, overlap(1), evecfv(1, i), 1, zzero, tmp, 1)
	z =sqrt(dble (zdotc(n, evecfv(1, i), 1, tmp, 1)))
	z=1.0/z
	call zscal(n, z, evecfv(1, i), 1)
end do
end subroutine
