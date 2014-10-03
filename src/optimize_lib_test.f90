program main
   use, intrinsic:: iso_fortran_env, only: INT64
   use, intrinsic:: iso_fortran_env, only: INPUT_UNIT, OUTPUT_UNIT, ERROR_UNIT
   use, non_intrinsic:: optimize_lib, only: nnls_lbfgsb, REAL_KIND

   implicit none

   Real(kind=REAL_KIND), parameter:: TEN = 10
   Real(kind=REAL_KIND), allocatable:: A(:, :), x_orig(:), x_optim(:), b(:), tA(:, :)
   Integer(kind=INT64):: n_row, n_col, i

   read(INPUT_UNIT, *) n_row, n_col
   allocate(A(n_row, n_col))
   read(INPUT_UNIT, *) A
   allocate(tA(size(A, 2), size(A, 1)))
   tA(:, :) = transpose(A)
   allocate(x_orig(size(A, 2)))
   x_orig(:) = zero_if_even([(i, i=1, n_col)])
   allocate(b(size(A, 1)))
   b(:) = matmul(A, x_orig)
   x_optim = nnls_lbfgsb(matmul(tA, A), matmul(tA, b), m=4, factr=1.0d0, pgtol=sqrt(epsilon(1.0d0)))
   write(OUTPUT_UNIT, *) x_orig
   write(OUTPUT_UNIT, *) x_optim
   if(.not.all(almost_equal(x_orig, x_optim, relative=TEN**(-3), absolute=TEN**(-3))))then
      write(ERROR_UNIT, *) x_orig
      write(ERROR_UNIT, *) x_optim
      error stop
   end if

   stop

contains

   elemental function almost_equal(a, b, relative, absolute) result(ret)
      logical:: ret
      Real(kind=REAL_KIND), intent(in):: a
      Real(kind=REAL_KIND), intent(in):: b
      real(max(kind(a), kind(b))), intent(in), optional:: relative
      real(max(kind(a), kind(b))), intent(in), optional:: absolute

      real(max(kind(a), kind(b))):: delta, deltaRelative, deltaAbsolute
      real(min(kind(a), kind(b))):: lowerPrecision

      if(present(relative))then
         deltaRelative = max(abs(a)*relative, abs(b)*relative)
      else
         deltaRelative = 2*max(epsilon(a)*abs(a), epsilon(b)*abs(b))
      end if

      if(present(absolute))then
         deltaAbsolute = absolute
      else
         deltaAbsolute = 2*epsilon(lowerPrecision)*tiny(lowerPrecision)
      end if

      delta = max(deltaRelative, deltaAbsolute)
      ret = (abs(a - b) < delta)
   end function almost_equal

   elemental function zero_if_even(n) result(ret)
      Integer(kind=INT64), intent(in):: n
      Integer(kind=kind(n)):: ret
      if(mod(n, 2) == 0)then
         ret = 0
      else
         ret = n
      end if
   end function zero_if_even
end program main
