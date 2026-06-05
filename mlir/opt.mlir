module attributes {gpu.container_module} {
  gpu.module @kernels [#rocdl.target<chip = "gfx942">] {
    gpu.func @vec_cos_kernel(%arg0: memref<1024xf32, 1>, %arg1: memref<1024xf32, 1>) kernel attributes {passthrough = ["amdgpu-no-implicitarg-ptr"]} {
      %0 = llvm.mlir.constant(3 : i64) : i64
      %1 = llvm.mlir.constant(2 : i64) : i64
      %2 = llvm.mlir.constant(1 : i64) : i64
      %3 = llvm.mlir.constant(0 : i64) : i64
      %4 = llvm.mlir.constant(4 : index) : i64
      %5 = llvm.mlir.constant(1024 : index) : i64
      %6 = llvm.mlir.constant(0 : index) : i64
      %7 = builtin.unrealized_conversion_cast %arg1 : memref<1024xf32, 1> to !llvm.struct<(ptr<1>, ptr<1>, i64, array<1 x i64>, array<1 x i64>)>
      %8 = builtin.unrealized_conversion_cast %arg0 : memref<1024xf32, 1> to !llvm.struct<(ptr<1>, ptr<1>, i64, array<1 x i64>, array<1 x i64>)>
      llvm.br ^bb1(%6 : i64)
    ^bb1(%9: i64):  // 2 preds: ^bb0, ^bb2
      %10 = llvm.icmp "slt" %9, %5 : i64
      llvm.cond_br %10, ^bb2, ^bb3
    ^bb2:  // pred: ^bb1
      %11 = llvm.extractvalue %8[1] : !llvm.struct<(ptr<1>, ptr<1>, i64, array<1 x i64>, array<1 x i64>)> 
      %12 = llvm.getelementptr %11[%9] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      %13 = llvm.load %12 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<4xf32>
      %14 = llvm.extractelement %13[%3 : i64] : vector<4xf32>
      %15 = llvm.extractelement %13[%2 : i64] : vector<4xf32>
      %16 = llvm.extractelement %13[%1 : i64] : vector<4xf32>
      %17 = llvm.extractelement %13[%0 : i64] : vector<4xf32>
      %18 = rocdl.cos %14 f32 -> f32
      %19 = rocdl.cos %15 f32 -> f32
      %20 = rocdl.cos %16 f32 -> f32
      %21 = rocdl.cos %17 f32 -> f32
      %22 = llvm.insertelement %18, %13[%3 : i64] : vector<4xf32>
      %23 = llvm.insertelement %19, %22[%2 : i64] : vector<4xf32>
      %24 = llvm.insertelement %20, %23[%1 : i64] : vector<4xf32>
      %25 = llvm.insertelement %21, %24[%0 : i64] : vector<4xf32>
      %26 = llvm.extractvalue %7[1] : !llvm.struct<(ptr<1>, ptr<1>, i64, array<1 x i64>, array<1 x i64>)> 
      %27 = llvm.getelementptr %26[%9] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f32
      llvm.store %25, %27 {alignment = 4 : i64} : vector<4xf32>, !llvm.ptr<1>
      %28 = llvm.add %9, %4 : i64
      llvm.br ^bb1(%28 : i64)
    ^bb3:  // pred: ^bb1
      gpu.return
    }
  }
}

