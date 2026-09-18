
# with the uknown set us: psi = r * A_theta
#   -div[ (1/(mu0*r)) grad(psi) ] = J_theta
# Magnetic field:
#   B_r = -(1/r) dpsi/dz
#   B_z =  (1/r) dpsi/dr
# The FE Spaces: 
# H1 FIRST  : psi
# ND FIRST  : grad(psi)
# RT CONST  : rotated grad(psi), B
# L2 CONST  : J_theta
# H1(p=1) -> ND(p=1) -> RT(p=0)

# Recover r*B from psi after the first solve
# First:
#       gradPsi = grad(psi)
# Then rotate:rotGradPsi =(-dpsi/dz,dpsi/dr)
#  ==>    rotGradPsi = r * B
#Multiapp structure: 1st read PF currents from CSV file, 2nd solve psi, 3rd solve RT projection to get B
#main application is the projection solve

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

  [HCurlFESpace]
    type = MFEMVectorFESpace
    fec_type = ND
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
  [psi]
    type = MFEMVariable
    fespace = H1FESpace
  []
[]

[AuxVariables]
  #toroidal current density transferred from
  # the libMesh current-reader subapp. (extracted from the optimised bluemira solve)
  [Jtheta]
    type = MFEMVariable
    fespace = L2FESpace
  []
  [gradPsi]
    type = MFEMVariable
    fespace = HCurlFESpace
  []

  # (-dpsi/dz, dpsi/dr)
  # This is r*B, not B
  [rotGradPsi]
    type = MFEMVariable
    fespace = RTFESpace
  []
  # Final B returned from the projection subapp
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

  # Reluctivity / r:  1 / (mu0*r)
  # Here x = R from the 2-D Cubit/Exodus mesh.
  # mu0 = 4*pi*1e-7 H/m
  # 1/mu0 = 795774.7154594767
  [nu_over_r]
    type = MFEMParsedFunction
    expression = 'if(x > r_eps, nu0/x, nu0/r_eps)'
    symbol_names = 'nu0 r_eps'
    symbol_values = '795774.7154594767 1e-6'
  []
[]

# psi equation \int [ 1/(mu0*r) grad(psi).grad(v) ] =\int[ Jtheta v }
# This is the scalar axisymmetric reduction of curl-curl.


[Kernels]
  [psi_operator]
    type = MFEMDiffusionKernel
    variable = psi
    coefficient = nu_over_r
  []
  [source_coils]
    type = MFEMDomainLFKernel
    variable = psi
    coefficient = Jtheta
    # NO block restriction for this test
  []
[]

[AuxKernels]
  [compute_grad_psi]
    type = MFEMGradAux
    variable = gradPsi
    source = psi
    execute_on = TIMESTEP_END
  []
  [compute_rotated_grad_psi]
    type = MFEMNDtoRTAux
    variable = rotGradPsi
    source = gradPsi
    # For the R-Z convention (-dpsi/dz, +dpsi/dr). minus sign
    scale_factor = -1.0
    execute_on = TIMESTEP_END
  []
[]

[BCs]
  [essential]
    type = MFEMScalarDirichletBC
    variable = psi
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
  [B_projection]
    type = FullSolveMultiApp
    input_files = B_projection_psi.i
    execute_on = FINAL
  []

[]

[Transfers]
  # Current reader -> psi solve
  # sourceCoef = r*Jtheta was needed by the Atheta formulation,
  # but not in the psi formulation.

  [pull_currents_from_libmesh]
    type = MultiApplibMeshToMFEMShapeEvaluationTransfer
    from_multi_app = current_reader
    source_variables = 'Jtheta_lm'
    variables = 'Jtheta'
    execute_on = INITIAL
  []
  [send_rotGradPsi_to_projection]
    type = MultiAppMFEMCopyTransfer
    to_multi_app = B_projection
    source_variables = 'rotGradPsi'
    variables = 'rotGradPsi_in'
    execute_on = FINAL
  []
  [pull_B_from_projection]
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
    file_base = OutputData/AxisymmetricTokamakPsi
    scalar_coefficients =
      'cylindrical_r cylindrical_inv_r cylindrical_p cylindrical_z'
    vtk_format = ASCII
  []
[]
