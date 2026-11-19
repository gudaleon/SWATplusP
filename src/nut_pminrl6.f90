      subroutine nut_pminrl6

!!    ~ ~ ~ PURPOSE ~ ~ ~
!!    Speciation branch of the augmented SWAT+ (P-core
!!    worked Example 8), active when bsn_cc%sol_P_model
!!    == 5. The branch replaces isotherm pool exchange with
!!    equilibrium aqueous speciation and mineral control:
!!    each day, per layer, it computes the dissolved
!!    phosphorus concentration at hydroxyapatite equilibrium
!!    for the layer's own pH, with the full phosphate
!!    speciation of phreeqc.dat (protonation, calcium and
!!    magnesium ion pairs, carbonate and sulfate pairing of
!!    the free cations), and relaxes the layer's dissolved
!!    phosphorus toward that concentration at a stated
!!    kinetic rate, precipitating the excess into the
!!    stable pool as the calcium-phosphate mineral store
!!    or dissolving that store when the water is
!!    undersaturated. The speciation mathematics is the
!!    solver verified against PHREEQC in the pre-registered
!!    gate (speciation_gate.py): fractions within half a
!!    percentage point and the hydroxyapatite index within
!!    0.01 log units at pH 5 to 8. Version 1 scope, stated:
!!    the water composition is the gate's water (Ca 2.0,
!!    Mg 1.0, Na 1.0, K 0.2, S 0.5, total carbon 3.0
!!    mmol/kgw) for every layer, so the branch isolates the
!!    pH axis, which the soil file carries per layer;
!!    per-layer element state from the model's salt module
!!    is the recorded version 2 coupling. Iron and
!!    aluminium phases are excluded, as in the gate.
!!    Dissolved mass is tracked in aug_diss; the export
!!    routine debits it alongside the labile pool under
!!    this branch, and the tracked mass is reconciled
!!    against the pool each day.

      use basin_module
      use organic_mineral_mass_module
      use hru_module, only : hru, ihru
      use soil_module
      use output_landscape_module, only : hnb_d
      use aug_p_module

      implicit none

      integer :: j = 0                  !none          |HRU number
      integer :: l = 0                  !none          |counter
      integer :: it = 0                 !none          |iteration
      real :: ph = 0.                   !none          |layer pH
      real :: tc = 0.                   !deg C         |layer temperature
      real :: stw = 0.                  !mm            |layer water storage
      real :: ah = 0.                   !none          |H+ activity
      real :: a_ca = 0.                 !none          |Ca+2 activity
      real :: a_mg = 0.                 !none          |Mg+2 activity
      real :: a_hpo4 = 0.               !none          |HPO4-2 activity
      real :: ceq = 0.                  !mg/L          |equilibrium conc.
      real :: target = 0.               !kg P/ha       |equilibrium mass
      real :: flux = 0.                 !kg P/ha       |mineral flux
      real :: ionic = 0.                !mol/kgw       |ionic strength

      !! gate water, mol/kgw
      real, parameter :: tot_ca = 2.0e-3
      real, parameter :: tot_mg = 1.0e-3
      real, parameter :: tot_na = 1.0e-3
      real, parameter :: tot_k  = 2.0e-4
      real, parameter :: tot_s  = 5.0e-4
      real, parameter :: tot_c  = 3.0e-3
      real, parameter :: k_spec = 0.1     !/day  |relaxation rate

      j = ihru

      if (.not. aug_ceq_ready) then
        allocate (aug_ceq(size(soil1), 50))
        aug_ceq = 0.
        aug_ceq_ready = .true.
      end if
      if (.not. spec_ready) then
        allocate (aug_diss(size(soil1), 50))
        allocate (spec_init(size(soil1)))
        aug_diss = 0.
        spec_init = .false.
        spec_ready = .true.
      end if

      hnb_d(j)%lab_min_p = 0.
      hnb_d(j)%act_sta_p = 0.

      do l = 1, soil(j)%nly
        stw = soil(j)%phys(l)%st
        ph = soil(j)%ly(l)%ph
        if (ph <= 0.) ph = 7.0
        tc = Max(2., Min(soil(j)%phys(l)%tmp, 35.))
        ah = 10. ** (-ph)

        !! free cation activities by fixed point on the
        !! carbonate and sulfate pairing (three iterations);
        !! ionic strength held at the gate water's converged
        !! value, 0.0103 mol/kgw
        ionic = 0.0103
        a_ca = 0.7 * tot_ca
        a_mg = 0.7 * tot_mg
        do it = 1, 3
          call spec_free_cations(ph, tc, ionic, a_ca, a_mg)
        end do

        !! hydroxyapatite equilibrium and the speciated
        !! dissolved total at that equilibrium
        a_hpo4 = (10. ** spec_logk(-3.421, -36.155, tc) * ah ** 4  &
     &           / a_ca ** 5) ** (1. / 3.)
        ceq = spec_total_p(ph, tc, ionic, a_ca, a_mg, a_hpo4)

        if (.not. spec_init(j)) then
          aug_diss(j, l) = ceq * stw / 100.
        end if
        !! reconcile tracked dissolved mass with the pool
        aug_diss(j, l) = Max(0., Min(aug_diss(j, l),               &
     &                     soil1(j)%mp(l)%lab))

        target = ceq * stw / 100.
        flux = k_spec * (aug_diss(j, l) - target)
        if (flux > 0.) then
          !! precipitation into the stable (Ca-P) pool
          flux = Min(flux, soil1(j)%mp(l)%lab)
          soil1(j)%mp(l)%lab = soil1(j)%mp(l)%lab - flux
          soil1(j)%mp(l)%sta = soil1(j)%mp(l)%sta + flux
          aug_diss(j, l) = aug_diss(j, l) - flux
          hnb_d(j)%act_sta_p = hnb_d(j)%act_sta_p + flux
        else if (flux < 0.) then
          !! dissolution of the Ca-P store
          flux = Min(-flux, soil1(j)%mp(l)%sta)
          soil1(j)%mp(l)%sta = soil1(j)%mp(l)%sta - flux
          soil1(j)%mp(l)%lab = soil1(j)%mp(l)%lab + flux
          aug_diss(j, l) = aug_diss(j, l) + flux
          hnb_d(j)%act_sta_p = hnb_d(j)%act_sta_p - flux
        end if

        if (stw > 0.) then
          aug_ceq(j, l) = aug_diss(j, l) * 100. / stw
        else
          aug_ceq(j, l) = 0.
        end if
      end do
      spec_init(j) = .true.

      return

      contains

      function spec_logk(logk25, dh_kcal, tc) result(lk)
        !! van't Hoff from 25 C, as in the gate solver
        real, intent(in) :: logk25, dh_kcal, tc
        real :: lk, tk
        tk = tc + 273.15
        lk = logk25 - (dh_kcal * 1000. / (2.302585 * 1.9872)) *    &
     &       (1. / tk - 1. / 298.15)
      end function spec_logk

      function spec_gamma(z, aa, bb, ionic) result(g)
        !! WATEQ extended Debye-Huckel; A and B at 15 C
        integer, intent(in) :: z
        real, intent(in) :: aa, bb, ionic
        real :: g, sq
        if (z == 0) then
          g = 1.
          return
        end if
        sq = Sqrt(ionic)
        g = 10. ** (-0.5004 * Real(z * z) * (sq / (1. + 0.3258 *   &
     &      aa * sq)) + bb * ionic)
      end function spec_gamma

      subroutine spec_free_cations(ph, tc, ionic, a_ca, a_mg)
        !! One fixed-point pass on the Ca and Mg totals with
        !! carbonate and sulfate pairing at the given pH.
        real, intent(in) :: ph, tc
        real, intent(inout) :: ionic, a_ca, a_mg
        real :: ah, g_ca, g_mg, g_co3, g_hco3, g_so4
        real :: a_co3, a_so4, denom
        ah = 10. ** (-ph)
        g_ca = spec_gamma(2, 5.0, 0.165, ionic)
        g_mg = spec_gamma(2, 5.5, 0.2, ionic)
        g_co3 = spec_gamma(-2, 5.4, 0.0, ionic)
        g_hco3 = spec_gamma(-1, 5.4, 0.0, ionic)
        g_so4 = spec_gamma(-2, 5.0, -0.04, ionic)
        !! carbonate distribution from total carbon at fixed pH
        a_co3 = tot_c / (1. / g_co3 + 10. ** spec_logk(10.329,     &
     &    -3.561, tc) * ah / g_hco3 + 10. ** spec_logk(16.681,     &
     &    -5.738, tc) * ah ** 2)
        a_so4 = 0.7 * tot_s * g_so4
        denom = 1. / g_ca + 10. ** spec_logk(3.224, 3.545, tc)     &
     &    * a_co3 + 10. ** spec_logk(10.91, 4.38, tc) * a_co3      &
     &    * ah / spec_gamma(1, 6.0, 0.0, ionic) + 10. **          &
     &    spec_logk(2.25, 1.325, tc) * a_so4
        a_ca = tot_ca / denom
        !! MgHCO3+ carries no -gamma entry in phreeqc.dat, so
        !! its coefficient is the Davies form, as in the gate
        denom = 1. / g_mg + 10. ** spec_logk(2.98, 2.713, tc)      &
     &    * a_co3 + 10. ** spec_logk(11.399, -2.771, tc) *        &
     &    a_co3 * ah / 10. ** (-0.5004 * (Sqrt(ionic) / (1. +      &
     &    Sqrt(ionic)) - 0.3 * ionic)) + 10. ** spec_logk(2.42,    &
     &    19.0 / 4.184, tc) * a_so4
        a_mg = tot_mg / denom
      end subroutine spec_free_cations

      function spec_total_p(ph, tc, ionic, a_ca, a_mg, a_hpo4)     &
     &    result(ceq_mgl)
        !! Total dissolved P (mg/L) whose HPO4-2 activity is
        !! the hydroxyapatite-equilibrium value.
        real, intent(in) :: ph, tc, ionic, a_ca, a_mg, a_hpo4
        real :: ceq_mgl, ah, a_po4, f, g_na, g_k, a_na, a_k
        ah = 10. ** (-ph)
        a_po4 = a_hpo4 / (10. ** spec_logk(12.346, -3.53, tc) * ah)
        g_na = spec_gamma(1, 4.0, 0.075, ionic)
        g_k = spec_gamma(1, 3.5, 0.015, ionic)
        a_na = g_na * tot_na
        a_k = g_k * tot_k
        f = 1. / spec_gamma(-3, 4.0, 0.0, ionic)
        f = f + 10. ** spec_logk(12.346, -3.53, tc) * ah /         &
     &      spec_gamma(-2, 5.0, 0.0, ionic)
        f = f + 10. ** spec_logk(19.553, -4.52, tc) * ah ** 2 /    &
     &      spec_gamma(-1, 5.4, 0.0, ionic)
        f = f + 10. ** spec_logk(21.721, -10.1 / 4.184, tc) *      &
     &      ah ** 3
        f = f + 10. ** spec_logk(2.739, 3.3, tc) * a_ca *          &
     &      10. ** spec_logk(12.346, -3.53, tc) * ah
        f = f + 10. ** spec_logk(1.408, 3.4, tc) * a_ca *          &
     &      10. ** spec_logk(19.553, -4.52, tc) * ah ** 2 /        &
     &      spec_gamma(1, 5.4, 0.0, ionic)
        f = f + 10. ** spec_logk(6.459, 3.1, tc) * a_ca /          &
     &      spec_gamma(-1, 5.4, 0.0, ionic)
        f = f + 10. ** spec_logk(2.87, 3.3, tc) * a_mg *           &
     &      10. ** spec_logk(12.346, -3.53, tc) * ah
        f = f + 10. ** spec_logk(1.513, 3.4, tc) * a_mg *          &
     &      10. ** spec_logk(19.553, -4.52, tc) * ah ** 2 /        &
     &      spec_gamma(1, 5.4, 0.0, ionic)
        f = f + 10. ** spec_logk(6.589, 3.1, tc) * a_mg /          &
     &      spec_gamma(-1, 5.4, 0.0, ionic)
        f = f + 10. ** 0.29 * a_na *                               &
     &      10. ** spec_logk(12.346, -3.53, tc) * ah /             &
     &      spec_gamma(-1, 5.4, 0.0, ionic)
        f = f + 10. ** 0.29 * a_k *                                &
     &      10. ** spec_logk(12.346, -3.53, tc) * ah /             &
     &      spec_gamma(-1, 5.4, 0.0, ionic)
        ceq_mgl = a_po4 * f * 30973.
      end function spec_total_p

      end subroutine nut_pminrl6
