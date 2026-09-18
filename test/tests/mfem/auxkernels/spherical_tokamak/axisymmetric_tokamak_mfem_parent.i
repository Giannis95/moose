[Mesh]
  type = MFEMFileMesh
  file = spherical_tokamak_axisymmetric2D.e

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

  [RTFESpace]
    type = MFEMVectorFESpace
    fec_type = RT
    fec_order = CONSTANT
  []

  [L2FESpace]
    type = MFEMScalarFESpace
    fec_type = L2
    fec_order = CONSTANT
    basis = GaussLegendre
  []
[]

[Variables]
  [Atheta]
    type = MFEMVariable
    fespace = H1FESpace
  []
[]

[AuxVariables]
  # Transferred physical current density J_theta from the libMesh subapp.
  [Jtheta]
    type = MFEMVariable
    fespace = L2FESpace
  []

  # Transferred weighted RHS coefficient r * J_theta from the libMesh subapp.
  [sourceCoef]
    type = MFEMVariable
    fespace = L2FESpace
  []

  # Magnetic field B = (B_r, B_z), computed from Atheta.
  [B]
    type = MFEMVariable
    fespace = RTFESpace
  []
[]

[Functions]
  [zero]
    type = MFEMParsedFunction
    expression = 0
  []

  [cylindrical]
    type = MFEMCoordinateTransformations
    coord_type = RZ
    inv_r_eps = 1e-6
  []
  # just for testing is this is passed as source in the solve
  [one]
    type = MFEMParsedFunction
    expression = 1
  []
[]

[FunctorMaterials]
  # Axisymmetric operator coefficients.
  #
  #   diffCoef = r
  #   massCoef = 1/r
  #
  [cyl_coeffs]
    type = MFEMGenericFunctorMaterial
    prop_names = 'diffCoef massCoef'
    prop_values = 'cylindrical_r cylindrical_inv_r'
  []
[]

[Kernels]
  # ∫ r grad(A_theta) · grad(v)
  [diffusion]
    type = MFEMDiffusionKernel
    variable = Atheta
    coefficient = diffCoef
  []

  # ∫ (1/r) A_theta v
  [mass]
    type = MFEMMassKernel
    variable = Atheta
    coefficient = massCoef
  []

  # sourceCoef is transferred from the libMesh subapp.
  # The source is applied only on the PF coil blocks.
  [source_coils]
    type = MFEMDomainLFKernel
    variable = Atheta
    coefficient = sourceCoef
    block = '1 2 3 4 5 6 7 8 9 10'
  []
[]

[AuxKernels]
  # B_r = -dA_theta/dz
  # B_z =  dA_theta/dr + A_theta/r
  [B_from_Atheta]
    type = MFEMAxisymmetricCurlAthetaAux
    variable = B
    source = Atheta
    coordinate_function = cylindrical
  []
[]

[BCs]
  # Vacuum is a volume block, not a boundary condition.
  [essential]
    type = MFEMScalarDirichletBC
    variable = Atheta
    boundary = 12
    coefficient = zero
  []
[]


[Solvers]
  [boomeramg]
    type = MFEMHypreBoomerAMG
  []
  [PCG]
    type = MFEMHyprePCG
    preconditioner = boomeramg
    l_tol = 1e-8
  []
[]

[Executioner]
  type = MFEMSteady
  device = cpu
[]

[MultiApps]
  [current_reader]
    type = FullSolveMultiApp
    input_files = pf_current_reader_libmesh_sub.i
    execute_on = INITIAL
  []
[]

[Transfers]
  [pull_currents_from_libmesh]
    type = MultiApplibMeshToMFEMShapeEvaluationTransfer
    from_multi_app = current_reader
    source_variables = 'Jtheta_lm sourceCoef_lm'
    variables = 'Jtheta sourceCoef'
    execute_on = INITIAL
  []
[]

[Outputs]
  [ParaViewDataCollection]
    type = MFEMParaViewDataCollection
    file_base = OutputData/AxisymmetricTokamak
    scalar_coefficients = 'cylindrical_r cylindrical_inv_r cylindrical_p cylindrical_z'
    vtk_format = ASCII
  []
[]
