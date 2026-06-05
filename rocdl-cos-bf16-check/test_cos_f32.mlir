// Working example: rocdl.cos with f32 (supported type)

module {
  llvm.func @test_cos_f32(%arg0: f32) -> f32 {
    %result = rocdl.cos %arg0 f32 -> f32
    llvm.return %result : f32
  }
}
