[Mesh]
  type = MFEMMesh
  file = spherical_tokamak_axisymmetric.e
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
  [B]
    type = MFEMVariable
    fespace = RTFESpace
  []

  [J]
    type = MFEMVariable
    fespace = L2FESpace
  []
[]

[UserObjects]
  [pf_current_reader]
    type = PropertyReadFile
    prop_file_name = pf_currents_pf_only.csv
    read_type = block
    nprop = 1
    nblock = 10
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
    inv_r_eps = 1E-12
  []
  # Same as cylindrical_r, but exposed as a Function so it
  [r_for_source]
    type = ParsedFunction
    expression = 'sqrt(x*x + y*y)'
  []

  # Reads the current density J_theta from the CSV file.
  # CSV format should be one value per row:
  #   row 1  -> pf_coil_1
  #   ...
  #   row 10 -> pf_coil_10
  [coil_current]
    type = PiecewiseConstantFromCSV
    read_prop_user_object = pf_current_reader
    read_type = block
    column_number = 0
  []

  # current density I in each coil, used to define the source coefficient r*J_theta
  [Jtheta_csv]
    type = MFEMParsedFunction
    expression = I
    symbol_names = 'I'
    symbol_values = 'coil_current'
  []

  # Axisymmetric RHS coefficient:
  #
  #   sourceCoef = r * J_theta
  #
  [sourceCoef_csv]
    type = MFEMParsedFunction
    expression = r*I
    symbol_names = 'r I'
    symbol_values = 'r_for_source coil_current'
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
  [diffusion]
    type = MFEMDiffusionKernel
    variable = Atheta
    coefficient = diffCoef
  []

  [mass]
    type = MFEMMassKernel
    variable = Atheta
    coefficient = massCoef
  []

  [source_coils]
    type = MFEMDomainLFKernel
    variable = Atheta
    coefficient = sourceCoef_csv
    # block = 'pf_coil_1 pf_coil_2 pf_coil_3 pf_coil_4 pf_coil_5 pf_coil_6 pf_coil_7 pf_coil_8 pf_coil_9 pf_coil_10'
    block = '1 2 3 4 5 6 7 8 9 10'
  []
[]

[AuxKernels]
  [B_from_Atheta]
    type = MFEMAxisymmetricCurlAthetaAux
    variable = B
    source = Atheta
    coordinate_function = cylindrical
  []

  [project_Jtheta]
    type = MFEMScalarProjectionAux
    variable = J
    coefficient = Jtheta_csv
   # block = 'pf_coil_1 pf_coil_2 pf_coil_3 pf_coil_4 pf_coil_5 pf_coil_6 pf_coil_7 pf_coil_8 pf_coil_9 pf_coil_10'
    #block = '1 2 3 4 5 6 7 8 9 10'
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

[Preconditioner]
  [boomeramg]
    type = MFEMHypreBoomerAMG
  []
[]

[Solvers]
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
    scalar_coefficients = 'cylindrical_r cylindrical_inv_r'
    vtk_format = ASCII
  []
[]