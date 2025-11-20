#Electrostatics on the coil, initialise and solve the lapace equation on the coil only

[Mesh]
    type = MFEMMesh
    file = vac_oval_coil_solid_target_coarse.e
    dim = 3
[]

[Problem]
    type = MFEMProblem
[]

[FESpaces]
    [H1FESpace]
        type = MFEMScalarFESpace
        fec_type = H1
        fec_order = FIRST
    []

    [HCurlFESpace]
        type = MFEMVectorFESpace
        fec_type = ND
        fec_order = FIRST
    []

    [L2FESpace]
        type = MFEMVectorFESpace
        fec_type = L2
        fec_order = CONSTANT
        fec_map = VALUE
  []
[]

[Variables]
    [electric_potential]
        type = MFEMVariable
        fespace = H1FESpace
    []
[]

[AuxVariables]
    [e_field]
        type = MFEMVariable
        fespace = HCurlFESpace
    []
[]

[AuxKernels]
    [grad_v]
        type = MFEMGradAux
        variable = e_field
        source = electric_potential
        scale_factor = -1
        execute_on =TIMESTEP_END
    []
[]

[BCs]
    [coil_input]
        type = MFEMScalarDirichletBC
        variable = electric_potential
        boundary = 'coil_in'
        coefficient = 100.0
    []
    [coil_output]
        type = MFEMScalarDirichletBC
        variable = electric_potential
        boundary = 'coil_out'
        coefficient = 0.0
    []

    #[terminal_plane]
    # Natural on lateral coil surface is implicit with diffusion kernel
    # boundary = 'terminal plane'
    #[]
[]

[Kernels]
  [diff]
    type = MFEMDiffusionKernel
    variable = electric_potential
    block = 'coil'
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
    file_base = HIVE/electrostatic
    vtk_format = ASCII
  []
[]
