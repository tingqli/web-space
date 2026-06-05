; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

define bfloat @test_cos_bf16(bfloat %0) {
  %2 = call bfloat @llvm.amdgcn.cos.bf16(bfloat %0)
  ret bfloat %2
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare bfloat @llvm.amdgcn.cos.bf16(bfloat) #0

attributes #0 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
