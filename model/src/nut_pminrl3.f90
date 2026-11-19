      subroutine nut_pminrl3

!!    ~ ~ ~ PURPOSE ~ ~ ~
!!    Augmented phosphorus mineral routine (P-core worked Example
!!    8), active when bsn_cc%sol_P_model == 2. Implements the
!!    frozen sorption core of SORPTION_CORE_SPEC_v1 inside SWAT+:
!!    the labile pool is the core's fast-sorbed pool plus the
!!    solution mass in equilibrium with it through the Langmuir
!!    isotherm; the active pool is the core's slow pool, exchanging
!!    with the fast pool at the frozen ageing rates; the stable
!!    pool is outside the core's scope and is not touched. Each
!!    day the routine re-splits the labile pool into solution and
!!    fast-sorbed parts at equilibrium, applies the ageing
!!    transfer, and publishes the layer equilibrium concentration
!!    (mg/L) to aug_p_module for nut_solp, which under this branch
!!    exports phosphorus at that concentration instead of through
!!    the linear partition. Boundary fluxes applied by other
!!    routines to the labile pool between calls act on the
!!    combined solution-plus-fast mass; with the fast exchange
!!    rate of the core (21.6/day) that operator split is the
!!    porting approximation recorded in PORT_DESIGN_v1.

      use basin_module
      use organic_mineral_mass_module
      use hru_module, only : hru, ihru
      use soil_module
      use output_landscape_module, only : hnb_d
      use aug_p_module

      implicit none

      integer :: j = 0                  !none          |HRU number
      integer :: l = 0                  !none          |counter
      real :: bd = 0.                   !t/m3          |bulk density
      real :: dpth = 0.                 !mm            |layer thickness
      real :: stw = 0.                  !mm            |layer water storage
      real :: soilkg = 0.               !kg/ha         |layer soil mass
      real :: tot = 0.                  !kg P/ha       |labile pool
      real :: conc = 0.                 !mg/L          |equilibrium conc.
      real :: mf = 0.                   !mg/kg         |fast pool content
      real :: ms = 0.                   !mg/kg         |slow pool content
      real :: age = 0.                  !kg P/ha       |ageing flux

      j = ihru

      if (.not. aug_ceq_ready) then
        allocate (aug_ceq(size(soil1), 50))
        aug_ceq = 0.
        aug_ceq_ready = .true.
      end if

      hnb_d(j)%lab_min_p = 0.
      hnb_d(j)%act_sta_p = 0.

      do l = 1, soil(j)%nly
        bd = soil(j)%phys(l)%bd
        dpth = soil(j)%phys(l)%d
        stw = soil(j)%phys(l)%st
        soilkg = 1.e4 * bd * dpth
        tot = soil1(j)%mp(l)%lab
        if (soilkg <= 0.) cycle

        !! equilibrium split of the labile pool
        conc = aug_solve_conc(tot, stw, soilkg)
        mf = aug_smax * aug_kl * conc / (1. + aug_kl * conc)

        !! ageing exchange with the slow (active) pool
        ms = soil1(j)%mp(l)%act * 1.e6 / soilkg
        age = (aug_ks * mf - aug_ksrev * ms) * soilkg / 1.e6
        age = Max(-soil1(j)%mp(l)%act, Min(age, tot))
        soil1(j)%mp(l)%act = soil1(j)%mp(l)%act + age
        if (soil1(j)%mp(l)%act < 0.) soil1(j)%mp(l)%act = 0.
        soil1(j)%mp(l)%lab = tot - age
        if (soil1(j)%mp(l)%lab < 0.) soil1(j)%mp(l)%lab = 0.

        !! publish the post-ageing equilibrium concentration
        mf = mf - age * 1.e6 / soilkg
        if (mf < 0.) mf = 0.
        if (mf >= aug_smax) mf = aug_smax * 0.9999
        aug_ceq(j, l) = mf / (aug_kl * (aug_smax - mf))

        hnb_d(j)%lab_min_p = hnb_d(j)%lab_min_p + age
      end do

      return

      contains

      function aug_solve_conc(tot, stw, soilkg) result(conc)
        !! Solve tot = conc*stw/100 + M(conc)*soilkg/1e6 for conc,
        !! with M the Langmuir content; bisection on a bracket
        !! grown by doubling (both terms increase with conc).
        real, intent(in) :: tot, stw, soilkg
        real :: conc, lo, hi, mid, f
        integer :: it
        if (tot <= 0.) then
          conc = 0.
          return
        end if
        lo = 0.
        hi = 1.
        do it = 1, 60
          f = hi * stw / 100. + aug_smax * aug_kl * hi /               &
     &        (1. + aug_kl * hi) * soilkg / 1.e6
          if (f >= tot) exit
          hi = hi * 2.
        end do
        do it = 1, 80
          mid = 0.5 * (lo + hi)
          f = mid * stw / 100. + aug_smax * aug_kl * mid /             &
     &        (1. + aug_kl * mid) * soilkg / 1.e6
          if (f < tot) then
            lo = mid
          else
            hi = mid
          end if
        end do
        conc = 0.5 * (lo + hi)
      end function aug_solve_conc

      end subroutine nut_pminrl3
