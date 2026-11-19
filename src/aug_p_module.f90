      module aug_p_module
!!
!!    Augmented phosphorus sorption core (P-core worked Example 8).
!!    Parameters of the frozen specification SORPTION_CORE_SPEC_v1:
!!    Langmuir capacity S_max and affinity K_L from Zhou et al.
!!    (2023) Table 6 via Worked Example 3; ageing rates from the
!!    Jones-lineage slow transfer of Worked Example 6. The array
!!    aug_ceq holds each HRU layer's equilibrium solution
!!    concentration (mg/L), published by nut_pminrl3 each day and
!!    read by nut_solp the same day when sol_P_model == 2.
!!
      implicit none

      real, parameter :: aug_smax  = 683.5    !mg/kg   |Langmuir capacity
      real, parameter :: aug_kl    = 0.2      !L/mg    |Langmuir affinity
      real, parameter :: aug_ks    = 0.0006   !/day    |ageing, fast to slow
      real, parameter :: aug_ksrev = 0.00006  !/day    |ageing, slow to fast

      real, allocatable :: aug_ceq(:,:)
      logical :: aug_ceq_ready = .false.

!!    HYPE branch (sol_P_model == 3, nut_pminrl4): parameters
!!    from the HYPE 5.36.0 demo parameter file and compiled
!!    constants, per PORT_DESIGN_hype_v1. aug_solid tracks the
!!    sorbed content (mg/kg) because the kinetic Freundlich
!!    step makes the split history-dependent; aug_dop and
!!    aug_dop_conc hold the branch's dissolved organic
!!    phosphorus state (kg/ha) and its concentration (mg/L).

      real, parameter :: hype_kfr      = 1000.   !L/kg  |Freundlich K
      real, parameter :: hype_nfr      = 0.5     !none  |Freundlich n
      real, parameter :: hype_kadsdes  = 0.065   !/day  |exchange rate
      real, parameter :: hype_minerfp  = 0.02    !/day  |fastP mineral.
      real, parameter :: hype_degradhp = 2.2e-5  !/day  |humusP degrad.
      real, parameter :: hype_pardishp = 1.5e-5  !/day  |humusP to DOP
      real, parameter :: hype_pardisfp = 0.      !/day  |fastP to DOP

      real, allocatable :: aug_solid(:,:)
      real, allocatable :: aug_dop(:,:)
      real, allocatable :: aug_dop_conc(:,:)
      logical, allocatable :: hype_init(:)
      logical :: hype_ready = .false.

!!    RZWQM2-P branch (sol_P_model == 4, nut_pminrl5):
!!    consecutive-day counters for the day-count exchange
!!    factors of Sadhukhan and Qi (2018) equations 81 to 85.

      integer, allocatable :: aug_day_srp(:,:)
      integer, allocatable :: aug_day_dsrp(:,:)
      logical :: rzwqm_ready = .false.

!!    Speciation branch (sol_P_model == 5, nut_pminrl6):
!!    aug_diss tracks the dissolved phosphorus mass (kg/ha)
!!    that the branch's mineral equilibrium governs; the
!!    export routine debits it alongside the labile pool.

      real, allocatable :: aug_diss(:,:)
      logical, allocatable :: spec_init(:)
      logical :: spec_ready = .false.

!!    Tile-drainage bypass (transport switch, all branches;
!!    PORT_DESIGN_tile_v1.md). Activated by the presence of
!!    a control file tile_bypass.ctl in the simulation
!!    folder; absent, the model is exactly stock. aug_ms is
!!    the Jarvis detachable-sediment store per HRU and
!!    aug_tilepp accumulates the particulate bypass flux.

      logical :: tb_checked = .false.
      logical :: tb_on = .false.
      real :: tb_r = 0.3        !macropore share of infiltration
      real :: tb_cap = 10.      !mm/day macropore flux cap
      real :: tb_kdet = 0.1     !Jarvis detachability (Ex. 6)
      real :: tb_krep = 10.     !Jarvis replenishment (Ex. 6)
      real :: tb_filt = 0.5     !filter coefficient (Ex. 6)
      real :: tb_cropfc = 0.3   !crop factor cover (Ex. 6)
      real :: tb_croph = 0.5    !crop factor height (Ex. 6)
      real, allocatable :: aug_ms(:)
      real, allocatable :: aug_tilepp(:)
      integer :: tb_unit = 0

      end module aug_p_module
