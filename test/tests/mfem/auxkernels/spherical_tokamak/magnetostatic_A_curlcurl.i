# Magnetostatic vector potential formulationcurl( nu curl(A) ) = J
# B = curl(A)
# A : H(curl) / Nedelec
# B : H(div)  / Raviart-Thomas

[Mesh]
  type = MFEMFileMesh
  file = spherical_tokamak_3D.e
[]

[Problem]
  type = MFEMProblem
[]

[FESpaces]
  [HCurlFESpace]
    type = MFEMVectorFESpace
    fec_type = ND
    fec_order = FIRST
  []
  [HDivFESpace]
    type = MFEMVectorFESpace
    fec_type = RT
    fec_order = CONSTANT
  []

[]
[Variables]
  [A]
    type = MFEMVariable
    fespace = HCurlFESpace
  []
[]
[AuxVariables]
  [J]
    type = MFEMVariable
    fespace = HDivFESpace
  []
  [curlA]
    type = MFEMVariable
    fespace = HDivFESpace
  []
  # B returned from optional second projection solve.
  [B]
    type = MFEMVariable
    fespace = HDivFESpace
  []
[]

[Functions]
  [zero_vector]
    type = MFEMParsedVectorFunction
    expression_x = 0
    expression_y = 0
    expression_z = 0
  []
  # nu = 1/mu0
  [reluctivity]
    type = MFEMParsedFunction
    expression = 795774.7154594767
  []
[]
[Kernels]
  [curlcurl]
    type = MFEMCurlCurlKernel
    variable = A
    coefficient = reluctivity
  []
  [current_source]
    type = MFEMVectorFEDomainLFKernel
    variable = A
    vector_coefficient = J
  []
[]

[AuxKernels]
  [compute_curl_A]
    type = MFEMCurlAux
    variable = curlA
    source = A
    execute_on = FINAL
  []
[]

[BCs]
  [far_field_A]
    type = MFEMVectorTangentialDirichletBC
    variable = A
    boundary = 'FAR_FIELD'
    vector_coefficient = zero_vector
  []
[]

[Solvers]
  [ams]
    type = MFEMHypreAMS
    fespace = HCurlFESpace
    singular = true
  []
  [gmres]
    type = MFEMHypreGMRES
    preconditioner = ams
    l_tol = 1e-10
    l_max_its = 1000
  []

[]

[Executioner]
  type = MFEMSteady
  device = cpu
[]

[MultiApps]
  [B_projection]
    type = FullSolveMultiApp
    input_files = B_projection_curlcurl.i
    execute_on = FINAL
  []
[]


[Transfers]
  # Send curl(A) to projection solve
  [send_curlA]
    type = MultiAppMFEMCopyTransfer
    to_multi_app = B_projection
    source_variables = 'curlA'
    variables = 'curlA_in'
    execute_on = FINAL
  []
  # Bring projected B back
  [pull_B]
    type = MultiAppMFEMCopyTransfer
    from_multi_app = B_projection
    source_variables = 'B_projected'
    variables = 'B'
    execute_on = FINAL
  []
[]

[Outputs]
  [ParaViewDataCollection]
    type = MFEMParaViewDataCollection
    file_base = OutputData/CurlCurlMagnetostatic
    vtk_format = ASCII
  []
[]
