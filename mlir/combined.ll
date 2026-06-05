; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-p:64:64-p1:64:64-p2:32:32-p3:32:32-p4:64:64-p5:32:32-p6:32:32-p7:160:256:256:32-p8:128:128:128:48-p9:192:256:256:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-v2048:2048-n32:64-S32-A5-G1-ni:7:8:9"
target triple = "amdgcn-amd-amdhsa"

%struct.heap_s = type { [16 x %struct.start_s], [16 x %struct.start_s], [16 x %struct.start_s], [16 x %struct.rtcsample_s], [16 x %struct.rtcsample_s], [16 x [256 x %struct.sdata_s]], i64, i64, i64, [14 x i64], i64 }
%struct.start_s = type { i32, [15 x i64] }
%struct.rtcsample_s = type { i64, [15 x i64] }
%struct.sdata_s = type { i64, i64, i32 }
%struct.header_t = type { i64, i64, i32, i32 }
%struct.payload_t = type { [64 x [8 x i64]] }

@printfFormat_0 = internal constant [13 x i8] c"Hello,World\0A\00"
@get_heap_ptr.heap = internal addrspace(1) global %struct.heap_s zeroinitializer, align 8
@__oclc_ISA_version = linkonce_odr hidden local_unnamed_addr addrspace(4) constant i32 9402, align 4
@__oclc_wavefrontsize64 = linkonce_odr hidden local_unnamed_addr addrspace(4) constant i8 1, align 1
@__oclc_ABI_version = linkonce_odr hidden local_unnamed_addr addrspace(4) constant i32 600, align 4

define amdgpu_kernel void @my_kernel(ptr addrspace(1) %0, float %1) #0 {
  %3 = call i64 @__ockl_printf_begin(i64 0)
  %4 = call i64 @__ockl_printf_append_string_n(i64 %3, ptr @printfFormat_0, i64 13, i32 0)
  %5 = call i64 @__ockl_printf_append_args(i64 %4, i32 1, i64 42, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i32 1)
  ret void
}

; Function Attrs: convergent norecurse nounwind
define weak hidden i64 @__ockl_devmem_request(i64 noundef %0, i64 noundef %1) local_unnamed_addr #1 {
  %3 = tail call <2 x i64> @__ockl_hostcall_preview(i32 noundef 3, i64 noundef %0, i64 noundef %1, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0) #15
  %4 = extractelement <2 x i64> %3, i64 0
  ret i64 %4
}

; Function Attrs: cold convergent norecurse nounwind
define linkonce_odr hidden <2 x i64> @__ockl_hostcall_preview(i32 noundef %0, i64 noundef %1, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8) local_unnamed_addr #2 {
  %10 = load i32, ptr addrspace(4) @__oclc_ABI_version, align 4, !tbaa !5
  %11 = icmp slt i32 %10, 500
  %12 = tail call ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %13 = select i1 %11, i64 24, i64 80
  %14 = getelementptr inbounds nuw i8, ptr addrspace(4) %12, i64 %13
  %15 = load i64, ptr addrspace(4) %14, align 8, !tbaa !9
  %16 = inttoptr i64 %15 to ptr addrspace(1)
  %17 = addrspacecast ptr addrspace(1) %16 to ptr
  %18 = tail call <2 x i64> @__ockl_hostcall_internal(ptr noundef %17, i32 noundef %0, i64 noundef %1, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8) #16
  ret <2 x i64> %18
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef align 4 ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr() #3

; Function Attrs: convergent norecurse nounwind
define linkonce_odr hidden <2 x i64> @__ockl_hostcall_internal(ptr noundef captures(none) %0, i32 noundef %1, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8, i64 noundef %9) local_unnamed_addr #1 {
  %11 = tail call i32 @__ockl_lane_u32() #15
  %12 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %11)
  %13 = addrspacecast ptr %0 to ptr addrspace(1)
  %14 = icmp eq i32 %11, %12
  br i1 %14, label %15, label %37

15:                                               ; preds = %10
  %16 = getelementptr inbounds nuw i8, ptr addrspace(1) %13, i64 24
  %17 = load atomic i64, ptr addrspace(1) %16 syncscope("one-as") acquire, align 8
  %18 = getelementptr i8, ptr addrspace(1) %13, i64 40
  %19 = load ptr addrspace(1), ptr addrspace(1) %13, align 8, !tbaa !11
  %20 = load i64, ptr addrspace(1) %18, align 8, !tbaa !15
  %21 = and i64 %20, %17
  %22 = getelementptr inbounds nuw %struct.header_t, ptr addrspace(1) %19, i64 %21
  %23 = load atomic i64, ptr addrspace(1) %22 syncscope("one-as") monotonic, align 8
  %24 = cmpxchg ptr addrspace(1) %16, i64 %17, i64 %23 syncscope("one-as") acquire monotonic, align 8
  %25 = extractvalue { i64, i1 } %24, 1
  %26 = extractvalue { i64, i1 } %24, 0
  br i1 %25, label %37, label %27

27:                                               ; preds = %27, %15
  %28 = phi i64 [ %36, %27 ], [ %26, %15 ]
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  %29 = load ptr addrspace(1), ptr addrspace(1) %13, align 8, !tbaa !11
  %30 = load i64, ptr addrspace(1) %18, align 8, !tbaa !15
  %31 = and i64 %30, %28
  %32 = getelementptr inbounds nuw %struct.header_t, ptr addrspace(1) %29, i64 %31
  %33 = load atomic i64, ptr addrspace(1) %32 syncscope("one-as") monotonic, align 8
  %34 = cmpxchg ptr addrspace(1) %16, i64 %28, i64 %33 syncscope("one-as") acquire monotonic, align 8
  %35 = extractvalue { i64, i1 } %34, 1
  %36 = extractvalue { i64, i1 } %34, 0
  br i1 %35, label %37, label %27

37:                                               ; preds = %27, %15, %10
  %38 = phi i64 [ 0, %10 ], [ %26, %15 ], [ %36, %27 ]
  %39 = tail call i64 @llvm.amdgcn.readfirstlane.i64(i64 %38)
  %40 = load ptr addrspace(1), ptr addrspace(1) %13, align 8, !tbaa !11
  %41 = getelementptr i8, ptr addrspace(1) %13, i64 40
  %42 = load i64, ptr addrspace(1) %41, align 8, !tbaa !15
  %43 = and i64 %42, %39
  %44 = getelementptr inbounds nuw %struct.header_t, ptr addrspace(1) %40, i64 %43
  %45 = getelementptr i8, ptr addrspace(1) %13, i64 8
  %46 = load ptr addrspace(1), ptr addrspace(1) %45, align 8, !tbaa !16
  %47 = getelementptr inbounds nuw %struct.payload_t, ptr addrspace(1) %46, i64 %43
  %48 = tail call i64 @llvm.amdgcn.ballot.i64(i1 true)
  br i1 %14, label %49, label %53

49:                                               ; preds = %37
  %50 = getelementptr inbounds nuw i8, ptr addrspace(1) %44, i64 16
  %51 = getelementptr inbounds nuw i8, ptr addrspace(1) %44, i64 8
  %52 = getelementptr inbounds nuw i8, ptr addrspace(1) %44, i64 20
  store i32 %1, ptr addrspace(1) %50, align 8, !tbaa !17
  store i64 %48, ptr addrspace(1) %51, align 8, !tbaa !19
  store i32 1, ptr addrspace(1) %52, align 4, !tbaa !20
  br label %53

53:                                               ; preds = %49, %37
  %54 = zext i32 %11 to i64
  %55 = getelementptr inbounds nuw [8 x i64], ptr addrspace(1) %47, i64 %54
  store i64 %2, ptr addrspace(1) %55, align 8, !tbaa !9
  %56 = getelementptr inbounds nuw i8, ptr addrspace(1) %55, i64 8
  store i64 %3, ptr addrspace(1) %56, align 8, !tbaa !9
  %57 = getelementptr inbounds nuw i8, ptr addrspace(1) %55, i64 16
  store i64 %4, ptr addrspace(1) %57, align 8, !tbaa !9
  %58 = getelementptr inbounds nuw i8, ptr addrspace(1) %55, i64 24
  store i64 %5, ptr addrspace(1) %58, align 8, !tbaa !9
  %59 = getelementptr inbounds nuw i8, ptr addrspace(1) %55, i64 32
  store i64 %6, ptr addrspace(1) %59, align 8, !tbaa !9
  %60 = getelementptr inbounds nuw i8, ptr addrspace(1) %55, i64 40
  store i64 %7, ptr addrspace(1) %60, align 8, !tbaa !9
  %61 = getelementptr inbounds nuw i8, ptr addrspace(1) %55, i64 48
  store i64 %8, ptr addrspace(1) %61, align 8, !tbaa !9
  %62 = getelementptr inbounds nuw i8, ptr addrspace(1) %55, i64 56
  store i64 %9, ptr addrspace(1) %62, align 8, !tbaa !9
  br i1 %14, label %63, label %79

63:                                               ; preds = %53
  %64 = getelementptr inbounds nuw i8, ptr addrspace(1) %13, i64 32
  %65 = load atomic i64, ptr addrspace(1) %64 syncscope("one-as") monotonic, align 8
  %66 = load i64, ptr addrspace(1) %41, align 8, !tbaa !15
  %67 = and i64 %66, %39
  %68 = getelementptr inbounds nuw %struct.header_t, ptr addrspace(1) %40, i64 %67
  store i64 %65, ptr addrspace(1) %68, align 8, !tbaa !21
  %69 = cmpxchg ptr addrspace(1) %64, i64 %65, i64 %39 syncscope("one-as") release monotonic, align 8
  %70 = extractvalue { i64, i1 } %69, 1
  br i1 %70, label %76, label %71

71:                                               ; preds = %71, %63
  %72 = phi { i64, i1 } [ %74, %71 ], [ %69, %63 ]
  %73 = extractvalue { i64, i1 } %72, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %73, ptr addrspace(1) %68, align 8, !tbaa !21
  %74 = cmpxchg ptr addrspace(1) %64, i64 %73, i64 %39 syncscope("one-as") release monotonic, align 8
  %75 = extractvalue { i64, i1 } %74, 1
  br i1 %75, label %76, label %71

76:                                               ; preds = %71, %63
  %77 = getelementptr inbounds nuw i8, ptr addrspace(1) %13, i64 16
  %78 = load i64, ptr addrspace(1) %77, align 8
  tail call void @__ockl_hsa_signal_add(i64 %78, i64 noundef 1, i32 noundef 3) #15
  br label %79

79:                                               ; preds = %76, %53
  %80 = getelementptr inbounds nuw i8, ptr addrspace(1) %44, i64 20
  br label %81

81:                                               ; preds = %89, %79
  br i1 %14, label %82, label %85

82:                                               ; preds = %81
  %83 = load atomic i32, ptr addrspace(1) %80 syncscope("one-as") acquire, align 4
  %84 = and i32 %83, 1
  br label %85

85:                                               ; preds = %82, %81
  %86 = phi i32 [ %84, %82 ], [ 1, %81 ]
  %87 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %86)
  %88 = icmp eq i32 %87, 0
  br i1 %88, label %90, label %89

89:                                               ; preds = %85
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  br label %81

90:                                               ; preds = %85
  %91 = load i64, ptr addrspace(1) %55, align 8, !tbaa !9
  %92 = load i64, ptr addrspace(1) %56, align 8, !tbaa !9
  br i1 %14, label %93, label %111

93:                                               ; preds = %90
  %94 = load i64, ptr addrspace(1) %41, align 8, !tbaa !15
  %95 = add i64 %94, 1
  %96 = add i64 %95, %39
  %97 = icmp eq i64 %96, 0
  %98 = select i1 %97, i64 %95, i64 %96
  %99 = getelementptr inbounds nuw i8, ptr addrspace(1) %13, i64 24
  %100 = load atomic i64, ptr addrspace(1) %99 syncscope("one-as") monotonic, align 8
  %101 = load ptr addrspace(1), ptr addrspace(1) %13, align 8, !tbaa !11
  %102 = and i64 %98, %94
  %103 = getelementptr inbounds nuw %struct.header_t, ptr addrspace(1) %101, i64 %102
  store i64 %100, ptr addrspace(1) %103, align 8, !tbaa !21
  %104 = cmpxchg ptr addrspace(1) %99, i64 %100, i64 %98 syncscope("one-as") release monotonic, align 8
  %105 = extractvalue { i64, i1 } %104, 1
  br i1 %105, label %111, label %106

106:                                              ; preds = %106, %93
  %107 = phi { i64, i1 } [ %109, %106 ], [ %104, %93 ]
  %108 = extractvalue { i64, i1 } %107, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %108, ptr addrspace(1) %103, align 8, !tbaa !21
  %109 = cmpxchg ptr addrspace(1) %99, i64 %108, i64 %98 syncscope("one-as") release monotonic, align 8
  %110 = extractvalue { i64, i1 } %109, 1
  br i1 %110, label %111, label %106

111:                                              ; preds = %106, %93, %90
  %112 = insertelement <2 x i64> poison, i64 %91, i64 0
  %113 = insertelement <2 x i64> %112, i64 %92, i64 1
  ret <2 x i64> %113
}

; Function Attrs: alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define linkonce_odr hidden i32 @__ockl_lane_u32() local_unnamed_addr #4 {
  %1 = tail call i32 @llvm.amdgcn.mbcnt.lo(i32 -1, i32 0)
  %2 = tail call i32 @llvm.amdgcn.mbcnt.hi(i32 -1, i32 %1)
  ret i32 %2
}

; Function Attrs: convergent nocallback nofree nounwind willreturn memory(none)
declare i32 @llvm.amdgcn.readfirstlane.i32(i32) #5

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.amdgcn.s.sleep(i32 immarg) #6

; Function Attrs: convergent nocallback nofree nounwind willreturn memory(none)
declare i64 @llvm.amdgcn.readfirstlane.i64(i64) #5

; Function Attrs: convergent nocallback nofree nounwind willreturn memory(none)
declare i64 @llvm.amdgcn.ballot.i64(i1) #5

; Function Attrs: convergent mustprogress norecurse nounwind willreturn
define linkonce_odr hidden void @__ockl_hsa_signal_add(i64 %0, i64 noundef %1, i32 noundef %2) local_unnamed_addr #7 {
  %4 = inttoptr i64 %0 to ptr addrspace(1)
  %5 = getelementptr inbounds nuw i8, ptr addrspace(1) %4, i64 8
  switch i32 %2, label %6 [
    i32 1, label %8
    i32 2, label %8
    i32 3, label %10
    i32 4, label %12
    i32 5, label %14
  ]

6:                                                ; preds = %3
  %7 = atomicrmw add ptr addrspace(1) %5, i64 %1 syncscope("one-as") monotonic, align 8, !amdgpu.no.fine.grained.memory !22, !amdgpu.no.remote.memory !22
  br label %16

8:                                                ; preds = %3, %3
  %9 = atomicrmw add ptr addrspace(1) %5, i64 %1 syncscope("one-as") acquire, align 8, !amdgpu.no.fine.grained.memory !22, !amdgpu.no.remote.memory !22
  br label %16

10:                                               ; preds = %3
  %11 = atomicrmw add ptr addrspace(1) %5, i64 %1 syncscope("one-as") release, align 8, !amdgpu.no.fine.grained.memory !22, !amdgpu.no.remote.memory !22
  br label %16

12:                                               ; preds = %3
  %13 = atomicrmw add ptr addrspace(1) %5, i64 %1 syncscope("one-as") acq_rel, align 8, !amdgpu.no.fine.grained.memory !22, !amdgpu.no.remote.memory !22
  br label %16

14:                                               ; preds = %3
  %15 = atomicrmw add ptr addrspace(1) %5, i64 %1 seq_cst, align 8, !amdgpu.no.fine.grained.memory !22, !amdgpu.no.remote.memory !22
  br label %16

16:                                               ; preds = %14, %12, %10, %8, %6
  %17 = getelementptr inbounds nuw i8, ptr addrspace(1) %4, i64 16
  %18 = load i64, ptr addrspace(1) %17, align 16, !tbaa !23
  %19 = icmp eq i64 %18, 0
  br i1 %19, label %34, label %20

20:                                               ; preds = %16
  %21 = inttoptr i64 %18 to ptr addrspace(1)
  %22 = getelementptr inbounds nuw i8, ptr addrspace(1) %4, i64 24
  %23 = load i32, ptr addrspace(1) %22, align 8, !tbaa !25
  %24 = zext i32 %23 to i64
  store atomic i64 %24, ptr addrspace(1) %21 syncscope("one-as") release, align 8
  %25 = load i32, ptr addrspace(4) @__oclc_ISA_version, align 4, !tbaa !5
  %26 = icmp slt i32 %25, 9000
  %27 = icmp samesign ult i32 %25, 10000
  %28 = icmp samesign ult i32 %25, 11000
  %29 = select i1 %28, i32 8388607, i32 16777215
  %30 = select i1 %27, i32 16777215, i32 %29
  %31 = select i1 %26, i32 255, i32 %30
  %32 = and i32 %31, %23
  %33 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %32)
  tail call void @llvm.amdgcn.s.sendmsg(i32 1, i32 %33)
  br label %34

34:                                               ; preds = %20, %16
  ret void
}

; Function Attrs: nocallback nounwind willreturn
declare void @llvm.amdgcn.s.sendmsg(i32 immarg, i32) #8

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare i32 @llvm.amdgcn.mbcnt.lo(i32, i32) #9

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare i32 @llvm.amdgcn.mbcnt.hi(i32, i32) #9

; Function Attrs: convergent norecurse nounwind
define weak hidden void @__ockl_dm_init_v1(i64 noundef %0, i64 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #1 {
  %5 = tail call i64 @__ockl_get_local_id(i32 noundef 0) #17
  %6 = icmp eq i32 %2, 0
  br i1 %6, label %43, label %7

7:                                                ; preds = %4
  %8 = shl i64 %5, 4
  %9 = and i64 %8, 4294967280
  %10 = add i64 %9, %0
  %11 = inttoptr i64 %10 to ptr addrspace(1)
  store <4 x i32> zeroinitializer, ptr addrspace(1) %11, align 16, !tbaa !26
  %12 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 4096
  store <4 x i32> zeroinitializer, ptr addrspace(1) %12, align 16, !tbaa !26
  %13 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 8192
  store <4 x i32> zeroinitializer, ptr addrspace(1) %13, align 16, !tbaa !26
  %14 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 12288
  store <4 x i32> zeroinitializer, ptr addrspace(1) %14, align 16, !tbaa !26
  %15 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 16384
  store <4 x i32> zeroinitializer, ptr addrspace(1) %15, align 16, !tbaa !26
  %16 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 20480
  store <4 x i32> zeroinitializer, ptr addrspace(1) %16, align 16, !tbaa !26
  %17 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 24576
  store <4 x i32> zeroinitializer, ptr addrspace(1) %17, align 16, !tbaa !26
  %18 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 28672
  store <4 x i32> zeroinitializer, ptr addrspace(1) %18, align 16, !tbaa !26
  %19 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 32768
  store <4 x i32> zeroinitializer, ptr addrspace(1) %19, align 16, !tbaa !26
  %20 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 36864
  store <4 x i32> zeroinitializer, ptr addrspace(1) %20, align 16, !tbaa !26
  %21 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 40960
  store <4 x i32> zeroinitializer, ptr addrspace(1) %21, align 16, !tbaa !26
  %22 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 45056
  store <4 x i32> zeroinitializer, ptr addrspace(1) %22, align 16, !tbaa !26
  %23 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 49152
  store <4 x i32> zeroinitializer, ptr addrspace(1) %23, align 16, !tbaa !26
  %24 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 53248
  store <4 x i32> zeroinitializer, ptr addrspace(1) %24, align 16, !tbaa !26
  %25 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 57344
  store <4 x i32> zeroinitializer, ptr addrspace(1) %25, align 16, !tbaa !26
  %26 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 61440
  store <4 x i32> zeroinitializer, ptr addrspace(1) %26, align 16, !tbaa !26
  %27 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 65536
  store <4 x i32> zeroinitializer, ptr addrspace(1) %27, align 16, !tbaa !26
  %28 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 69632
  store <4 x i32> zeroinitializer, ptr addrspace(1) %28, align 16, !tbaa !26
  %29 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 73728
  store <4 x i32> zeroinitializer, ptr addrspace(1) %29, align 16, !tbaa !26
  %30 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 77824
  store <4 x i32> zeroinitializer, ptr addrspace(1) %30, align 16, !tbaa !26
  %31 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 81920
  store <4 x i32> zeroinitializer, ptr addrspace(1) %31, align 16, !tbaa !26
  %32 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 86016
  store <4 x i32> zeroinitializer, ptr addrspace(1) %32, align 16, !tbaa !26
  %33 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 90112
  store <4 x i32> zeroinitializer, ptr addrspace(1) %33, align 16, !tbaa !26
  %34 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 94208
  store <4 x i32> zeroinitializer, ptr addrspace(1) %34, align 16, !tbaa !26
  %35 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 98304
  store <4 x i32> zeroinitializer, ptr addrspace(1) %35, align 16, !tbaa !26
  %36 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 102400
  store <4 x i32> zeroinitializer, ptr addrspace(1) %36, align 16, !tbaa !26
  %37 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 106496
  store <4 x i32> zeroinitializer, ptr addrspace(1) %37, align 16, !tbaa !26
  %38 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 110592
  store <4 x i32> zeroinitializer, ptr addrspace(1) %38, align 16, !tbaa !26
  %39 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 114688
  store <4 x i32> zeroinitializer, ptr addrspace(1) %39, align 16, !tbaa !26
  %40 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 118784
  store <4 x i32> zeroinitializer, ptr addrspace(1) %40, align 16, !tbaa !26
  %41 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 122880
  store <4 x i32> zeroinitializer, ptr addrspace(1) %41, align 16, !tbaa !26
  %42 = getelementptr inbounds nuw i8, ptr addrspace(1) %11, i64 126976
  store <4 x i32> zeroinitializer, ptr addrspace(1) %42, align 16, !tbaa !26
  br label %43

43:                                               ; preds = %7, %4
  fence syncscope("agent") release, !mmra !27
  tail call void @llvm.amdgcn.s.barrier()
  %44 = and i64 %5, 4294967295
  %45 = icmp eq i64 %44, 0
  br i1 %45, label %46, label %54

46:                                               ; preds = %43
  %47 = inttoptr i64 %0 to ptr addrspace(1)
  %48 = getelementptr inbounds nuw i8, ptr addrspace(1) %47, i64 108544
  store atomic i64 %1, ptr addrspace(1) %48 syncscope("agent-one-as") monotonic, align 8
  %49 = zext i32 %3 to i64
  %50 = shl nuw nsw i64 %49, 21
  %51 = add i64 %50, %1
  %52 = getelementptr inbounds nuw i8, ptr addrspace(1) %47, i64 108552
  store i64 %51, ptr addrspace(1) %52, align 8, !tbaa !28
  %53 = getelementptr inbounds nuw i8, ptr addrspace(1) %47, i64 108560
  store i64 %1, ptr addrspace(1) %53, align 8, !tbaa !30
  br label %54

54:                                               ; preds = %46, %43
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define linkonce_odr hidden range(i64 0, 1024) i64 @__ockl_get_local_id(i32 noundef %0) local_unnamed_addr #10 {
  switch i32 %0, label %8 [
    i32 0, label %2
    i32 1, label %4
    i32 2, label %6
  ]

2:                                                ; preds = %1
  %3 = tail call i32 @llvm.amdgcn.workitem.id.x()
  br label %8

4:                                                ; preds = %1
  %5 = tail call i32 @llvm.amdgcn.workitem.id.y()
  br label %8

6:                                                ; preds = %1
  %7 = tail call i32 @llvm.amdgcn.workitem.id.z()
  br label %8

8:                                                ; preds = %6, %4, %2, %1
  %9 = phi i32 [ %3, %2 ], [ %5, %4 ], [ %7, %6 ], [ 0, %1 ]
  %10 = zext nneg i32 %9 to i64
  ret i64 %10
}

; Function Attrs: convergent nocallback nofree nounwind willreturn
declare void @llvm.amdgcn.s.barrier() #11

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef range(i32 0, 1024) i32 @llvm.amdgcn.workitem.id.x() #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef range(i32 0, 1024) i32 @llvm.amdgcn.workitem.id.y() #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef range(i32 0, 1024) i32 @llvm.amdgcn.workitem.id.z() #3

; Function Attrs: cold convergent norecurse nounwind optsize
define weak hidden void @__ockl_dm_trim(ptr noundef %0) local_unnamed_addr #12 {
  %2 = addrspacecast ptr %0 to ptr addrspace(3)
  %3 = load i8, ptr addrspace(4) @__oclc_wavefrontsize64, align 1, !tbaa !31, !range !33, !noundef !22
  %4 = trunc nuw i8 %3 to i1
  %5 = select i1 %4, i32 128, i32 64
  %6 = getelementptr inbounds nuw i32, ptr addrspace(3) %2, i32 %5
  %7 = load i32, ptr addrspace(4) @__oclc_ABI_version, align 4, !tbaa !5
  %8 = icmp slt i32 %7, 500
  br i1 %8, label %14, label %9

9:                                                ; preds = %1
  %10 = tail call ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %11 = getelementptr inbounds nuw i8, ptr addrspace(4) %10, i64 96
  %12 = load i64, ptr addrspace(4) %11, align 8, !tbaa !9
  %13 = inttoptr i64 %12 to ptr addrspace(1)
  br label %14

14:                                               ; preds = %9, %1
  %15 = phi ptr addrspace(1) [ %13, %9 ], [ @get_heap_ptr.heap, %1 ]
  %16 = getelementptr inbounds nuw i8, ptr addrspace(1) %15, i64 108560
  %17 = load i64, ptr addrspace(1) %16, align 8, !tbaa !30
  %18 = getelementptr inbounds nuw i8, ptr addrspace(1) %15, i64 108552
  %19 = load i64, ptr addrspace(1) %18, align 8, !tbaa !28
  %20 = tail call i32 @__ockl_lane_u32() #15
  %21 = icmp eq i32 %20, 0
  %22 = getelementptr inbounds nuw i8, ptr addrspace(1) %15, i64 2048
  %23 = select i1 %4, i32 64, i32 32
  %24 = select i1 %4, i32 -64, i32 -32
  %25 = getelementptr inbounds nuw i8, ptr addrspace(1) %15, i64 10240
  %26 = getelementptr i32, ptr addrspace(3) %2, i32 %20
  %27 = getelementptr i32, ptr addrspace(3) %6, i32 %20
  br label %29

28:                                               ; preds = %264
  ret void

29:                                               ; preds = %264, %14
  %30 = phi i32 [ 0, %14 ], [ %265, %264 ]
  br i1 %21, label %31, label %35

31:                                               ; preds = %29
  %32 = zext nneg i32 %30 to i64
  %33 = getelementptr inbounds nuw %struct.start_s, ptr addrspace(1) %22, i64 %32
  %34 = load atomic i32, ptr addrspace(1) %33 syncscope("agent-one-as") monotonic, align 8
  br label %35

35:                                               ; preds = %31, %29
  %36 = phi i32 [ %34, %31 ], [ 0, %29 ]
  %37 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %36)
  %38 = icmp eq i32 %37, 0
  br i1 %38, label %264, label %39

39:                                               ; preds = %35
  %40 = add i32 %37, -1
  %41 = and i32 %40, %24
  %42 = zext nneg i32 %30 to i64
  %43 = getelementptr inbounds nuw [256 x %struct.sdata_s], ptr addrspace(1) %25, i64 %42
  br label %44

44:                                               ; preds = %222, %39
  %45 = phi i32 [ 0, %39 ], [ %224, %222 ]
  %46 = phi i32 [ 0, %39 ], [ %219, %222 ]
  %47 = phi i32 [ %41, %39 ], [ %157, %222 ]
  %48 = phi i32 [ 0, %39 ], [ %223, %222 ]
  %49 = phi i32 [ 0, %39 ], [ %101, %222 ]
  %50 = icmp ult i32 %49, %37
  %51 = icmp ult i32 %45, %23
  %52 = select i1 %50, i1 %51, i1 false
  br i1 %52, label %53, label %99

53:                                               ; preds = %89, %44
  %54 = phi i32 [ %95, %89 ], [ %49, %44 ]
  %55 = phi i32 [ %94, %89 ], [ %45, %44 ]
  %56 = add i32 %54, %20
  %57 = icmp ult i32 %56, %37
  br i1 %57, label %58, label %89

58:                                               ; preds = %53
  %59 = icmp ugt i32 %56, 255
  br i1 %59, label %60, label %68

60:                                               ; preds = %58
  %61 = and i32 %56, 255
  %62 = add i32 %56, -256
  %63 = lshr i32 %62, 8
  %64 = zext nneg i32 %63 to i64
  %65 = getelementptr inbounds nuw %struct.sdata_s, ptr addrspace(1) %43, i64 %64
  %66 = load atomic i64, ptr addrspace(1) %65 syncscope("agent-one-as") monotonic, align 8
  %67 = inttoptr i64 %66 to ptr addrspace(1)
  br label %68

68:                                               ; preds = %60, %58
  %69 = phi i32 [ %61, %60 ], [ %56, %58 ]
  %70 = phi ptr addrspace(1) [ %67, %60 ], [ %43, %58 ]
  %71 = zext nneg i32 %69 to i64
  %72 = getelementptr inbounds nuw %struct.sdata_s, ptr addrspace(1) %70, i64 %71
  %73 = getelementptr inbounds nuw i8, ptr addrspace(1) %72, i64 16
  %74 = load atomic i32, ptr addrspace(1) %73 syncscope("agent-one-as") monotonic, align 8
  %75 = getelementptr inbounds nuw i8, ptr addrspace(1) %72, i64 8
  %76 = load atomic i64, ptr addrspace(1) %75 syncscope("agent-one-as") monotonic, align 8
  %77 = icmp eq i32 %74, 0
  %78 = icmp ne i64 %76, 0
  %79 = icmp ult i64 %76, %17
  %80 = icmp uge i64 %76, %19
  %81 = or i1 %79, %80
  %82 = and i1 %78, %81
  %83 = select i1 %77, i1 %82, i1 false
  br i1 %83, label %84, label %89

84:                                               ; preds = %68
  %85 = tail call i64 @__ockl_devmem_request(i64 noundef %76, i64 noundef 0) #15
  store atomic i64 0, ptr addrspace(1) %75 syncscope("agent-one-as") monotonic, align 8
  store atomic i32 0, ptr addrspace(1) %73 syncscope("agent-one-as") monotonic, align 8
  %86 = tail call i32 @__ockl_activelane_u32() #15
  %87 = getelementptr i32, ptr addrspace(3) %2, i32 %55
  %88 = getelementptr i32, ptr addrspace(3) %87, i32 %86
  store i32 %56, ptr addrspace(3) %88, align 4, !tbaa !5
  br label %89

89:                                               ; preds = %84, %68, %53
  %90 = phi i1 [ false, %53 ], [ true, %84 ], [ false, %68 ]
  %91 = tail call i64 @llvm.amdgcn.ballot.i64(i1 %90)
  %92 = tail call range(i64 0, 65) i64 @llvm.ctpop.i64(i64 %91)
  %93 = trunc nuw nsw i64 %92 to i32
  %94 = add nuw nsw i32 %55, %93
  %95 = add i32 %54, %23
  %96 = icmp ult i32 %95, %37
  %97 = icmp ult i32 %94, %23
  %98 = select i1 %96, i1 %97, i1 false
  br i1 %98, label %53, label %99

99:                                               ; preds = %89, %44
  %100 = phi i32 [ %45, %44 ], [ %94, %89 ]
  %101 = phi i32 [ %49, %44 ], [ %95, %89 ]
  %102 = phi i1 [ %50, %44 ], [ %96, %89 ]
  %103 = icmp eq i32 %100, 0
  br i1 %103, label %229, label %104

104:                                              ; preds = %99
  %105 = icmp ult i32 %47, %37
  %106 = icmp ult i32 %48, %23
  %107 = select i1 %105, i1 %106, i1 false
  br i1 %107, label %108, label %156

108:                                              ; preds = %145, %104
  %109 = phi i32 [ %151, %145 ], [ %48, %104 ]
  %110 = phi i32 [ %152, %145 ], [ %47, %104 ]
  %111 = add i32 %110, %20
  %112 = icmp ult i32 %111, %37
  br i1 %112, label %113, label %145

113:                                              ; preds = %108
  %114 = icmp ugt i32 %111, 255
  br i1 %114, label %115, label %123

115:                                              ; preds = %113
  %116 = and i32 %111, 255
  %117 = add i32 %111, -256
  %118 = lshr i32 %117, 8
  %119 = zext nneg i32 %118 to i64
  %120 = getelementptr inbounds nuw %struct.sdata_s, ptr addrspace(1) %43, i64 %119
  %121 = load atomic i64, ptr addrspace(1) %120 syncscope("agent-one-as") monotonic, align 8
  %122 = inttoptr i64 %121 to ptr addrspace(1)
  br label %123

123:                                              ; preds = %115, %113
  %124 = phi i32 [ %116, %115 ], [ %111, %113 ]
  %125 = phi ptr addrspace(1) [ %122, %115 ], [ %43, %113 ]
  %126 = zext nneg i32 %124 to i64
  %127 = getelementptr inbounds nuw %struct.sdata_s, ptr addrspace(1) %125, i64 %126
  %128 = getelementptr inbounds nuw i8, ptr addrspace(1) %127, i64 8
  %129 = load atomic i64, ptr addrspace(1) %128 syncscope("agent-one-as") monotonic, align 8
  %130 = getelementptr inbounds nuw i8, ptr addrspace(1) %127, i64 16
  %131 = load atomic i32, ptr addrspace(1) %130 syncscope("agent-one-as") monotonic, align 8
  %132 = icmp ne i32 %131, 0
  %133 = icmp uge i64 %129, %17
  %134 = icmp ult i64 %129, %19
  %135 = and i1 %133, %134
  %136 = select i1 %132, i1 true, i1 %135
  br i1 %136, label %137, label %141

137:                                              ; preds = %123
  %138 = tail call i32 @__ockl_activelane_u32() #15
  %139 = getelementptr i32, ptr addrspace(3) %6, i32 %109
  %140 = getelementptr i32, ptr addrspace(3) %139, i32 %138
  store i32 %111, ptr addrspace(3) %140, align 4, !tbaa !5
  br label %145

141:                                              ; preds = %123
  %142 = icmp eq i64 %129, 0
  br i1 %142, label %145, label %143

143:                                              ; preds = %141
  %144 = tail call i64 @__ockl_devmem_request(i64 noundef %129, i64 noundef 0) #15
  store atomic i64 0, ptr addrspace(1) %128 syncscope("agent-one-as") monotonic, align 8
  store atomic i32 0, ptr addrspace(1) %130 syncscope("agent-one-as") monotonic, align 8
  br label %145

145:                                              ; preds = %143, %141, %137, %108
  %146 = phi i1 [ false, %108 ], [ false, %141 ], [ false, %143 ], [ true, %137 ]
  %147 = tail call i64 @llvm.amdgcn.ballot.i64(i1 %146)
  %148 = tail call range(i64 0, 65) i64 @llvm.ctpop.i64(i64 %147)
  %149 = trunc nuw nsw i64 %148 to i32
  %150 = getelementptr inbounds nuw i32, ptr addrspace(3) %6, i32 %109
  tail call fastcc void @reverse_la(ptr addrspace(3) noundef nonnull %150, i32 noundef %20, i32 noundef %149) #15
  %151 = add nuw nsw i32 %109, %149
  %152 = sub i32 %110, %23
  %153 = icmp ult i32 %152, %37
  %154 = icmp ult i32 %151, %23
  %155 = select i1 %153, i1 %154, i1 false
  br i1 %155, label %108, label %156

156:                                              ; preds = %145, %104
  %157 = phi i32 [ %47, %104 ], [ %152, %145 ]
  %158 = phi i32 [ %48, %104 ], [ %151, %145 ]
  %159 = icmp eq i32 %158, 0
  br i1 %159, label %229, label %160

160:                                              ; preds = %156
  %161 = tail call i32 @llvm.umin.i32(i32 %100, i32 %158)
  %162 = tail call i32 @llvm.umin.i32(i32 %23, i32 %161)
  %163 = icmp ult i32 %20, %162
  br i1 %163, label %164, label %168

164:                                              ; preds = %160
  %165 = load i32, ptr addrspace(3) %26, align 4, !tbaa !5
  %166 = load i32, ptr addrspace(3) %27, align 4, !tbaa !5
  %167 = icmp ult i32 %165, %166
  br label %168

168:                                              ; preds = %164, %160
  %169 = phi i1 [ false, %160 ], [ %167, %164 ]
  br i1 %169, label %170, label %209

170:                                              ; preds = %168
  %171 = load i32, ptr addrspace(3) %26, align 4, !tbaa !5
  %172 = icmp ugt i32 %171, 255
  br i1 %172, label %173, label %181

173:                                              ; preds = %170
  %174 = and i32 %171, 255
  %175 = add i32 %171, -256
  %176 = lshr i32 %175, 8
  %177 = zext nneg i32 %176 to i64
  %178 = getelementptr inbounds nuw %struct.sdata_s, ptr addrspace(1) %43, i64 %177
  %179 = load atomic i64, ptr addrspace(1) %178 syncscope("agent-one-as") monotonic, align 8
  %180 = inttoptr i64 %179 to ptr addrspace(1)
  br label %181

181:                                              ; preds = %173, %170
  %182 = phi i32 [ %174, %173 ], [ %171, %170 ]
  %183 = phi ptr addrspace(1) [ %180, %173 ], [ %43, %170 ]
  %184 = zext nneg i32 %182 to i64
  %185 = getelementptr inbounds nuw %struct.sdata_s, ptr addrspace(1) %183, i64 %184
  %186 = load i32, ptr addrspace(3) %27, align 4, !tbaa !5
  %187 = icmp ugt i32 %186, 255
  br i1 %187, label %188, label %196

188:                                              ; preds = %181
  %189 = and i32 %186, 255
  %190 = add i32 %186, -256
  %191 = lshr i32 %190, 8
  %192 = zext nneg i32 %191 to i64
  %193 = getelementptr inbounds nuw %struct.sdata_s, ptr addrspace(1) %43, i64 %192
  %194 = load atomic i64, ptr addrspace(1) %193 syncscope("agent-one-as") monotonic, align 8
  %195 = inttoptr i64 %194 to ptr addrspace(1)
  br label %196

196:                                              ; preds = %188, %181
  %197 = phi i32 [ %189, %188 ], [ %186, %181 ]
  %198 = phi ptr addrspace(1) [ %195, %188 ], [ %43, %181 ]
  %199 = zext nneg i32 %197 to i64
  %200 = getelementptr inbounds nuw %struct.sdata_s, ptr addrspace(1) %198, i64 %199
  %201 = getelementptr inbounds nuw i8, ptr addrspace(1) %200, i64 8
  %202 = load atomic i64, ptr addrspace(1) %201 syncscope("agent-one-as") monotonic, align 8
  %203 = inttoptr i64 %202 to ptr addrspace(1)
  %204 = getelementptr inbounds nuw i8, ptr addrspace(1) %203, i64 4
  store i32 %171, ptr addrspace(1) %204, align 4, !tbaa !34
  %205 = getelementptr inbounds nuw i8, ptr addrspace(1) %185, i64 8
  store atomic i64 %202, ptr addrspace(1) %205 syncscope("agent-one-as") monotonic, align 8
  %206 = getelementptr inbounds nuw i8, ptr addrspace(1) %185, i64 16
  %207 = getelementptr inbounds nuw i8, ptr addrspace(1) %200, i64 16
  %208 = load atomic i32, ptr addrspace(1) %207 syncscope("agent-one-as") monotonic, align 8
  store atomic i32 %208, ptr addrspace(1) %206 syncscope("agent-one-as") monotonic, align 8
  store atomic i64 0, ptr addrspace(1) %201 syncscope("agent-one-as") monotonic, align 8
  store atomic i32 0, ptr addrspace(1) %207 syncscope("agent-one-as") monotonic, align 8
  br label %209

209:                                              ; preds = %196, %168
  %210 = tail call i64 @llvm.amdgcn.ballot.i64(i1 %169)
  %211 = tail call range(i64 0, 65) i64 @llvm.ctpop.i64(i64 %210)
  %212 = trunc nuw nsw i64 %211 to i32
  %213 = icmp eq i64 %210, 0
  br i1 %213, label %218, label %214

214:                                              ; preds = %209
  %215 = getelementptr i32, ptr addrspace(3) %2, i32 %212
  %216 = getelementptr i8, ptr addrspace(3) %215, i32 -4
  %217 = load i32, ptr addrspace(3) %216, align 4, !tbaa !5
  br label %218

218:                                              ; preds = %214, %209
  %219 = phi i32 [ %217, %214 ], [ %46, %209 ]
  %220 = icmp eq i32 %162, %212
  %221 = and i1 %102, %220
  br i1 %221, label %222, label %229

222:                                              ; preds = %218
  %223 = sub i32 %158, %162
  %224 = sub i32 %100, %162
  %225 = getelementptr i32, ptr addrspace(3) %27, i32 %162
  %226 = getelementptr i32, ptr addrspace(3) %26, i32 %162
  %227 = load i32, ptr addrspace(3) %226, align 4, !tbaa !5
  store i32 %227, ptr addrspace(3) %26, align 4, !tbaa !5
  %228 = load i32, ptr addrspace(3) %225, align 4, !tbaa !5
  store i32 %228, ptr addrspace(3) %27, align 4, !tbaa !5
  br label %44

229:                                              ; preds = %218, %156, %99
  %230 = phi i32 [ %46, %99 ], [ %46, %156 ], [ %219, %218 ]
  %231 = and i32 %230, %24
  br label %232

232:                                              ; preds = %254, %229
  %233 = phi i32 [ %231, %229 ], [ %259, %254 ]
  %234 = add i32 %233, %20
  %235 = icmp ult i32 %234, %37
  br i1 %235, label %236, label %254

236:                                              ; preds = %232
  %237 = icmp ugt i32 %234, 255
  br i1 %237, label %238, label %246

238:                                              ; preds = %236
  %239 = and i32 %234, 255
  %240 = add i32 %234, -256
  %241 = lshr i32 %240, 8
  %242 = zext nneg i32 %241 to i64
  %243 = getelementptr inbounds nuw %struct.sdata_s, ptr addrspace(1) %43, i64 %242
  %244 = load atomic i64, ptr addrspace(1) %243 syncscope("agent-one-as") monotonic, align 8
  %245 = inttoptr i64 %244 to ptr addrspace(1)
  br label %246

246:                                              ; preds = %238, %236
  %247 = phi i32 [ %239, %238 ], [ %234, %236 ]
  %248 = phi ptr addrspace(1) [ %245, %238 ], [ %43, %236 ]
  %249 = zext nneg i32 %247 to i64
  %250 = getelementptr inbounds nuw %struct.sdata_s, ptr addrspace(1) %248, i64 %249
  %251 = getelementptr inbounds nuw i8, ptr addrspace(1) %250, i64 8
  %252 = load atomic i64, ptr addrspace(1) %251 syncscope("agent-one-as") monotonic, align 8
  %253 = icmp ne i64 %252, 0
  br label %254

254:                                              ; preds = %246, %232
  %255 = phi i1 [ %253, %246 ], [ false, %232 ]
  %256 = tail call i64 @llvm.amdgcn.ballot.i64(i1 %255)
  %257 = tail call range(i64 0, 65) i64 @llvm.ctpop.i64(i64 %256)
  %258 = trunc nuw nsw i64 %257 to i32
  %259 = add i32 %233, %258
  %260 = icmp eq i32 %23, %258
  br i1 %260, label %232, label %261

261:                                              ; preds = %254
  br i1 %21, label %262, label %264

262:                                              ; preds = %261
  %263 = getelementptr inbounds nuw %struct.start_s, ptr addrspace(1) %22, i64 %42
  store atomic i32 %259, ptr addrspace(1) %263 syncscope("agent-one-as") monotonic, align 8
  br label %264

264:                                              ; preds = %262, %261, %35
  %265 = add nuw nsw i32 %30, 1
  %266 = icmp eq i32 %265, 16
  br i1 %266, label %28, label %29
}

; Function Attrs: convergent mustprogress nofree norecurse nounwind willreturn memory(none)
define linkonce_odr hidden i32 @__ockl_activelane_u32() local_unnamed_addr #13 {
  %1 = tail call i64 @llvm.amdgcn.ballot.i64(i1 true)
  %2 = lshr i64 %1, 32
  %3 = trunc nuw i64 %2 to i32
  %4 = tail call i32 @llvm.amdgcn.ballot.i32(i1 true)
  %5 = tail call i32 @llvm.amdgcn.mbcnt.lo(i32 %4, i32 0)
  %6 = tail call i32 @llvm.amdgcn.mbcnt.hi(i32 %3, i32 %5)
  ret i32 %6
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.ctpop.i64(i64) #3

; Function Attrs: convergent mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite)
define internal fastcc void @reverse_la(ptr addrspace(3) noundef captures(none) %0, i32 noundef %1, i32 noundef range(i32 0, 65) %2) unnamed_addr #14 {
  %4 = icmp ult i32 %1, %2
  br i1 %4, label %5, label %12

5:                                                ; preds = %3
  %6 = getelementptr inbounds nuw i32, ptr addrspace(3) %0, i32 %1
  %7 = xor i32 %1, -1
  %8 = add nsw i32 %2, %7
  %9 = shl nsw i32 %8, 2
  %10 = load i32, ptr addrspace(3) %6, align 4, !tbaa !5
  %11 = tail call i32 @llvm.amdgcn.ds.bpermute(i32 %9, i32 %10)
  store i32 %11, ptr addrspace(3) %6, align 4, !tbaa !5
  br label %12

12:                                               ; preds = %5, %3
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #3

; Function Attrs: convergent nocallback nofree nounwind willreturn memory(none)
declare i32 @llvm.amdgcn.ds.bpermute(i32, i32) #5

; Function Attrs: convergent nocallback nofree nounwind willreturn memory(none)
declare i32 @llvm.amdgcn.ballot.i32(i1) #5

; Function Attrs: convergent norecurse nounwind
define linkonce_odr hidden i64 @__ockl_printf_begin(i64 noundef %0) #1 {
  %2 = tail call <2 x i64> @__ockl_hostcall_preview(i32 noundef 2, i64 noundef 33, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0) #15
  %3 = extractelement <2 x i64> %2, i64 0
  ret i64 %3
}

; Function Attrs: convergent norecurse nounwind
define linkonce_odr hidden i64 @__ockl_printf_append_args(i64 noundef %0, i32 noundef %1, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8, i32 noundef %9) #1 {
  %11 = icmp eq i32 %9, 0
  %12 = or i64 %0, 2
  %13 = select i1 %11, i64 %0, i64 %12
  %14 = and i64 %13, -225
  %15 = zext i32 %1 to i64
  %16 = shl nuw nsw i64 %15, 5
  %17 = or i64 %14, %16
  %18 = tail call <2 x i64> @__ockl_hostcall_preview(i32 noundef 2, i64 noundef %17, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8) #15
  %19 = extractelement <2 x i64> %18, i64 0
  ret i64 %19
}

; Function Attrs: convergent norecurse nounwind
define linkonce_odr hidden i64 @__ockl_printf_append_string_n(i64 noundef %0, ptr noundef readonly %1, i64 noundef %2, i32 noundef %3) #1 {
  %5 = icmp eq i32 %3, 0
  %6 = or i64 %0, 2
  %7 = select i1 %5, i64 %0, i64 %6
  %8 = icmp eq ptr %1, null
  br i1 %8, label %9, label %13

9:                                                ; preds = %4
  %10 = and i64 %7, -225
  %11 = or disjoint i64 %10, 32
  %12 = tail call <2 x i64> @__ockl_hostcall_preview(i32 noundef 2, i64 noundef %11, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0) #15
  br label %452

13:                                               ; preds = %4
  %14 = and i64 %7, 2
  %15 = and i64 %7, -3
  %16 = insertelement <2 x i64> <i64 poison, i64 0>, i64 %15, i64 0
  br label %17

17:                                               ; preds = %440, %13
  %18 = phi i64 [ %2, %13 ], [ %449, %440 ]
  %19 = phi ptr [ %1, %13 ], [ %450, %440 ]
  %20 = phi <2 x i64> [ %16, %13 ], [ %448, %440 ]
  %21 = icmp ugt i64 %18, 56
  %22 = extractelement <2 x i64> %20, i64 0
  %23 = tail call i64 @llvm.umin.i64(i64 %18, i64 56)
  %24 = trunc nuw nsw i64 %23 to i32
  %25 = select i1 %21, i64 0, i64 %14
  %26 = icmp ugt i64 %18, 7
  br i1 %26, label %29, label %27

27:                                               ; preds = %17
  %28 = icmp eq i64 %18, 0
  br i1 %28, label %82, label %69

29:                                               ; preds = %17
  %30 = load i8, ptr %19, align 1, !tbaa !26
  %31 = zext i8 %30 to i64
  %32 = getelementptr inbounds nuw i8, ptr %19, i64 1
  %33 = load i8, ptr %32, align 1, !tbaa !26
  %34 = zext i8 %33 to i64
  %35 = shl nuw nsw i64 %34, 8
  %36 = or disjoint i64 %35, %31
  %37 = getelementptr inbounds nuw i8, ptr %19, i64 2
  %38 = load i8, ptr %37, align 1, !tbaa !26
  %39 = zext i8 %38 to i64
  %40 = shl nuw nsw i64 %39, 16
  %41 = or disjoint i64 %36, %40
  %42 = getelementptr inbounds nuw i8, ptr %19, i64 3
  %43 = load i8, ptr %42, align 1, !tbaa !26
  %44 = zext i8 %43 to i64
  %45 = shl nuw nsw i64 %44, 24
  %46 = or disjoint i64 %41, %45
  %47 = getelementptr inbounds nuw i8, ptr %19, i64 4
  %48 = load i8, ptr %47, align 1, !tbaa !26
  %49 = zext i8 %48 to i64
  %50 = shl nuw nsw i64 %49, 32
  %51 = or disjoint i64 %46, %50
  %52 = getelementptr inbounds nuw i8, ptr %19, i64 5
  %53 = load i8, ptr %52, align 1, !tbaa !26
  %54 = zext i8 %53 to i64
  %55 = shl nuw nsw i64 %54, 40
  %56 = or i64 %51, %55
  %57 = getelementptr inbounds nuw i8, ptr %19, i64 6
  %58 = load i8, ptr %57, align 1, !tbaa !26
  %59 = zext i8 %58 to i64
  %60 = shl nuw nsw i64 %59, 48
  %61 = or i64 %56, %60
  %62 = getelementptr inbounds nuw i8, ptr %19, i64 7
  %63 = load i8, ptr %62, align 1, !tbaa !26
  %64 = zext i8 %63 to i64
  %65 = shl nuw i64 %64, 56
  %66 = or i64 %61, %65
  %67 = add nsw i32 %24, -8
  %68 = getelementptr inbounds nuw i8, ptr %19, i64 8
  br label %82

69:                                               ; preds = %69, %27
  %70 = phi i32 [ %80, %69 ], [ 0, %27 ]
  %71 = phi i64 [ %79, %69 ], [ 0, %27 ]
  %72 = zext nneg i32 %70 to i64
  %73 = getelementptr inbounds nuw i8, ptr %19, i64 %72
  %74 = load i8, ptr %73, align 1, !tbaa !26
  %75 = zext i8 %74 to i64
  %76 = shl i32 %70, 3
  %77 = zext nneg i32 %76 to i64
  %78 = shl nuw i64 %75, %77
  %79 = or i64 %78, %71
  %80 = add nuw nsw i32 %70, 1
  %81 = icmp eq i32 %80, %24
  br i1 %81, label %82, label %69

82:                                               ; preds = %69, %29, %27
  %83 = phi ptr [ %68, %29 ], [ %19, %27 ], [ %19, %69 ]
  %84 = phi i32 [ %67, %29 ], [ 0, %27 ], [ 0, %69 ]
  %85 = phi i64 [ %66, %29 ], [ 0, %27 ], [ %79, %69 ]
  %86 = icmp ugt i32 %84, 7
  br i1 %86, label %89, label %87

87:                                               ; preds = %82
  %88 = icmp eq i32 %84, 0
  br i1 %88, label %142, label %129

89:                                               ; preds = %82
  %90 = load i8, ptr %83, align 1, !tbaa !26
  %91 = zext i8 %90 to i64
  %92 = getelementptr inbounds nuw i8, ptr %83, i64 1
  %93 = load i8, ptr %92, align 1, !tbaa !26
  %94 = zext i8 %93 to i64
  %95 = shl nuw nsw i64 %94, 8
  %96 = or disjoint i64 %95, %91
  %97 = getelementptr inbounds nuw i8, ptr %83, i64 2
  %98 = load i8, ptr %97, align 1, !tbaa !26
  %99 = zext i8 %98 to i64
  %100 = shl nuw nsw i64 %99, 16
  %101 = or disjoint i64 %96, %100
  %102 = getelementptr inbounds nuw i8, ptr %83, i64 3
  %103 = load i8, ptr %102, align 1, !tbaa !26
  %104 = zext i8 %103 to i64
  %105 = shl nuw nsw i64 %104, 24
  %106 = or disjoint i64 %101, %105
  %107 = getelementptr inbounds nuw i8, ptr %83, i64 4
  %108 = load i8, ptr %107, align 1, !tbaa !26
  %109 = zext i8 %108 to i64
  %110 = shl nuw nsw i64 %109, 32
  %111 = or disjoint i64 %106, %110
  %112 = getelementptr inbounds nuw i8, ptr %83, i64 5
  %113 = load i8, ptr %112, align 1, !tbaa !26
  %114 = zext i8 %113 to i64
  %115 = shl nuw nsw i64 %114, 40
  %116 = or i64 %111, %115
  %117 = getelementptr inbounds nuw i8, ptr %83, i64 6
  %118 = load i8, ptr %117, align 1, !tbaa !26
  %119 = zext i8 %118 to i64
  %120 = shl nuw nsw i64 %119, 48
  %121 = or i64 %116, %120
  %122 = getelementptr inbounds nuw i8, ptr %83, i64 7
  %123 = load i8, ptr %122, align 1, !tbaa !26
  %124 = zext i8 %123 to i64
  %125 = shl nuw i64 %124, 56
  %126 = or i64 %121, %125
  %127 = add nsw i32 %84, -8
  %128 = getelementptr inbounds nuw i8, ptr %83, i64 8
  br label %142

129:                                              ; preds = %129, %87
  %130 = phi i32 [ %140, %129 ], [ 0, %87 ]
  %131 = phi i64 [ %139, %129 ], [ 0, %87 ]
  %132 = zext nneg i32 %130 to i64
  %133 = getelementptr inbounds nuw i8, ptr %83, i64 %132
  %134 = load i8, ptr %133, align 1, !tbaa !26
  %135 = zext i8 %134 to i64
  %136 = shl i32 %130, 3
  %137 = zext nneg i32 %136 to i64
  %138 = shl nuw i64 %135, %137
  %139 = or i64 %138, %131
  %140 = add nuw nsw i32 %130, 1
  %141 = icmp eq i32 %140, %84
  br i1 %141, label %142, label %129

142:                                              ; preds = %129, %89, %87
  %143 = phi ptr [ %128, %89 ], [ %83, %87 ], [ %83, %129 ]
  %144 = phi i32 [ %127, %89 ], [ 0, %87 ], [ 0, %129 ]
  %145 = phi i64 [ %126, %89 ], [ 0, %87 ], [ %139, %129 ]
  %146 = icmp ugt i32 %144, 7
  br i1 %146, label %149, label %147

147:                                              ; preds = %142
  %148 = icmp eq i32 %144, 0
  br i1 %148, label %202, label %189

149:                                              ; preds = %142
  %150 = load i8, ptr %143, align 1, !tbaa !26
  %151 = zext i8 %150 to i64
  %152 = getelementptr inbounds nuw i8, ptr %143, i64 1
  %153 = load i8, ptr %152, align 1, !tbaa !26
  %154 = zext i8 %153 to i64
  %155 = shl nuw nsw i64 %154, 8
  %156 = or disjoint i64 %155, %151
  %157 = getelementptr inbounds nuw i8, ptr %143, i64 2
  %158 = load i8, ptr %157, align 1, !tbaa !26
  %159 = zext i8 %158 to i64
  %160 = shl nuw nsw i64 %159, 16
  %161 = or disjoint i64 %156, %160
  %162 = getelementptr inbounds nuw i8, ptr %143, i64 3
  %163 = load i8, ptr %162, align 1, !tbaa !26
  %164 = zext i8 %163 to i64
  %165 = shl nuw nsw i64 %164, 24
  %166 = or disjoint i64 %161, %165
  %167 = getelementptr inbounds nuw i8, ptr %143, i64 4
  %168 = load i8, ptr %167, align 1, !tbaa !26
  %169 = zext i8 %168 to i64
  %170 = shl nuw nsw i64 %169, 32
  %171 = or disjoint i64 %166, %170
  %172 = getelementptr inbounds nuw i8, ptr %143, i64 5
  %173 = load i8, ptr %172, align 1, !tbaa !26
  %174 = zext i8 %173 to i64
  %175 = shl nuw nsw i64 %174, 40
  %176 = or i64 %171, %175
  %177 = getelementptr inbounds nuw i8, ptr %143, i64 6
  %178 = load i8, ptr %177, align 1, !tbaa !26
  %179 = zext i8 %178 to i64
  %180 = shl nuw nsw i64 %179, 48
  %181 = or i64 %176, %180
  %182 = getelementptr inbounds nuw i8, ptr %143, i64 7
  %183 = load i8, ptr %182, align 1, !tbaa !26
  %184 = zext i8 %183 to i64
  %185 = shl nuw i64 %184, 56
  %186 = or i64 %181, %185
  %187 = add nsw i32 %144, -8
  %188 = getelementptr inbounds nuw i8, ptr %143, i64 8
  br label %202

189:                                              ; preds = %189, %147
  %190 = phi i32 [ %200, %189 ], [ 0, %147 ]
  %191 = phi i64 [ %199, %189 ], [ 0, %147 ]
  %192 = zext nneg i32 %190 to i64
  %193 = getelementptr inbounds nuw i8, ptr %143, i64 %192
  %194 = load i8, ptr %193, align 1, !tbaa !26
  %195 = zext i8 %194 to i64
  %196 = shl i32 %190, 3
  %197 = zext nneg i32 %196 to i64
  %198 = shl nuw i64 %195, %197
  %199 = or i64 %198, %191
  %200 = add nuw nsw i32 %190, 1
  %201 = icmp eq i32 %200, %144
  br i1 %201, label %202, label %189

202:                                              ; preds = %189, %149, %147
  %203 = phi ptr [ %188, %149 ], [ %143, %147 ], [ %143, %189 ]
  %204 = phi i32 [ %187, %149 ], [ 0, %147 ], [ 0, %189 ]
  %205 = phi i64 [ %186, %149 ], [ 0, %147 ], [ %199, %189 ]
  %206 = icmp ugt i32 %204, 7
  br i1 %206, label %209, label %207

207:                                              ; preds = %202
  %208 = icmp eq i32 %204, 0
  br i1 %208, label %262, label %249

209:                                              ; preds = %202
  %210 = load i8, ptr %203, align 1, !tbaa !26
  %211 = zext i8 %210 to i64
  %212 = getelementptr inbounds nuw i8, ptr %203, i64 1
  %213 = load i8, ptr %212, align 1, !tbaa !26
  %214 = zext i8 %213 to i64
  %215 = shl nuw nsw i64 %214, 8
  %216 = or disjoint i64 %215, %211
  %217 = getelementptr inbounds nuw i8, ptr %203, i64 2
  %218 = load i8, ptr %217, align 1, !tbaa !26
  %219 = zext i8 %218 to i64
  %220 = shl nuw nsw i64 %219, 16
  %221 = or disjoint i64 %216, %220
  %222 = getelementptr inbounds nuw i8, ptr %203, i64 3
  %223 = load i8, ptr %222, align 1, !tbaa !26
  %224 = zext i8 %223 to i64
  %225 = shl nuw nsw i64 %224, 24
  %226 = or disjoint i64 %221, %225
  %227 = getelementptr inbounds nuw i8, ptr %203, i64 4
  %228 = load i8, ptr %227, align 1, !tbaa !26
  %229 = zext i8 %228 to i64
  %230 = shl nuw nsw i64 %229, 32
  %231 = or disjoint i64 %226, %230
  %232 = getelementptr inbounds nuw i8, ptr %203, i64 5
  %233 = load i8, ptr %232, align 1, !tbaa !26
  %234 = zext i8 %233 to i64
  %235 = shl nuw nsw i64 %234, 40
  %236 = or i64 %231, %235
  %237 = getelementptr inbounds nuw i8, ptr %203, i64 6
  %238 = load i8, ptr %237, align 1, !tbaa !26
  %239 = zext i8 %238 to i64
  %240 = shl nuw nsw i64 %239, 48
  %241 = or i64 %236, %240
  %242 = getelementptr inbounds nuw i8, ptr %203, i64 7
  %243 = load i8, ptr %242, align 1, !tbaa !26
  %244 = zext i8 %243 to i64
  %245 = shl nuw i64 %244, 56
  %246 = or i64 %241, %245
  %247 = add nsw i32 %204, -8
  %248 = getelementptr inbounds nuw i8, ptr %203, i64 8
  br label %262

249:                                              ; preds = %249, %207
  %250 = phi i32 [ %260, %249 ], [ 0, %207 ]
  %251 = phi i64 [ %259, %249 ], [ 0, %207 ]
  %252 = zext nneg i32 %250 to i64
  %253 = getelementptr inbounds nuw i8, ptr %203, i64 %252
  %254 = load i8, ptr %253, align 1, !tbaa !26
  %255 = zext i8 %254 to i64
  %256 = shl i32 %250, 3
  %257 = zext nneg i32 %256 to i64
  %258 = shl nuw i64 %255, %257
  %259 = or i64 %258, %251
  %260 = add nuw nsw i32 %250, 1
  %261 = icmp eq i32 %260, %204
  br i1 %261, label %262, label %249

262:                                              ; preds = %249, %209, %207
  %263 = phi ptr [ %248, %209 ], [ %203, %207 ], [ %203, %249 ]
  %264 = phi i32 [ %247, %209 ], [ 0, %207 ], [ 0, %249 ]
  %265 = phi i64 [ %246, %209 ], [ 0, %207 ], [ %259, %249 ]
  %266 = icmp ugt i32 %264, 7
  br i1 %266, label %269, label %267

267:                                              ; preds = %262
  %268 = icmp eq i32 %264, 0
  br i1 %268, label %322, label %309

269:                                              ; preds = %262
  %270 = load i8, ptr %263, align 1, !tbaa !26
  %271 = zext i8 %270 to i64
  %272 = getelementptr inbounds nuw i8, ptr %263, i64 1
  %273 = load i8, ptr %272, align 1, !tbaa !26
  %274 = zext i8 %273 to i64
  %275 = shl nuw nsw i64 %274, 8
  %276 = or disjoint i64 %275, %271
  %277 = getelementptr inbounds nuw i8, ptr %263, i64 2
  %278 = load i8, ptr %277, align 1, !tbaa !26
  %279 = zext i8 %278 to i64
  %280 = shl nuw nsw i64 %279, 16
  %281 = or disjoint i64 %276, %280
  %282 = getelementptr inbounds nuw i8, ptr %263, i64 3
  %283 = load i8, ptr %282, align 1, !tbaa !26
  %284 = zext i8 %283 to i64
  %285 = shl nuw nsw i64 %284, 24
  %286 = or disjoint i64 %281, %285
  %287 = getelementptr inbounds nuw i8, ptr %263, i64 4
  %288 = load i8, ptr %287, align 1, !tbaa !26
  %289 = zext i8 %288 to i64
  %290 = shl nuw nsw i64 %289, 32
  %291 = or disjoint i64 %286, %290
  %292 = getelementptr inbounds nuw i8, ptr %263, i64 5
  %293 = load i8, ptr %292, align 1, !tbaa !26
  %294 = zext i8 %293 to i64
  %295 = shl nuw nsw i64 %294, 40
  %296 = or i64 %291, %295
  %297 = getelementptr inbounds nuw i8, ptr %263, i64 6
  %298 = load i8, ptr %297, align 1, !tbaa !26
  %299 = zext i8 %298 to i64
  %300 = shl nuw nsw i64 %299, 48
  %301 = or i64 %296, %300
  %302 = getelementptr inbounds nuw i8, ptr %263, i64 7
  %303 = load i8, ptr %302, align 1, !tbaa !26
  %304 = zext i8 %303 to i64
  %305 = shl nuw i64 %304, 56
  %306 = or i64 %301, %305
  %307 = add nsw i32 %264, -8
  %308 = getelementptr inbounds nuw i8, ptr %263, i64 8
  br label %322

309:                                              ; preds = %309, %267
  %310 = phi i32 [ %320, %309 ], [ 0, %267 ]
  %311 = phi i64 [ %319, %309 ], [ 0, %267 ]
  %312 = zext nneg i32 %310 to i64
  %313 = getelementptr inbounds nuw i8, ptr %263, i64 %312
  %314 = load i8, ptr %313, align 1, !tbaa !26
  %315 = zext i8 %314 to i64
  %316 = shl i32 %310, 3
  %317 = zext nneg i32 %316 to i64
  %318 = shl nuw i64 %315, %317
  %319 = or i64 %318, %311
  %320 = add nuw nsw i32 %310, 1
  %321 = icmp eq i32 %320, %264
  br i1 %321, label %322, label %309

322:                                              ; preds = %309, %269, %267
  %323 = phi ptr [ %308, %269 ], [ %263, %267 ], [ %263, %309 ]
  %324 = phi i32 [ %307, %269 ], [ 0, %267 ], [ 0, %309 ]
  %325 = phi i64 [ %306, %269 ], [ 0, %267 ], [ %319, %309 ]
  %326 = icmp ugt i32 %324, 7
  br i1 %326, label %329, label %327

327:                                              ; preds = %322
  %328 = icmp eq i32 %324, 0
  br i1 %328, label %382, label %369

329:                                              ; preds = %322
  %330 = load i8, ptr %323, align 1, !tbaa !26
  %331 = zext i8 %330 to i64
  %332 = getelementptr inbounds nuw i8, ptr %323, i64 1
  %333 = load i8, ptr %332, align 1, !tbaa !26
  %334 = zext i8 %333 to i64
  %335 = shl nuw nsw i64 %334, 8
  %336 = or disjoint i64 %335, %331
  %337 = getelementptr inbounds nuw i8, ptr %323, i64 2
  %338 = load i8, ptr %337, align 1, !tbaa !26
  %339 = zext i8 %338 to i64
  %340 = shl nuw nsw i64 %339, 16
  %341 = or disjoint i64 %336, %340
  %342 = getelementptr inbounds nuw i8, ptr %323, i64 3
  %343 = load i8, ptr %342, align 1, !tbaa !26
  %344 = zext i8 %343 to i64
  %345 = shl nuw nsw i64 %344, 24
  %346 = or disjoint i64 %341, %345
  %347 = getelementptr inbounds nuw i8, ptr %323, i64 4
  %348 = load i8, ptr %347, align 1, !tbaa !26
  %349 = zext i8 %348 to i64
  %350 = shl nuw nsw i64 %349, 32
  %351 = or disjoint i64 %346, %350
  %352 = getelementptr inbounds nuw i8, ptr %323, i64 5
  %353 = load i8, ptr %352, align 1, !tbaa !26
  %354 = zext i8 %353 to i64
  %355 = shl nuw nsw i64 %354, 40
  %356 = or i64 %351, %355
  %357 = getelementptr inbounds nuw i8, ptr %323, i64 6
  %358 = load i8, ptr %357, align 1, !tbaa !26
  %359 = zext i8 %358 to i64
  %360 = shl nuw nsw i64 %359, 48
  %361 = or i64 %356, %360
  %362 = getelementptr inbounds nuw i8, ptr %323, i64 7
  %363 = load i8, ptr %362, align 1, !tbaa !26
  %364 = zext i8 %363 to i64
  %365 = shl nuw i64 %364, 56
  %366 = or i64 %361, %365
  %367 = add nsw i32 %324, -8
  %368 = getelementptr inbounds nuw i8, ptr %323, i64 8
  br label %382

369:                                              ; preds = %369, %327
  %370 = phi i32 [ %380, %369 ], [ 0, %327 ]
  %371 = phi i64 [ %379, %369 ], [ 0, %327 ]
  %372 = zext nneg i32 %370 to i64
  %373 = getelementptr inbounds nuw i8, ptr %323, i64 %372
  %374 = load i8, ptr %373, align 1, !tbaa !26
  %375 = zext i8 %374 to i64
  %376 = shl i32 %370, 3
  %377 = zext nneg i32 %376 to i64
  %378 = shl nuw i64 %375, %377
  %379 = or i64 %378, %371
  %380 = add nuw nsw i32 %370, 1
  %381 = icmp eq i32 %380, %324
  br i1 %381, label %382, label %369

382:                                              ; preds = %369, %329, %327
  %383 = phi ptr [ %368, %329 ], [ %323, %327 ], [ %323, %369 ]
  %384 = phi i32 [ %367, %329 ], [ 0, %327 ], [ 0, %369 ]
  %385 = phi i64 [ %366, %329 ], [ 0, %327 ], [ %379, %369 ]
  %386 = icmp ugt i32 %384, 7
  br i1 %386, label %389, label %387

387:                                              ; preds = %382
  %388 = icmp eq i32 %384, 0
  br i1 %388, label %440, label %427

389:                                              ; preds = %382
  %390 = load i8, ptr %383, align 1, !tbaa !26
  %391 = zext i8 %390 to i64
  %392 = getelementptr inbounds nuw i8, ptr %383, i64 1
  %393 = load i8, ptr %392, align 1, !tbaa !26
  %394 = zext i8 %393 to i64
  %395 = shl nuw nsw i64 %394, 8
  %396 = or disjoint i64 %395, %391
  %397 = getelementptr inbounds nuw i8, ptr %383, i64 2
  %398 = load i8, ptr %397, align 1, !tbaa !26
  %399 = zext i8 %398 to i64
  %400 = shl nuw nsw i64 %399, 16
  %401 = or disjoint i64 %396, %400
  %402 = getelementptr inbounds nuw i8, ptr %383, i64 3
  %403 = load i8, ptr %402, align 1, !tbaa !26
  %404 = zext i8 %403 to i64
  %405 = shl nuw nsw i64 %404, 24
  %406 = or disjoint i64 %401, %405
  %407 = getelementptr inbounds nuw i8, ptr %383, i64 4
  %408 = load i8, ptr %407, align 1, !tbaa !26
  %409 = zext i8 %408 to i64
  %410 = shl nuw nsw i64 %409, 32
  %411 = or disjoint i64 %406, %410
  %412 = getelementptr inbounds nuw i8, ptr %383, i64 5
  %413 = load i8, ptr %412, align 1, !tbaa !26
  %414 = zext i8 %413 to i64
  %415 = shl nuw nsw i64 %414, 40
  %416 = or i64 %411, %415
  %417 = getelementptr inbounds nuw i8, ptr %383, i64 6
  %418 = load i8, ptr %417, align 1, !tbaa !26
  %419 = zext i8 %418 to i64
  %420 = shl nuw nsw i64 %419, 48
  %421 = or i64 %416, %420
  %422 = getelementptr inbounds nuw i8, ptr %383, i64 7
  %423 = load i8, ptr %422, align 1, !tbaa !26
  %424 = zext i8 %423 to i64
  %425 = shl nuw i64 %424, 56
  %426 = or i64 %421, %425
  br label %440

427:                                              ; preds = %427, %387
  %428 = phi i32 [ %438, %427 ], [ 0, %387 ]
  %429 = phi i64 [ %437, %427 ], [ 0, %387 ]
  %430 = zext nneg i32 %428 to i64
  %431 = getelementptr inbounds nuw i8, ptr %383, i64 %430
  %432 = load i8, ptr %431, align 1, !tbaa !26
  %433 = zext i8 %432 to i64
  %434 = shl i32 %428, 3
  %435 = zext nneg i32 %434 to i64
  %436 = shl nuw i64 %433, %435
  %437 = or i64 %436, %429
  %438 = add nuw nsw i32 %428, 1
  %439 = icmp eq i32 %438, %384
  br i1 %439, label %440, label %427

440:                                              ; preds = %427, %389, %387
  %441 = phi i64 [ %426, %389 ], [ 0, %387 ], [ %437, %427 ]
  %442 = shl nuw nsw i64 %23, 2
  %443 = add nuw nsw i64 %442, 28
  %444 = and i64 %443, 480
  %445 = and i64 %22, -225
  %446 = or i64 %445, %25
  %447 = or i64 %446, %444
  %448 = tail call <2 x i64> @__ockl_hostcall_preview(i32 noundef 2, i64 noundef %447, i64 noundef %85, i64 noundef %145, i64 noundef %205, i64 noundef %265, i64 noundef %325, i64 noundef %385, i64 noundef %441) #15
  %449 = sub i64 %18, %23
  %450 = getelementptr inbounds nuw i8, ptr %19, i64 %23
  %451 = icmp eq i64 %449, 0
  br i1 %451, label %452, label %17

452:                                              ; preds = %440, %9
  %453 = phi <2 x i64> [ %12, %9 ], [ %448, %440 ]
  %454 = extractelement <2 x i64> %453, i64 0
  ret i64 %454
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umin.i64(i64, i64) #3

; Function Attrs: convergent norecurse nounwind
define weak hidden void @__ockl_sanitizer_report(i64 noundef %0, i64 noundef %1, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7) local_unnamed_addr #1 {
  %9 = tail call <2 x i64> @__ockl_hostcall_preview(i32 noundef 4, i64 noundef %0, i64 noundef %1, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7) #15
  ret void
}

attributes #0 = { "amdgpu-flat-work-group-size"="1,256" "uniform-work-group-size" }
attributes #1 = { convergent norecurse nounwind "denormal-fp-math"="dynamic,dynamic" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" }
attributes #2 = { cold convergent norecurse nounwind "denormal-fp-math"="dynamic,dynamic" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(none) "amdgpu-agpr-alloc"="0" "amdgpu-no-cluster-id-x" "amdgpu-no-cluster-id-y" "amdgpu-no-cluster-id-z" "amdgpu-no-completion-action" "amdgpu-no-default-queue" "amdgpu-no-dispatch-id" "amdgpu-no-dispatch-ptr" "amdgpu-no-flat-scratch-init" "amdgpu-no-heap-ptr" "amdgpu-no-hostcall-ptr" "amdgpu-no-implicitarg-ptr" "amdgpu-no-lds-kernel-id" "amdgpu-no-multigrid-sync-arg" "amdgpu-no-queue-ptr" "amdgpu-no-workgroup-id-x" "amdgpu-no-workgroup-id-y" "amdgpu-no-workgroup-id-z" "amdgpu-no-workitem-id-x" "amdgpu-no-workitem-id-y" "amdgpu-no-workitem-id-z" "denormal-fp-math"="dynamic,dynamic" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" }
attributes #5 = { convergent nocallback nofree nounwind willreturn memory(none) }
attributes #6 = { nocallback nofree nosync nounwind willreturn }
attributes #7 = { convergent mustprogress norecurse nounwind willreturn "amdgpu-agpr-alloc"="0" "amdgpu-no-cluster-id-x" "amdgpu-no-cluster-id-y" "amdgpu-no-cluster-id-z" "amdgpu-no-completion-action" "amdgpu-no-default-queue" "amdgpu-no-dispatch-id" "amdgpu-no-dispatch-ptr" "amdgpu-no-flat-scratch-init" "amdgpu-no-heap-ptr" "amdgpu-no-hostcall-ptr" "amdgpu-no-implicitarg-ptr" "amdgpu-no-lds-kernel-id" "amdgpu-no-multigrid-sync-arg" "amdgpu-no-queue-ptr" "amdgpu-no-workgroup-id-x" "amdgpu-no-workgroup-id-y" "amdgpu-no-workgroup-id-z" "amdgpu-no-workitem-id-x" "amdgpu-no-workitem-id-y" "amdgpu-no-workitem-id-z" "denormal-fp-math"="dynamic,dynamic" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" }
attributes #8 = { nocallback nounwind willreturn }
attributes #9 = { nocallback nofree nosync nounwind willreturn memory(none) }
attributes #10 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) "amdgpu-agpr-alloc"="0" "amdgpu-no-cluster-id-x" "amdgpu-no-cluster-id-y" "amdgpu-no-cluster-id-z" "amdgpu-no-completion-action" "amdgpu-no-default-queue" "amdgpu-no-dispatch-id" "amdgpu-no-dispatch-ptr" "amdgpu-no-flat-scratch-init" "amdgpu-no-heap-ptr" "amdgpu-no-hostcall-ptr" "amdgpu-no-implicitarg-ptr" "amdgpu-no-lds-kernel-id" "amdgpu-no-multigrid-sync-arg" "amdgpu-no-queue-ptr" "amdgpu-no-workgroup-id-x" "amdgpu-no-workgroup-id-y" "amdgpu-no-workgroup-id-z" "denormal-fp-math"="dynamic,dynamic" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" }
attributes #11 = { convergent nocallback nofree nounwind willreturn }
attributes #12 = { cold convergent norecurse nounwind optsize "denormal-fp-math"="dynamic,dynamic" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" }
attributes #13 = { convergent mustprogress nofree norecurse nounwind willreturn memory(none) "amdgpu-agpr-alloc"="0" "amdgpu-no-cluster-id-x" "amdgpu-no-cluster-id-y" "amdgpu-no-cluster-id-z" "amdgpu-no-completion-action" "amdgpu-no-default-queue" "amdgpu-no-dispatch-id" "amdgpu-no-dispatch-ptr" "amdgpu-no-flat-scratch-init" "amdgpu-no-heap-ptr" "amdgpu-no-hostcall-ptr" "amdgpu-no-implicitarg-ptr" "amdgpu-no-lds-kernel-id" "amdgpu-no-multigrid-sync-arg" "amdgpu-no-queue-ptr" "amdgpu-no-workgroup-id-x" "amdgpu-no-workgroup-id-y" "amdgpu-no-workgroup-id-z" "amdgpu-no-workitem-id-x" "amdgpu-no-workitem-id-y" "amdgpu-no-workitem-id-z" "denormal-fp-math"="dynamic,dynamic" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" }
attributes #14 = { convergent mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite) "amdgpu-agpr-alloc"="0" "amdgpu-no-cluster-id-x" "amdgpu-no-cluster-id-y" "amdgpu-no-cluster-id-z" "amdgpu-no-completion-action" "amdgpu-no-default-queue" "amdgpu-no-dispatch-id" "amdgpu-no-dispatch-ptr" "amdgpu-no-flat-scratch-init" "amdgpu-no-heap-ptr" "amdgpu-no-hostcall-ptr" "amdgpu-no-implicitarg-ptr" "amdgpu-no-lds-kernel-id" "amdgpu-no-multigrid-sync-arg" "amdgpu-no-queue-ptr" "amdgpu-no-workgroup-id-x" "amdgpu-no-workgroup-id-y" "amdgpu-no-workgroup-id-z" "amdgpu-no-workitem-id-x" "amdgpu-no-workitem-id-y" "amdgpu-no-workitem-id-z" "denormal-fp-math"="dynamic,dynamic" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-features"="+gfx8-insts" "uniform-work-group-size"="false" }
attributes #15 = { convergent nounwind }
attributes #16 = { cold convergent nounwind }
attributes #17 = { convergent nounwind willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2}
!opencl.ocl.version = !{!3}
!llvm.ident = !{!4}

!0 = !{i32 2, !"Debug Info Version", i32 3}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 0}
!3 = !{i32 2, i32 0}
!4 = !{!"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"}
!5 = !{!6, !6, i64 0}
!6 = !{!"int", !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{!10, !10, i64 0}
!10 = !{!"long", !7, i64 0}
!11 = !{!12, !13, i64 0}
!12 = !{!"", !13, i64 0, !13, i64 8, !14, i64 16, !10, i64 24, !10, i64 32, !10, i64 40}
!13 = !{!"any pointer", !7, i64 0}
!14 = !{!"hsa_signal_s", !10, i64 0}
!15 = !{!12, !10, i64 40}
!16 = !{!12, !13, i64 8}
!17 = !{!18, !6, i64 16}
!18 = !{!"", !10, i64 0, !10, i64 8, !6, i64 16, !6, i64 20}
!19 = !{!18, !10, i64 8}
!20 = !{!18, !6, i64 20}
!21 = !{!18, !10, i64 0}
!22 = !{}
!23 = !{!24, !10, i64 16}
!24 = !{!"amd_signal_s", !10, i64 0, !7, i64 8, !10, i64 16, !6, i64 24, !6, i64 28, !10, i64 32, !10, i64 40, !7, i64 48, !7, i64 56}
!25 = !{!24, !6, i64 24}
!26 = !{!7, !7, i64 0}
!27 = !{!"amdgpu-synchronize-as", !"global"}
!28 = !{!29, !10, i64 108552}
!29 = !{!"heap_s", !7, i64 0, !7, i64 2048, !7, i64 4096, !7, i64 6144, !7, i64 8192, !7, i64 10240, !7, i64 108544, !10, i64 108552, !10, i64 108560, !7, i64 108568, !7, i64 108680}
!30 = !{!29, !10, i64 108560}
!31 = !{!32, !32, i64 0}
!32 = !{!"bool", !7, i64 0}
!33 = !{i8 0, i8 2}
!34 = !{!35, !6, i64 4}
!35 = !{!"slab_s", !6, i64 0, !6, i64 4, !7, i64 8, !6, i64 12, !7, i64 16}
