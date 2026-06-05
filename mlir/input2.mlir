module attributes {
  llvm.target_triple = "amdgcn-amd-amdhsa",
  rocdl.arch = "gfx942"
} {
  llvm.func @kernel_cos(
      %arg0: !llvm.ptr<1>,
      %arg1: !llvm.ptr<1>)
      attributes {rocdl.kernel} {
    %c0 = llvm.mlir.constant(0 : i32) : i32
    %c1 = llvm.mlir.constant(1 : i32) : i32
    %c4_i32 = llvm.mlir.constant(4 : i32) : i32
    %c4_i64 = llvm.mlir.constant(4 : i64) : i64

    %tid = rocdl.workitem.id.x : i32
    %bid = rocdl.workgroup.id.x : i32
    %bdim = rocdl.workgroup.dim.x : i32

    %global_tid0 = llvm.mul %bid, %bdim : i32
    %global_tid = llvm.add %global_tid0, %tid : i32

    %base = llvm.mul %global_tid, %c4_i32 : i32

    %idx0 = %base : i32
    %idx1 = llvm.add %base, %c1 : i32
    %idx2 = llvm.add %base, %c4_i32 : i32
    %idx3 = llvm.add %idx2, %c1 : i32

    %p0 = llvm.getelementptr %arg0[%idx0] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
    %p1 = llvm.getelementptr %arg0[%idx1] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
    %p2 = llvm.getelementptr %arg0[%idx2] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
    %p3 = llvm.getelementptr %arg0[%idx3] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32

    %x0 = llvm.load %p0 : !llvm.ptr<1> -> f32
    %x1 = llvm.load %p1 : !llvm.ptr<1> -> f32
    %x2 = llvm.load %p2 : !llvm.ptr<1> -> f32
    %x3 = llvm.load %p3 : !llvm.ptr<1> -> f32

    %y0 = rocdl.cos %x0 f32 -> f32
    %y1 = rocdl.cos %x1 f32 -> f32
    %y2 = rocdl.cos %x2 f32 -> f32
    %y3 = rocdl.cos %x3 f32 -> f32

    %q0 = llvm.getelementptr %arg1[%idx0] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
    %q1 = llvm.getelementptr %arg1[%idx1] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
    %q2 = llvm.getelementptr %arg1[%idx2] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32
    %q3 = llvm.getelementptr %arg1[%idx3] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f32

    llvm.store %y0, %q0 : f32, !llvm.ptr<1>
    llvm.store %y1, %q1 : f32, !llvm.ptr<1>
    llvm.store %y2, %q2 : f32, !llvm.ptr<1>
    llvm.store %y3, %q3 : f32, !llvm.ptr<1>

    llvm.return
  }
}