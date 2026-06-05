// Test rocdl.cos with bf16 input type
// Minimal test case using LLVM dialect

module {
  llvm.func @test_cos_bf16(%arg0: bf16) -> bf16 {
    %result = rocdl.cos %arg0 bf16 -> bf16
    llvm.return %result : bf16
  }
}
