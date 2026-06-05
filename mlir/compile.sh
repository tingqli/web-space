


/root/tingqli/llvm-project/mlir_install/bin/mlir-opt input.mlir \
  --convert-math-to-rocdl \
  --lower-affine \
  --convert-scf-to-cf \
  --convert-vector-to-llvm \
  --expand-strided-metadata \
  --finalize-memref-to-llvm \
  --convert-func-to-llvm \
  --convert-arith-to-llvm \
  --convert-cf-to-llvm \
  --reconcile-unrealized-casts \
  -o opt.mlir

mlir-translate -mlir-to-llvmir opt.mlir -o opt.ll