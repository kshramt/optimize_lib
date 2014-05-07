program main
   use, intrinsic:: iso_fortran_env, only: REAL64, INT64
   use, intrinsic:: iso_fortran_env, only: INPUT_UNIT, OUTPUT_UNIT, ERROR_UNIT
   use, non_intrinsic:: optimize_lib, only: nnls_lbfgsb

   implicit none

   Real(kind=REAL64), allocatable:: A(:, :), x_orig(:), x_optim(:), b(:), tA(:, :)
   Integer(kind=INT64):: n, i

   n = 5
   allocate(A(2*n, n))
   call random_number(A)
   allocate(tA(size(A, 2), size(A, 1)))
   tA(:, :) = transpose(A)
   allocate(x_orig(size(A, 2)))
   x_orig(:) = zero_if_even([(i, i=1, n)])
   allocate(b(size(A, 1)))
   b(:) = matmul(A, x_orig)
   x_optim = nnls_lbfgsb(matmul(tA, A), matmul(tA, b), m=4, factr=1.0d0, pgtol=epsilon(1.0d0))
   write(OUTPUT_UNIT, *)
   write(OUTPUT_UNIT, *) x_orig
   write(OUTPUT_UNIT, *) x_optim

   n = 20
   deallocate(A, tA, x_orig, b)
   allocate(A(2*n, n))
   call random_number(A)
   allocate(tA(size(A, 2), size(A, 1)))
   tA(:, :) = transpose(A)
   allocate(x_orig(size(A, 2)))
   x_orig(:) = zero_if_even([(i, i=1, n)])
   allocate(b(size(A, 1)))
   b(:) = matmul(A, x_orig)
   x_optim = nnls_lbfgsb(matmul(tA, A), matmul(tA, b), m=4)
   write(OUTPUT_UNIT, *)
   write(OUTPUT_UNIT, *) x_orig
   write(OUTPUT_UNIT, *) x_optim
   x_optim = nnls_lbfgsb(matmul(tA, A), matmul(tA, b), m=4, factr=1.0d0)
   write(OUTPUT_UNIT, *) x_optim

   n = 20
   deallocate(A, tA, x_orig, b)
   allocate(A(2*n, n))
   call random_number(A)
   allocate(tA(size(A, 2), size(A, 1)))
   tA(:, :) = transpose(A)
   allocate(x_orig(size(A, 2)))
   x_orig(:) = zero_if_even([(i - n/2, i=1, n)])
   allocate(b(size(A, 1)))
   b(:) = matmul(A, x_orig)
   x_optim = nnls_lbfgsb(matmul(tA, A), matmul(tA, b), m=4)
   write(OUTPUT_UNIT, *)
   write(OUTPUT_UNIT, *) x_orig
   write(OUTPUT_UNIT, *) x_optim
   x_optim = nnls_lbfgsb(matmul(tA, A), matmul(tA, b), m=4, factr=1.0d0)
   write(OUTPUT_UNIT, *) x_optim

   stop

contains

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
