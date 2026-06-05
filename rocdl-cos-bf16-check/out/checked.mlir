module {
  llvm.func @cos_bf16(%arg0: bf16) -> bf16 {
    %0 = rocdl.cos %arg0 bf16 -> bf16
    llvm.return %0 : bf16
  }
  llvm.func @cos_f32(%arg0: f32) -> f32 {
    %0 = rocdl.cos %arg0 f32 -> f32
    llvm.return %0 : f32
  }
}

