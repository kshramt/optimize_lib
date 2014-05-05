module optimize_lib
   use, intrinsic:: iso_fortran_env, only: REAL64
   use, intrinsic:: iso_fortran_env, only: INPUT_UNIT, OUTPUT_UNIT, ERROR_UNIT

   implicit none

   private
   public:: nnls_lbfgsb

   interface nnls_lbfgsb
      module procedure nnls_lbfgsb
   end interface nnls_lbfgsb

contains


   ! Solve non-negative least square solution for $\bm{b} = \bm{A}\bm{x}$, where $\bm{A}$ is a $q \times n$ matrix and $\bm{b}$ is a data vector of size $q$.
   ! # References
   ! - Byrd, R. H., Lu, P., Nocedal, J., & Zhu, C. (1995). A Limited Memory Algorithm for Bound Constrained Optimization. SIAM Journal on Scientific Computing, 16(5), 1190–1208. doi:10.1137/0916069
   function nnls_lbfgsb(A, b, m, factr, pgtol) result(x)
      DoublePrecision, intent(in):: A(:, :), b(:)
      ! Size of limited memory approximation of a hessian matrix $\bm{B}$.
      ! According to `code.pdf` in the `Lbfgsb` distribution,
      ! > small values of $m$ (say $3 \le m \le 20$) are recommended,
      Integer, intent(in), optional:: m
      ! According to `code.pdf` in the `Lbfgsb` distribution,
      ! > $10^{12}$ for low accuracy; $10^{7}$ for moderate accuracy; $10^{1}$ for extremely high accuracy.
      Real(kind=kind(b)), intent(in), optional:: factr
      Real(kind=kind(b)), intent(in), optional:: pgtol
      ! Non-negative reast square solution of size $n$.
      Real(kind=kind(b)), allocatable:: x(:)

      ! Working variables.

      Real(kind=kind(b)), allocatable:: b_minus_Ax(:)

      ! See descriptions in `setulb` for the details.

      ! Size of the kernel matrix $\bm{A}$
      Integer(kind=kind(m)):: q, n, m_, iprint
      Real(kind=kind(b)), allocatable:: l(:), u(:), g(:), wa(:)
      Real(kind=kind(b)):: f
      Integer(kind=kind(m)), allocatable:: nbd(:), iwa(:)
      Real(kind=kind(factr)):: factr_, pgtol_
      Character(len=60):: task, csave
      Logical:: lsave(1:4)
      Integer(kind=kind(m)):: isave(1:44)
      Real(kind=kind(b)):: dsave(1:29)

      q = size(A, 1, kind=kind(q))
      n = size(A, 2, kind=kind(n))
      if(q < n)then
         write(ERROR_UNIT, *) 'ERROR: a number of data is less than a number of model parameter: ', q, n
         error stop
      end if

      allocate(x(1:n))
      x = 1 ! todo: allow user to specify the initial value for x
      allocate(b_minus_Ax(1:n))
      allocate(l(1:n))
      l = 0 ! lower bound is zero
      allocate(u(1:n)) ! upper bound is not used
      allocate(nbd(1:n))
      nbd = 1 ! consider only lower bounds
      ! default values are taken from `driver1.f90`
      if(present(m))then
         m_ = m
      else
         m_ = 5
      end if
      if(present(factr))then
         factr_ = factr
      else
         factr_ = 1.0e+7
      end if
      if(present(pgtol))then
         pgtol_ = pgtol
      else
         pgtol_ = 1.0e-5
      end if
      allocate(g(1:n))
      allocate(wa(1:((2*m_ + 5)*n + 12*m_**2 + 12*m_)))
      allocate(iwa(1:(3*n)))
      task = 'START'
      iprint = -1

      do while(task(1:2) == 'FG' .or. task == 'NEW_X' .or. task == 'START')
         call setulb(n, m_, x, l, u, nbd, f, g, factr_, pgtol_, wa, iwa, task, iprint, csave, lsave, isave, dsave)
         if(task(1:2) == 'FG')then
            b_minus_Ax(:) = b - matmul(A, x)
            f = dot_product(b_minus_Ax, b_minus_Ax)
            g(:) = 2*matmul(b_minus_Ax, A)
         end if
      end do
   end function nnls_lbfgsb
end module optimize_lib
