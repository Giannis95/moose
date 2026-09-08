[Mesh]
  type = FileMesh
  file = spherical_tokamak_axisymmetric2D.e
[]

[Problem]
  solve = false
[]

[AuxVariables]
  [Jtheta_lm]
    family = MONOMIAL
    order = CONSTANT
  []

  [sourceCoef_lm]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[UserObjects]
  [reader_block]
    type = PropertyReadFile
    prop_file_name = 'pf_currents_pf_only.csv'
    read_type = block
    nprop = 5
    nblock = 10
    use_zero_based_block_indexing = false
  []
[]

[Functions]
  [coil_dx]
    type = PiecewiseConstantFromCSV
    read_prop_user_object = reader_block
    read_type = block
    column_number = 2
  []

  [coil_dz]
    type = PiecewiseConstantFromCSV
    read_prop_user_object = reader_block
    read_type = block
    column_number = 3
  []

  [coil_current]
    type = PiecewiseConstantFromCSV
    read_prop_user_object = reader_block
    read_type = block
    column_number = 4
  []

  [Jtheta_fun]
    type = ParsedFunction
    expression = 'I/(dx*dz)'
    symbol_names = 'I dx dz'
    symbol_values = 'coil_current coil_dx coil_dz'
  []

  [sourceCoef_fun]
    type = ParsedFunction
    expression = 'sqrt(x*x + y*y)*I/(dx*dz)'
    symbol_names = 'I dx dz'
    symbol_values = 'coil_current coil_dx coil_dz'
  []
[]

[AuxKernels]
  [set_Jtheta]
    type = FunctionAux
    variable = Jtheta_lm
    function = Jtheta_fun
    block = '1 2 3 4 5 6 7 8 9 10'
    execute_on = INITIAL
  []

  [set_sourceCoef]
    type = FunctionAux
    variable = sourceCoef_lm
    function = sourceCoef_fun
    block = '1 2 3 4 5 6 7 8 9 10'
    execute_on = INITIAL
  []
[]

[Executioner]
  type = Steady
[]

[Outputs]
  csv = true
  file_base = OutputData/PFCurrentReader
[]