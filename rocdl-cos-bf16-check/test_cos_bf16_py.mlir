module {
  llvm.func @test_cos_bf16(%arg0: bf16) -> bf16 {
    %0 = rocdl.cos %arg0 bf16 -> bf16
    llvm.return %0 : bf16
  }
}
