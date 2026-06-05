	.amdgcn_target "amdgcn-amd-amdhsa--gfx942"
	.amdhsa_code_object_version 6
	.text
	.globl	my_kernel                       ; -- Begin function my_kernel
	.p2align	8
	.type	my_kernel,@function
my_kernel:                              ; @my_kernel
; %bb.0:
	s_add_u32 s48, s4, 16
	s_addc_u32 s49, s5, 0
	s_mov_b64 s[38:39], s[0:1]
	s_getpc_b64 s[0:1]
	s_add_u32 s0, s0, __ockl_printf_begin@gotpcrel32@lo+4
	s_addc_u32 s1, s1, __ockl_printf_begin@gotpcrel32@hi+12
	s_load_dwordx2 s[0:1], s[0:1], 0x0
	s_mov_b32 s33, s10
	s_mov_b32 s50, s9
	s_mov_b32 s51, s8
	s_mov_b64 s[34:35], s[6:7]
	v_mov_b32_e32 v40, v0
	s_mov_b64 s[4:5], s[38:39]
	s_mov_b64 s[6:7], s[2:3]
	s_mov_b64 s[8:9], s[48:49]
	s_mov_b64 s[10:11], s[34:35]
	s_mov_b32 s12, s51
	s_mov_b32 s13, s50
	s_mov_b32 s14, s33
	v_mov_b32_e32 v31, v0
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v1, 0
	s_mov_b32 s32, 0
	s_mov_b64 s[36:37], s[2:3]
	s_waitcnt lgkmcnt(0)
	s_swappc_b64 s[30:31], s[0:1]
	s_getpc_b64 s[0:1]
	s_add_u32 s0, s0, printfFormat_0@rel32@lo+4
	s_addc_u32 s1, s1, printfFormat_0@rel32@hi+12
	s_getpc_b64 s[2:3]
	s_add_u32 s2, s2, __ockl_printf_append_string_n@gotpcrel32@lo+4
	s_addc_u32 s3, s3, __ockl_printf_append_string_n@gotpcrel32@hi+12
	s_load_dwordx2 s[2:3], s[2:3], 0x0
	s_mov_b64 s[4:5], s[38:39]
	s_mov_b64 s[6:7], s[36:37]
	s_mov_b64 s[8:9], s[48:49]
	s_mov_b64 s[10:11], s[34:35]
	s_mov_b32 s12, s51
	s_mov_b32 s13, s50
	s_mov_b32 s14, s33
	v_mov_b32_e32 v31, v40
	v_mov_b32_e32 v2, s0
	v_mov_b32_e32 v3, s1
	v_mov_b32_e32 v4, 13
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v6, 0
	s_waitcnt lgkmcnt(0)
	s_swappc_b64 s[30:31], s[2:3]
	s_getpc_b64 s[0:1]
	s_add_u32 s0, s0, __ockl_printf_append_args@gotpcrel32@lo+4
	s_addc_u32 s1, s1, __ockl_printf_append_args@gotpcrel32@hi+12
	s_load_dwordx2 s[0:1], s[0:1], 0x0
	s_mov_b64 s[4:5], s[38:39]
	s_mov_b64 s[6:7], s[36:37]
	s_mov_b64 s[8:9], s[48:49]
	s_mov_b64 s[10:11], s[34:35]
	s_mov_b32 s12, s51
	s_mov_b32 s13, s50
	s_mov_b32 s14, s33
	v_mov_b32_e32 v31, v40
	v_mov_b32_e32 v2, 1
	v_mov_b32_e32 v3, 42
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v7, 0
	v_mov_b32_e32 v8, 0
	v_mov_b32_e32 v9, 0
	v_mov_b32_e32 v10, 0
	v_mov_b32_e32 v11, 0
	v_mov_b32_e32 v12, 0
	v_mov_b32_e32 v13, 0
	v_mov_b32_e32 v14, 0
	v_mov_b32_e32 v15, 0
	v_mov_b32_e32 v16, 0
	v_mov_b32_e32 v17, 1
	s_waitcnt lgkmcnt(0)
	s_swappc_b64 s[30:31], s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel my_kernel
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 12
		.amdhsa_user_sgpr_count 8
		.amdhsa_user_sgpr_dispatch_ptr 1
		.amdhsa_user_sgpr_queue_ptr 1
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 1
		.amdhsa_user_sgpr_kernarg_preload_length 0
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_uses_dynamic_stack 1
		.amdhsa_enable_private_segment 1
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 2
		.amdhsa_next_free_vgpr max(totalnumvgprs(my_kernel.num_agpr, my_kernel.num_vgpr), 1, 0)
		.amdhsa_next_free_sgpr max(my_kernel.numbered_sgpr+6, 1, 0)-6
		.amdhsa_accum_offset (((((alignto(max(1, my_kernel.num_vgpr), 4)/4)-1)&~65536)&63)+1)*4
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
		.amdhsa_exception_fp_ieee_invalid_op 0
		.amdhsa_exception_fp_denorm_src 0
		.amdhsa_exception_fp_ieee_div_zero 0
		.amdhsa_exception_fp_ieee_overflow 0
		.amdhsa_exception_fp_ieee_underflow 0
		.amdhsa_exception_fp_ieee_inexact 0
		.amdhsa_exception_int_div_zero 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size	my_kernel, .Lfunc_end0-my_kernel
                                        ; -- End function
	.set my_kernel.num_vgpr, max(41, amdgpu.max_num_vgpr)
	.set my_kernel.num_agpr, max(0, amdgpu.max_num_agpr)
	.set my_kernel.numbered_sgpr, max(52, amdgpu.max_num_sgpr)
	.set my_kernel.num_named_barrier, max(0, amdgpu.max_num_named_barrier)
	.set my_kernel.private_seg_size, 0
	.set my_kernel.uses_vcc, 1
	.set my_kernel.uses_flat_scratch, 1
	.set my_kernel.has_dyn_sized_stack, 1
	.set my_kernel.has_recursion, 1
	.set my_kernel.has_indirect_call, 1
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 360
; TotalNumSgprs: my_kernel.numbered_sgpr+6
; NumVgprs: my_kernel.num_vgpr
; NumAgprs: my_kernel.num_agpr
; TotalNumVgprs: totalnumvgprs(my_kernel.num_agpr, my_kernel.num_vgpr)
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: (alignto(max(max(my_kernel.numbered_sgpr+extrasgprs(my_kernel.uses_vcc, my_kernel.uses_flat_scratch, 1), 1, 0), 1), 8)/8)-1
; VGPRBlocks: (alignto(max(max(totalnumvgprs(my_kernel.num_agpr, my_kernel.num_vgpr), 1, 0), 1), 8)/8)-1
; NumSGPRsForWavesPerEU: max(my_kernel.numbered_sgpr+6, 1, 0)
; NumVGPRsForWavesPerEU: max(totalnumvgprs(my_kernel.num_agpr, my_kernel.num_vgpr), 1, 0)
; AccumOffset: ((alignto(max(1, my_kernel.num_vgpr), 4)/4)-1+1)*4
; Occupancy: occupancy(8, 8, 512, 8, 8, max(my_kernel.numbered_sgpr+extrasgprs(my_kernel.uses_vcc, my_kernel.uses_flat_scratch, 1), 1, 0), max(totalnumvgprs(my_kernel.num_agpr, my_kernel.num_vgpr), 1, 0))
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 1
; COMPUTE_PGM_RSRC2:USER_SGPR: 8
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 2
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: (((alignto(max(1, my_kernel.num_vgpr), 4)/4)-1)&~65536)&63
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.set amdgpu.max_num_named_barrier, 0
	.text
	.type	printfFormat_0,@object          ; @printfFormat_0
	.section	.rodata,"a",@progbits
printfFormat_0:
	.asciz	"Hello,World\n"
	.size	printfFormat_0, 13

	.section	".note.GNU-stack","",@progbits
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .offset:         8
        .size:           4
        .value_kind:     by_value
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 12
    .max_flat_workgroup_size: 256
    .name:           my_kernel
    .private_segment_fixed_size: 0
    .sgpr_count:     58
    .sgpr_spill_count: 0
    .symbol:         my_kernel.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: true
    .vgpr_count:     41
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx942
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
