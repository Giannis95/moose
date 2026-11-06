
# Projection of curl(A) into RT space
[Mesh]
  type = MFEMFileMesh
  file = spherical_tokamak_3D.e
[]

[Problem]
  type = MFEMProblem
[]

[FESpaces]
  [HDivFESpace]
    type = MFEMVectorFESpace
    fec_type = RT
    fec_order = CONSTANT
  []
[]

[Variables]
  [B_projected]
    type = MFEMVariable
    fespace = HDivFESpace
  []
[]

[AuxVariables]
  [curlA_in]
    type = MFEMVariable
    fespace = HDivFESpace
  []
[]

[Kernels]
  [B_mass]
    type = MFEMVectorFEMassKernel
    variable = B_projected
  []
  [B_rhs]
    type = MFEMVectorFEDomainLFKernel
    variable = B_projected
    vector_coefficient = curlA_in
  []
[]


[Solvers]
  [boomeramg]
    type = MFEMHypreBoomerAMG
  []
  [pcg]
    type = MFEMHyprePCG
    preconditioner = boomeramg
    l_tol = 1e-12
    l_max_its = 500
  []
[]

[Executioner]
  type = MFEMSteady
  device = cpu
[]
[Outputs]
  [ParaViewDataCollection]
    type = MFEMParaViewDataCollection
    file_base = OutputData/BProjectionCurlCurl
    vtk_format = ASCII
  []
[]
