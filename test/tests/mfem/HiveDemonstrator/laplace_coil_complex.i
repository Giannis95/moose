#Electrostatics on the coil, initialise and solve the lapace equation on the coil only

[Mesh]
    type = MFEMMesh
    file = vac_oval_coil_solid_target_coarse.e
    dim = 3
[]

[Problem]
    type = MFEMProblem
    numeric_type = complex
[]

[FESpaces]
    [H1FESpace]
        type = MFEMScalarFESpace
        fec_type = H1
        fec_order = FIRST
    []

    [L2FESpace]
        type = MFEMVectorFESpace
        fec_type = L2
        fec_order = CONSTANT
        fec_map = VALUE
  []
   [HCurlFESpace]
      type = MFEMVectorFESpace
      fec_type = ND
      fec_order = FIRST
  []
[]

[Variables]
    [electric_potential]
        type = MFEMComplexVariable
        fespace = H1FESpace
    []
[]

[AuxVariables]
  [e_field]
    type = MFEMComplexVariable
    fespace = HCurlFESpace
  []
[]

[Functions]
  [stiffnessCoef]
    type = ParsedFunction
    expression = 1.0
  []
[]

[AuxKernels]
  [grad_v]
    type = MFEMComplexGradAux
    variable = e_field
    source = electric_potential
    scale_factor = -1
    execute_on =TIMESTEP_END
  []
 []

[BCs]
  [coil_input]
    type = MFEMComplexScalarDirichletBC
    variable = electric_potential
    boundary = 'coil_in'
    coefficient_real = 100.0
    coefficient_imag = 0.0 #no phase-shift
  []
  [coil_output]
    type = MFEMComplexScalarDirichletBC
    variable = electric_potential
    boundary = 'coil_out'
    coefficient_real = 0.0
    coefficient_imag = 0.0
  []

    #[terminal_plane]
    # Natural on lateral coil surface is implicit with diffusion kernel
    # boundary = 'terminal plane'
    #[]
[]

[Kernels]
  [diff_complex]
    type = MFEMComplexKernel
    variable = electric_potential
    block = 'coil'
    [RealComponent]
      type = MFEMDiffusionKernel
      coefficient = stiffnessCoef
    []
    [ImagComponent]
      type = MFEMDiffusionKernel
      coefficient = 0.0
    []
  []
[]

[Preconditioner]
  [boomeramg]
    type = MFEMHypreBoomerAMG
  []
  [jacobi]
    type = MFEMOperatorJacobiSmoother
  []
[]

[Solver]
  type = MFEMHypreGMRES
  preconditioner = boomeramg
  l_tol = 1e-16
  l_max_its = 1000
[]

[Executioner]
  type = MFEMSteady
  device = cpu
[]

[Outputs]
  [ParaViewDataCollection]
    type = MFEMParaViewDataCollection
    file_base = HIVE/Aform_frequency_domain/laplace
    vtk_format = ASCII
  []
[]
