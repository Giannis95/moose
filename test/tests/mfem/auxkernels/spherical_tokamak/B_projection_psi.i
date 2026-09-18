# ============================================================
# Second solve:Find B_h in RT such that \int r B_h . w_h dOmega = integral rotGradPsi . w_h dOmega
# where: rotGradPsi = (-dpsi/dz, dpsi/dr) so -> 
#       B_r = -(1/r) dpsi/dz
#       B_z =  (1/r) dpsi/dr
[Mesh]
  type = MFEMFileMesh
  file = spherical_tokamak_axisymmetric2D.e
[]
[Problem]
  type = MFEMProblem
[]
[FESpaces]
  [RTFESpace]
    type = MFEMVectorFESpace
    fec_type = RT
    fec_order = CONSTANT
  []
[]

[Variables]
  [B_projected]
    type = MFEMVariable
    fespace = RTFESpace
  []
[]

[AuxVariables] #r*B field transferred from parent
  [rotGradPsi_in]
    type = MFEMVariable
    fespace = RTFESpace
  []
[]

[Functions]
  [cylindrical]
    type = MFEMCoordinateTransformations
    coord_type = RZ
    inv_r_eps = 1e-6
  []

[]

[Kernels]
  [B_weighted_mass]
    type = MFEMVectorFEMassKernel
    variable = B_projected
    coefficient = cylindrical_r
  []
  [B_projection_rhs]
    type = MFEMVectorFEDomainLFKernel
    variable = B_projected
    vector_coefficient = rotGradPsi_in
  []
[]

# No B boundary condition for this projection.

[Solvers]
  [PCG]
    type = MFEMHyprePCG
    l_tol = 1e-10
    l_max_its = 1000
  []
[]
[Executioner]
  type = MFEMSteady
  device = cpu
[]

[Outputs]
  [ParaViewDataCollection]
    type = MFEMParaViewDataCollection
    file_base = OutputData/BProjectionPsi
    scalar_coefficients =
      'cylindrical_r cylindrical_inv_r cylindrical_p cylindrical_z'
    vtk_format = ASCII
  []
[]