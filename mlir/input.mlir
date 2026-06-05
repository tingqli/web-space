module attributes {
  gpu.container_module
} {
  gpu.module @kernels [#rocdl.target<chip = "gfx942">] {
    gpu.func @vec_cos_kernel(%arg0: memref<1024xf32, 1>,
                             %arg1: memref<1024xf32, 1>)
        kernel 
        attributes {
            passthrough = ["amdgpu-no-implicitarg-ptr"]
        }        {
      %c0 = arith.constant 0 : index
      %c1024 = arith.constant 1024 : index
      %c4 = arith.constant 4 : index

      scf.for %i = %c0 to %c1024 step %c4 {
        %v = vector.load %arg0[%i] : memref<1024xf32, 1>, vector<4xf32>

        %f0 = vector.extract %v[0] : f32 from vector<4xf32>
        %f1 = vector.extract %v[1] : f32 from vector<4xf32>
        %f2 = vector.extract %v[2] : f32 from vector<4xf32>
        %f3 = vector.extract %v[3] : f32 from vector<4xf32>

        %c0v = rocdl.cos %f0 f32 -> f32
        %c1v = rocdl.cos %f1 f32 -> f32
        %c2v = rocdl.cos %f2 f32 -> f32
        %c3v = rocdl.cos %f3 f32 -> f32

        %r0 = vector.insert %c0v, %v[0] : f32 into vector<4xf32>
        %r1 = vector.insert %c1v, %r0[1] : f32 into vector<4xf32>
        %r2 = vector.insert %c2v, %r1[2] : f32 into vector<4xf32>
        %r3 = vector.insert %c3v, %r2[3] : f32 into vector<4xf32>

        vector.store %r3, %arg1[%i] : memref<1024xf32, 1>, vector<4xf32>
      }

      gpu.return
    }
  }
}