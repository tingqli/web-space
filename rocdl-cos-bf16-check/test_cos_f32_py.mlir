module {
  llvm.func @test_cos_f32(%arg0: f32) -> f32 {
    %0 = rocdl.cos %arg0 f32 -> f32
    llvm.return %0 : f32
  }
}
