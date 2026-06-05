; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

define bfloat @cos_bf16(bfloat %0) {
  %2 = call bfloat @llvm.amdgcn.cos.bf16(bfloat %0)
  ret bfloat %2
}

define float @cos_f32(float %0) {
  %2 = call float @llvm.amdgcn.cos.f32(float %0)
  ret float %2
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare bfloat @llvm.amdgcn.cos.bf16(bfloat) #0

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.amdgcn.cos.f32(float) #0

attributes #0 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
