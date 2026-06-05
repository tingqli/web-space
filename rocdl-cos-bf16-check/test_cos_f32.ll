; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

define float @test_cos_f32(float %0) {
  %2 = call float @llvm.amdgcn.cos.f32(float %0)
  ret float %2
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.amdgcn.cos.f32(float) #0

attributes #0 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
