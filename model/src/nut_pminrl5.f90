      subroutine nut_pminrl5

!!    ~ ~ ~ PURPOSE ~ ~ ~
!!    RZWQM2-P soil phosphorus formulation ported into SWAT+
!!    (P-core worked Example 8, RZWQM2-P branch), active when
!!    bsn_cc%sol_P_model == 4. Implements the pool exchanges
!!    of Sadhukhan and Qi (2018) section 4, equations 77 to
!!    88, as verified in Worked Example 6: the sorption ratio
!!    PSP from clay, labile phosphorus and soil carbon; the
!!    labile-active imbalance relaxed by day-count power-law
!!    factors, whose consecutive-day counters are the
!!    formulation's memory and are held as branch state; and
!!    the active-stable imbalance relaxed at the report's
!!    slow rates. Scope limits of record (PORT_DESIGN_rzwqm
!!    _v1): the formulation's macropore tile transport is not
!!    ported, because the host has no macropore flux to attach
!!    it to, and its residue-class organic mineralization
!!    stays in Example 6; this branch changes pool dynamics
!!    only and exports through the host's stock partition.
!!    The LabP term of equation 77 follows Example 6's
!!    reading (the labile pool in kg/ha); the mg/kg basis of
!!    the original regression, used by the host's Vadas and
!!    White branch, is recorded as a discrepancy item in the
!!    port design note.

      use basin_module
      use organic_mineral_mass_module
      use hru_module, only : hru, ihru
      use soil_module
      use output_landscape_module, only : hnb_d
      use aug_p_module

      implicit none

      integer :: j = 0                  !none          |HRU number
      integer :: l = 0                  !none          |counter
      real :: clay = 0.                 !%             |clay content
      real :: cbn = 0.                  !%             |organic carbon
      real :: psp = 0.                  !none          |sorption ratio
      real :: pbal = 0.                 !kg P/ha       |labile imbalance
      real :: pbal1 = 0.                !kg P/ha       |stable imbalance
      real :: aa = 0.                   !none          |eq 82 factor
      real :: bb = 0.                   !none          |eq 83 exponent
      real :: base = 0.                 !none          |eq 85 factor
      real :: f = 0.                    !none          |transfer fraction
      real :: flow = 0.                 !kg P/ha       |pool flux

      j = ihru

      if (.not. rzwqm_ready) then
        allocate (aug_day_srp(size(soil1), 50))
        allocate (aug_day_dsrp(size(soil1), 50))
        aug_day_srp = 0
        aug_day_dsrp = 0
        rzwqm_ready = .true.
      end if

      hnb_d(j)%lab_min_p = 0.
      hnb_d(j)%act_sta_p = 0.

      do l = 1, soil(j)%nly
        clay = Max(soil(j)%phys(l)%clay, 0.1)
        cbn = soil(j)%phys(l)%cbn
        psp = -0.045 * Log10(clay) + 0.001 * soil1(j)%mp(l)%lab    &
     &        - 0.035 * cbn + 0.43
        psp = Max(0.01, Min(psp, 0.9))

        !! labile <-> active, equations 78 to 85
        pbal = soil1(j)%mp(l)%lab - soil1(j)%mp(l)%act * psp /     &
     &         (1. - psp)
        if (pbal > 1.e-12) then
          aug_day_srp(j, l) = aug_day_srp(j, l) + 1
          aug_day_dsrp(j, l) = 0
          aa = 0.918 * Exp(-4.603 * psp)
          bb = -0.238 * Log(aa) - 1.126
          f = Max(0., Min(aa * Real(aug_day_srp(j, l)) ** bb, 1.))
          flow = Min(f * pbal, soil1(j)%mp(l)%lab)
          soil1(j)%mp(l)%lab = soil1(j)%mp(l)%lab - flow
          soil1(j)%mp(l)%act = soil1(j)%mp(l)%act + flow
          hnb_d(j)%lab_min_p = hnb_d(j)%lab_min_p + flow
        else if (pbal < -1.e-12) then
          aug_day_dsrp(j, l) = aug_day_dsrp(j, l) + 1
          aug_day_srp(j, l) = 0
          base = -1.08 * psp + 0.79
          f = Max(0., Min(base * Real(aug_day_dsrp(j, l)) **       &
     &        (-0.29), 1.))
          flow = Min(f * Abs(pbal), soil1(j)%mp(l)%act)
          soil1(j)%mp(l)%act = soil1(j)%mp(l)%act - flow
          soil1(j)%mp(l)%lab = soil1(j)%mp(l)%lab + flow
          hnb_d(j)%lab_min_p = hnb_d(j)%lab_min_p - flow
        end if

        !! active <-> stable, equations 86 to 88
        pbal1 = 4. * soil1(j)%mp(l)%act - soil1(j)%mp(l)%sta
        if (pbal1 > 0.) then
          flow = Min(0.0006 * pbal1, soil1(j)%mp(l)%act)
          soil1(j)%mp(l)%act = soil1(j)%mp(l)%act - flow
          soil1(j)%mp(l)%sta = soil1(j)%mp(l)%sta + flow
          hnb_d(j)%act_sta_p = hnb_d(j)%act_sta_p + flow
        else if (pbal1 < 0.) then
          flow = Min(0.00006 * Abs(pbal1), soil1(j)%mp(l)%sta)
          soil1(j)%mp(l)%sta = soil1(j)%mp(l)%sta - flow
          soil1(j)%mp(l)%act = soil1(j)%mp(l)%act + flow
          hnb_d(j)%act_sta_p = hnb_d(j)%act_sta_p - flow
        end if
      end do

      return
      end subroutine nut_pminrl5
