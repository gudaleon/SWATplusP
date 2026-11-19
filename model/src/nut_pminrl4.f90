      subroutine nut_pminrl4

!!    ~ ~ ~ PURPOSE ~ ~ ~
!!    HYPE phosphorus routine ported into SWAT+ (P-core worked
!!    Example 8, HYPE branch), active when bsn_cc%sol_P_model
!!    == 3. Implements the formulation of PORT_DESIGN_hype_v1
!!    from the HYPE 5.36.0 source (npc_soil_proc.f90 and
!!    general_func.f90): first-order pool transformations with
!!    phosphorus mineralization independent of nitrogen, and a
!!    kinetic Freundlich exchange between solution phosphorus
!!    and the sorbed pool. Pool mapping of record: HYPE partP
!!    is the SWAT+ labile pool (the combined solution-plus-
!!    sorbed store, with the sorbed content tracked explicitly
!!    in aug_solid because the kinetic step makes today's split
!!    depend on yesterday's), HYPE fastP is the active pool,
!!    HYPE humusP is the stable humus phosphorus pool, and the
!!    stable mineral pool is outside the port and is not
!!    touched. Dissolved organic phosphorus is branch state in
!!    aug_dop, exported by nut_solp under this branch only.
!!    The equilibrium concentration of the combined store is
!!    published to aug_ceq, so nut_solp exports dissolved
!!    phosphorus at the tracked solution concentration exactly
!!    as it does for the Langmuir branch.

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
      real :: tf = 0.                   !none          |temperature factor
      real :: sf = 0.                   !none          |moisture factor
      real :: sm = 0.                   !mm            |total soil water
      real :: pw = 0.                   !mm            |pore volume
      real :: dissolh = 0.              !kg P/ha       |humusP to DOP
      real :: degradh = 0.              !kg P/ha       |humusP to fastP
      real :: transf = 0.               !kg P/ha       |fastP to solution
      real :: dissolf = 0.              !kg P/ha       |fastP to DOP
      real :: tot = 0.                  !kg P/ha       |combined store
      real :: ceq = 0.                  !mg/L          |equilibrium conc.
      real :: solid_eq = 0.             !mg/kg         |equilibrium solid
      real :: solmass = 0.              !kg P/ha       |solution mass

      j = ihru

      if (.not. aug_ceq_ready) then
        allocate (aug_ceq(size(soil1), 50))
        aug_ceq = 0.
        aug_ceq_ready = .true.
      end if
      if (.not. hype_ready) then
        allocate (aug_solid(size(soil1), 50))
        allocate (aug_dop(size(soil1), 50))
        allocate (aug_dop_conc(size(soil1), 50))
        allocate (hype_init(size(soil1)))
        aug_solid = 0.
        aug_dop = 0.
        aug_dop_conc = 0.
        hype_init = .false.
        hype_ready = .true.
      end if

      hnb_d(j)%lab_min_p = 0.
      hnb_d(j)%act_sta_p = 0.

      do l = 1, soil(j)%nly
        bd = soil(j)%phys(l)%bd
        dpth = soil(j)%phys(l)%d
        stw = soil(j)%phys(l)%st
        soilkg = 1.e4 * bd * dpth
        if (soilkg <= 0.) cycle

        !! first call for this HRU: sorbed content starts at the
        !! equilibrium split of the initial combined store
        if (.not. hype_init(j)) then
          ceq = hype_solve_conc(soil1(j)%mp(l)%lab, stw, soilkg)
          aug_solid(j, l) = hype_kfr * ceq ** hype_nfr
        end if

        !! HYPE environmental factors (general_func.f90)
        tf = hype_tempfactor(soil(j)%phys(l)%tmp)
        sm = stw + soil(j)%phys(l)%wpmm
        pw = (1. - bd / 2.65) * dpth
        sf = hype_moisturefactor(sm, soil(j)%phys(l)%wpmm, pw, dpth)

        !! transformations, in HYPE's retention order
        dissolh = Min(hype_pardishp * tf * sf * soil1(j)%hsta(l)%p, &
     &                soil1(j)%hsta(l)%p)
        soil1(j)%hsta(l)%p = soil1(j)%hsta(l)%p - dissolh
        degradh = Min(hype_degradhp * tf * sf * soil1(j)%hsta(l)%p, &
     &                soil1(j)%hsta(l)%p)
        soil1(j)%hsta(l)%p = soil1(j)%hsta(l)%p - degradh
        soil1(j)%mp(l)%act = soil1(j)%mp(l)%act + degradh
        transf = Min(hype_minerfp * tf * sf * soil1(j)%mp(l)%act,  &
     &               soil1(j)%mp(l)%act)
        soil1(j)%mp(l)%act = soil1(j)%mp(l)%act - transf
        soil1(j)%mp(l)%lab = soil1(j)%mp(l)%lab + transf
        dissolf = Min(hype_pardisfp * tf * sf * soil1(j)%mp(l)%act, &
     &                soil1(j)%mp(l)%act)
        soil1(j)%mp(l)%act = soil1(j)%mp(l)%act - dissolf
        aug_dop(j, l) = aug_dop(j, l) + dissolh + dissolf
        hnb_d(j)%lab_min_p = hnb_d(j)%lab_min_p + transf

        !! kinetic Freundlich exchange on the combined store
        tot = soil1(j)%mp(l)%lab
        if (tot > 0.) then
          ceq = hype_solve_conc(tot, stw, soilkg)
          solid_eq = hype_kfr * ceq ** hype_nfr
          aug_solid(j, l) = aug_solid(j, l) + (solid_eq -          &
     &        aug_solid(j, l)) * (1. - Exp(-hype_kadsdes))
          aug_solid(j, l) = Max(0., Min(aug_solid(j, l),           &
     &        tot * 1.e6 / soilkg))
          solmass = tot - aug_solid(j, l) * soilkg / 1.e6
        else
          aug_solid(j, l) = 0.
          solmass = 0.
        end if
        if (stw > 0.) then
          aug_ceq(j, l) = Max(solmass, 0.) * 100. / stw
          aug_dop_conc(j, l) = aug_dop(j, l) * 100. / stw
        else
          aug_ceq(j, l) = 0.
          aug_dop_conc(j, l) = 0.
        end if
      end do
      hype_init(j) = .true.

      return

      contains

      function hype_tempfactor(temp) result(fcn)
        !! HYPE tempfactor: Q10 = 2 about 20 C, ramped by T/5
        !! below 5 C and zero below 0 C.
        real, intent(in) :: temp
        real :: fcn
        fcn = 2. ** ((temp - 20.) / 10.)
        if (temp < 5.) fcn = fcn * (temp / 5.)
        if (temp < 0.) fcn = 0.
      end function hype_tempfactor

      function hype_moisturefactor(sm, wp, pw, thick) result(fcn)
        !! HYPE moisturefactor with the compiled constants
        !! Satact 0.6, Thetalow 8, Thetaupp 12, Thetapow 1.
        real, intent(in) :: sm, wp, pw, thick
        real :: fcn
        if (thick <= 0.) then
          fcn = 0.
        else if (sm >= pw) then
          fcn = 0.6
        else if (sm <= wp) then
          fcn = 0.
        else
          fcn = Min(1., 0.4 * ((pw - sm) / (0.12 * thick)) + 0.6,   &
     &              ((sm - wp) / (0.08 * thick)))
        end if
      end function hype_moisturefactor

      function hype_solve_conc(tot, stw, soilkg) result(conc)
        !! Solve tot = conc*stw/100 + Kfr*conc**nfr*soilkg/1e6
        !! by bisection on a bracket grown by doubling.
        real, intent(in) :: tot, stw, soilkg
        real :: conc, lo, hi, mid, f
        integer :: it
        if (tot <= 0.) then
          conc = 0.
          return
        end if
        lo = 0.
        hi = 1.
        do it = 1, 80
          f = hi * stw / 100. + hype_kfr * hi ** hype_nfr *         &
     &        soilkg / 1.e6
          if (f >= tot) exit
          hi = hi * 2.
        end do
        do it = 1, 80
          mid = 0.5 * (lo + hi)
          f = mid * stw / 100. + hype_kfr * mid ** hype_nfr *       &
     &        soilkg / 1.e6
          if (f < tot) then
            lo = mid
          else
            hi = mid
          end if
        end do
        conc = 0.5 * (lo + hi)
      end function hype_solve_conc

      end subroutine nut_pminrl4
