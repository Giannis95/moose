#A-Form frequency-domain solve with transferred E field as RHS
#Equation curl(nu curl A) + j * \omega * \sigma * A = \sigma * E_{laplace}
#where E_drive os the complex e_field (-grad V) tansfereed from the coil. 

freq = 50000 #50kHz
angfreq = 2*3.141592653589793*${freq}

# Conductivities 
sigma_vac = 2.5e2
sigma_coil = 5.8e6
sigma_target = 3.5e6

# Magnetic reluctivities (1/mu)
nu_vac = 1.0e-6
nu_coil = 1.0e-6
nu_target = 1.0e-6

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
    [HCurlFESpace]
        type = MFEMVectorFESpace
        fec_type = ND
        fec_order = FIRST
    []
    [L2FESpace]
        type = MFEMVectorFESpace
        fec_type = L2
        fec_order = CONSTANT
        fec_map = INTEGRAL
  []
[]

[AuxVariables]
    [e_field] #complex (supposingly transferring both components)
        type = MFEMComplexVariable
       # type = MFEMVariable
        fespace = HCurlFESpace
    []
[]

[Variables]
    [a_field]
        type = MFEMComplexVariable
        fespace = HCurlFESpace
    []
    # [e_field]
    #     type = MFEMComplexVariable
    #     fespace = HCurlFESpace
    # []
[]

[Functions]
    # j * \omega * \sigma * A represented as (massCoef + i*loss_coef)*A 
    # with massCoef = 0, lossCoef = \omega * sigma
    [mass_coef_vac]
        type = ParsedFunction
        expression = 0.0
    []
    [loss_coef_vac]
        type = ParsedFunction
        expression = ${angfreq}*${sigma_vac}
    []
    [mass_coef_coil]
        type = ParsedFunction
        expression = 1.0e-6
    []
    [loss_coef_coil]
        type = ParsedFunction
        expression = ${angfreq}*${sigma_coil}
    []
    [mass_coef_target]
        type = ParsedFunction
        expression = 1.0e-6
    []
    [loss_coef_target]
        type = ParsedFunction
        expression = ${angfreq}*${sigma_target}
    []
    [exact_a_field]
        type = ParsedVectorFunction
        expression_x = '0'
        expression_y = '0'
        expression_z = '0'
    []
[]
[BCs]
    [terminal_plane_tangential]
        type = MFEMComplexVectorTangentialDirichletBC
        variable = a_field
        vector_coefficient_real = exact_a_field
        vector_coefficient_imag = 0.0
        # boundary = 'terminal_plane'
    []
[]

[FunctorMaterials]
    #expose \sigma, nu, mass/loss for j*\omega*\sigma
    [vacuum]
        type = MFEMGenericFunctorMaterial
        prop_names = 'massCoef lossCoef sigma nu'
        prop_values = 'mass_coef_vac loss_coef_vac ${sigma_vac} ${nu_vac}'
        block = 'vacuum_region'
    []
    [coil]
        type = MFEMGenericFunctorMaterial
        prop_names = 'massCoef lossCoef sigma nu'
        prop_values = 'mass_coef_coil loss_coef_coil ${sigma_coil} ${nu_coil}'
        block = 'coil'
    []
    [target]
        type = MFEMGenericFunctorMaterial
        prop_names = 'massCoef lossCoef sigma nu'
        prop_values = 'mass_coef_target loss_coef_target ${sigma_target} ${nu_target}'
        block = 'target'
    []
[]


[Kernels]
    [curlcurl]
        type = MFEMComplexKernel
        variable = a_field
        [RealComponent]
            type = MFEMCurlCurlKernel
            coefficient = nu
            block = 'coil target vacuum_region'
        []#[ImagComponent] -> 0 (nu assumed real)
    []

    # j*omega*sigma*A 
    [conductive_mass_complex]
        type = MFEMComplexKernel
        variable = a_field
        [RealComponent]
            type = MFEMVectorFEMassKernel
            coefficient = massCoef # = 0
            block = 'coil target vacuum_region' #for eddy currents in the coil to add coil here ?
        []
        [ImagComponent]
            type = MFEMVectorFEMassKernel
            coefficient = lossCoef # = \omega * \sigma
            block = 'coil target vacuum_region'
        []
    []
    [forcing_field_complex]
        type = MFEMComplexKernel
        variable = a_field
        [RealComponent]
            type = MFEMMixedVectorMassKernel
            trial_variable = e_field
            coefficient = sigma
            block = 'coil target'
        []
        [ImagComponent]
            type = MFEMMixedVectorMassKernel
            trial_variable = e_field
            coefficient = sigma
            # coefficient = 0.0 #RHS purely real; E_laplace is real
            block = 'coil target'
        []
    []
[]

# [Preconditioner]
#   [ams]
#     type = MFEMHypreAMS
#     fespace = HCurlFESpace
#   []
# []

[Solver]
  type = MFEMSuperLU 
#   preconditioner = ams
#   l_tol = 1e-14
#   l_max_its = 200
[]

[Executioner]
    type = MFEMSteady
    device = cpu
[]


[MultiApps]
  [coil_laplace]
    type = FullSolveMultiApp
    input_files = laplace_coil_complex.i
    execute_on = INITIAL
    clone_parent_mesh = true
  []
[]

[Transfers]
  [from_coil]
    type = MultiAppMFEMCopyTransfer
    source_variable = e_field
    variable = e_field
    from_multi_app = coil_laplace
  []
[]

[Outputs]
  [ParaViewDataCollection]
    type = MFEMParaViewDataCollection
    file_base = HIVE/Aform_frequency_domain
    vtk_format = ASCII
  []
[]
