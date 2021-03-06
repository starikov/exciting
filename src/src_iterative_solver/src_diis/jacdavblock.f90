



subroutine jacdavblock(n, m, system, ld, u, u_A, u_B, theta, t, t_A, flag)
 use modmain, only: nstfv
use modfvsystem
	IMPLICIT NONE
	INTEGER, intent(in) :: n, m, ld
	type(evsystem), intent(in) :: system
	DOUBLE COMPLEX, intent(in) :: u(ld, nstfv)   
	DOUBLE COMPLEX, intent(in) :: u_A(ld, nstfv )
	DOUBLE COMPLEX, intent(in) :: u_B(ld, nstfv)
	DOUBLE PRECISION, intent(in) :: theta(nstfv)
	DOUBLE COMPLEX, intent(out) :: t(ld, nstfv)
	DOUBLE COMPLEX, intent(out) :: t_A(ld, nstfv)
	INTEGER, intent(in) :: flag

!Purpose:
!========
!
!   Perform only one (inner) iteration for the itearive solution of 
!
!     A1 * t = r,  t'*B*u = 0
!
!   for the unknown t with
!
!     A1 = (I-(B*u*u')/(u'*B*u))*(A-theta*B)*(I-(u*u'*B)/(u'*B*u))
!     r = (A-theta*B)*u
!     theta = (u'*A*u)/(u'*B*u)  ("Ritz value")
!
!   using a preconditioner
!
!      K1 = (I-(B*u*u')/(u'*B*u))*K*(I-(u*u'*B)/(u'*B*u))
!
!   where inv(K) approximates inv(A-theta*B). 
!   In this implementation we use K = inv(A)
!
!   u may actually be a matrix (m columns), such that m right hand sides r
!   are treated all at once. In this case, u_A and  u_B must also be matrices
!   of the appropriate sizes.
!
!   The matrices A and B are assumed to be symmetric and are
!   both passed via AB. 
!   A is needed only for the initialization step  (flag=0, see below),
!   only the entries on and BELOW the diagonal of A are used.
!   B is needed only for the computational step(s) (flag=1, see below),
!   only the entries on and ABOVE the diagonal of B are used.
!
!   The matrix vector (resp. matrix matrix) products u_A = A*u and 
!   u_B = B*u and the Ritz values theta =(u'*u_A)/(u'*u_B) are 
!   (not computed but) passed  to this subroutine because these values 
!   are needed by the calling routine anyway.
!
!   This subroutine must first be initialized by calling it with flag=0,
!   see below. The actual computational runs are then performed by
!   calling this routine with flag=1. Finally, this routine has to be
!   called with flag=-1 which will free all allocated resources. 
!
!
!Arguments:
!==========
!
!   n      (input for flag = 0 or 1) INTEGER 
!	   The dimension of the problem. 
!          NOTE: It is assumed that the matrices AB, u, u_A, u_B, and t
!          all have leading dimension n.
!
!   m      (input for flag = 1) INTEGER
!          The number of right hand sides, i.e., the number of columns
!          of the matrices u, u_A, u_B, and t.
!
!   AB     (input for flag = 0 or 1) DOUBLE COMPLEX array, dimension (n, n)
!          For flag = 0: The matrix A (only the entries on and BELOW the 
!                        diagonal are used).
!          For flag = 1: The matrix B (only the entries on and ABOVE the
!                        diagonal are used).
!
!  ld      (input for flag = 0 or 1) INTEGER
!          The leading dimension of AB.
!          NOTE: It is assumed that the matrices u, u_A, u_B, and t
!          also have leading dimension ld.
!
!   u      (input for flag = 1) DOUBLE COMPLEX array, dimension (n, m)
!          The vectors u. 
!
!   u_A    (input for flag = 1) DOUBLE COMPLEX array, dimension (n, m)
!	   u_A = A*u (not needed, only for a consistent interface).
!
!   u_B    (input for flag = 1) DOUBLE COMPLEX array, dimension (n, m)
!	   u_B = B*u
!
!   theta  (input for flag = 1) DOUBLE COMPLEX array, dimesion m
!          The Ritz values theta(i) = (u(:,i)'*u_A(:,i))/(u(:,i)'*u_B(:,i))
!
!   t      (output for flag = 1) DOUBLE COMPLEX array, dimension (n, m)
!          The approximation to solution obtained after one iteration.
! 
!   flag   (input) INTEGER
!          =  0: init; allocate resources, prepare preconditioner
!          =  1: apply;
!          = -1: finish; free resources
!   
!       
!Method:
!=======
!
!   This subroutine is modelled after the following MATLAB code:
!
!      u_A = A*u;
!      u_B = B*u;
!      theta = (u'*u_A)/(u'*u_B);
!       
!      u_B1 = A\u_B;
!      mu = u_B'*u_B1
!      r = u - theta*u_B1;       
!      r = r - ((u_B'*r)/mu)*u_B1; 
!
!      t = -theta*B*r
!      t = A\t
!      t = t + r
!      t = t - ((u_B'*t)/mu)*u_B1;
!
!
!   The algorithm is based on considerations from
!
!    "Templates for the Solution of Algebraic Eigenvalue Problems: 
!     A Practical Guide"
!     (TODO: precise reference)
!
! ..

	DOUBLE COMPLEX, allocatable, save :: u_B1(:, :)
	DOUBLE COMPLEX, allocatable :: work(:)
	DOUBLE COMPLEX, allocatable, save :: Afacts(:, :)
	INTEGER, allocatable, save :: ipiv(:)
	INTEGER :: i, j, info, lwork
	DOUBLE COMPLEX :: olwork
	DOUBLE COMPLEX :: dconjg 

!from BLAS:
	DOUBLE COMPLEX, external :: zdotc
	EXTERNAL :: zcopy, zaxpy, zscal, zhemm
!from LAPACK:
	EXTERNAL :: zhetrf, zhetrs


	IF (flag == 0) THEN ! INIT

            ! construct precondtioner for A-theta*B
            ! We use a factorization of A which is assumed to be 
            ! symmetric but not necessarily positive definite

            ! workspace query: get optimal size of work
	    call zhetrf("L", n, Afacts, n, ipiv, olwork, -1, info )
	    lwork = olwork

	    ALLOCATE( work(lwork), Afacts(n, n), ipiv(n) ) !TODO: error handling

            ! Afacts = A 
	    do j = 1, n
		do i = 1, n
		    Afacts(j, i) = system%hamilton%za(j, i) 
		end do
	    end do

	    call zhetrf("L", n, Afacts, n, ipiv, work, lwork, info )
	    if (info .ne. 0) then
		print *, "zhetrf: info = ", info
		stop "jacdavblock"
	    end if

	    DEALLOCATE( work )

	    ALLOCATE ( u_B1(n, m) ) ! todo: error handling 

	    RETURN

	ELSE IF (flag == -1) THEN ! FINISH

	    DEALLOCATE ( u_B1 )
	    DEALLOCATE ( Afacts, ipiv )

	    RETURN

	END IF

        ! u_B1 = u_B;
        ! t = u
        ! t_A = u_A
	IF (ld == n) THEN
            !only one call to dcopy necessary 
	    call zcopy(n*m, u, 1, t, 1)
	    call zcopy(n*m, u_B, 1, u_B1, 1)
	    call zcopy(n*m, u_A, 1, t_A, 1)
	ELSE
	    DO i=1, m
	       call zcopy(n, u(:, i), 1, t(:, i), 1)
	       call zcopy(n, u_B(:, i), 1, u_B1(:, i), 1)
	       call zcopy(n, u_A(:, i), 1, t_A(:, i), 1)
	    END DO
	END IF	  

        ! u_B1 = A\u_B1;
	call zhetrs("L", n, m, Afacts, n, ipiv, u_B1, n, info)

	DO i = 1, m 
            ! t = t - theta*u_B1;       
	    call zaxpy(n, -dcmplx(theta(i)), u_B1(:, i), 1, t(:, i), 1)
            ! t_A = t_A - theta*u_B;
	    call zaxpy(n, -dcmplx(theta(i)), u_B(:, i), 1, t_A(:, i), 1)
	END DO

	RETURN

END SUBROUTINE jacdavblock
