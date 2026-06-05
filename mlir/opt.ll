; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

@printfFormat_0 = internal constant [13 x i8] c"Hello,World\0A\00"

declare i64 @__ockl_printf_append_string_n(i64, ptr, i64, i32)

declare i64 @__ockl_printf_append_args(i64, i32, i64, i64, i64, i64, i64, i64, i64, i32)

declare i64 @__ockl_printf_begin(i64)

define amdgpu_kernel void @my_kernel(ptr addrspace(1) %0, float %1) #0 {
  %3 = call i64 @__ockl_printf_begin(i64 0)
  %4 = call i64 @__ockl_printf_append_string_n(i64 %3, ptr @printfFormat_0, i64 13, i32 0)
  %5 = call i64 @__ockl_printf_append_args(i64 %4, i32 1, i64 42, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i32 1)
  ret void
}

attributes #0 = { "amdgpu-flat-work-group-size"="1,256" "uniform-work-group-size" }

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}