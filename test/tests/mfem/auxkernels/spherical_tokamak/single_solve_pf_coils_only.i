[Mesh]
  type = MFEMFileMesh
  file = corrected_pf_mesh_quad4_2d_bc12.e
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
  # Diagnostic/output representation of J_theta.
  [Jtheta]
    type = MFEMVariable
    fespace = L2FESpace
  []

  # Diagnostic/output representation of r * J_theta.
  [sourceCoef]
    type = MFEMVariable
    fespace = L2FESpace
  []

  # Magnetic field B = (B_r, B_z).
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

  # -------------------------------------------------------
  # Direct MFEM-native CSV readers
  #
  # CSV rows correspond in order to PF attributes 1 ... 10.
  #
  # Old libMesh mapping:
  # column 2 -> dx
  # column 3 -> dz
  # column 4 -> I
  # -------------------------------------------------------

  [coil_dx]
    type = MFEMPiecewiseConstantFromCSV
    csv_file = pf_currents_pf_only.csv

    header = false
    value_column_index = 2

    attributes = '1 2 3 4 5 6 7 8 9 10'

    # Avoid division by zero outside the PF blocks.
    default_value = 1.0
  []

  [coil_dz]
    type = MFEMPiecewiseConstantFromCSV
    csv_file = pf_currents_pf_only.csv

    header = false
    value_column_index = 3

    attributes = '1 2 3 4 5 6 7 8 9 10'

    # Avoid division by zero outside the PF blocks.
    default_value = 1.0
  []

  [coil_current]
    type = MFEMPiecewiseConstantFromCSV
    csv_file = pf_currents_pf_only.csv

    header = false
    value_column_index = 4

    attributes = '1 2 3 4 5 6 7 8 9 10'

    # No PF source outside PF attributes.
    default_value = 0.0
  []

  # -------------------------------------------------------
  # Current density
  #
  # This exactly reproduces the old libMesh expression:
  #
  #     Jtheta = I / (dx * dz)
  # -------------------------------------------------------

  [Jtheta_fun]
    type = MFEMParsedFunction
    expression = 'I/(dx*dz)'
    symbol_names = 'I dx dz'
    symbol_values = 'coil_current coil_dx coil_dz'
  []

  # -------------------------------------------------------
  # Axisymmetric RHS:
  #
  #     sourceCoef = r * Jtheta
  #                = r * I/(dx*dz)
  #
  # cylindrical_r is already an MFEM coefficient.
  # -------------------------------------------------------

  [sourceCoef_fun]
    type = MFEMParsedFunction
    expression = 'r*I/(dx*dz)'
    symbol_names = 'r I dx dz'
    symbol_values = 'cylindrical_r coil_current coil_dx coil_dz'
  []
[]

[FunctorMaterials]
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

  # ∫ (r J_theta) v
  #
  # Applied only on PF attributes 1...10.
  [source_coils]
    type = MFEMDomainLFKernel
    variable = Atheta
    coefficient = sourceCoef_fun
    block = '1 2 3 4 5 6 7 8 9 10'
  []
[]

[AuxKernels]
  # Project Jtheta for visualization.
  [project_Jtheta]
    type = MFEMScalarProjectionAux
    variable = Jtheta
    coefficient = Jtheta_fun
    block = '1 2 3 4 5 6 7 8 9 10'
    execute_on = INITIAL
  []

  # Project r*Jtheta for visualization/debugging.
  [project_sourceCoef]
    type = MFEMScalarProjectionAux
    variable = sourceCoef
    coefficient = sourceCoef_fun
    block = '1 2 3 4 5 6 7 8 9 10'
    execute_on = INITIAL
  []

  # B_r = -dA_theta/dz
  # B_z = dA_theta/dr + A_theta/r
  [B_from_Atheta]
    type = MFEMMeridionalCurlAux
    variable = B
    source = Atheta
  []
[]

[BCs]
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

[Outputs]
  [ParaViewDataCollection]
    type = MFEMParaViewDataCollection
    file_base = OutputData/AxisymmetricTokamak

    scalar_coefficients =
      'cylindrical_r
       cylindrical_inv_r
       cylindrical_p
       cylindrical_z
       coil_current
       coil_dx
       coil_dz'

    vtk_format = ASCII
  []
[]