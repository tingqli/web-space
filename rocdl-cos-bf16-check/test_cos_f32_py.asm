	.amdgcn_target "amdgcn-amd-amdhsa--gfx942"
	.amdhsa_code_object_version 6
	.text
	.globl	test_cos_f32                    ; -- Begin function test_cos_f32
	.p2align	6
	.type	test_cos_f32,@function
test_cos_f32:                           ; @test_cos_f32
; %bb.0:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
	v_cos_f32_e32 v0, v0
	s_setpc_b64 s[30:31]
.Lfunc_end0:
	.size	test_cos_f32, .Lfunc_end0-test_cos_f32
                                        ; -- End function
	.set test_cos_f32.num_vgpr, 1
	.set test_cos_f32.num_agpr, 0
	.set test_cos_f32.numbered_sgpr, 32
	.set test_cos_f32.num_named_barrier, 0
	.set test_cos_f32.private_seg_size, 0
	.set test_cos_f32.uses_vcc, 0
	.set test_cos_f32.uses_flat_scratch, 0
	.set test_cos_f32.has_dyn_sized_stack, 0
	.set test_cos_f32.has_recursion, 0
	.set test_cos_f32.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Function info:
; codeLenInByte = 12
; TotalNumSgprs: 38
; NumVgprs: 1
; NumAgprs: 0
; TotalNumVgprs: 1
; ScratchSize: 0
; MemoryBound: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 1
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 32
	.set amdgpu.max_num_named_barrier, 0
	.text
	.section	".note.GNU-stack","",@progbits
	.amdgpu_metadata
---
amdhsa.kernels:  []
amdhsa.target:   amdgcn-amd-amdhsa--gfx942
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
