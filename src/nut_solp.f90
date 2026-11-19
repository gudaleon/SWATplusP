      subroutine nut_solp
      
!!    ~ ~ ~ PURPOSE ~ ~ ~
!!    this subroutine calculates the amount of phosphorus lost from the soil
!!    profile in runoff and the movement of soluble phosphorus from the first
!!    to the second layer via percolation

!!    ~ ~ ~ INCOMING VARIABLES ~ ~ ~
!!    name          |units        |definition
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
!!    ihru          |none         |HRU number
!!    surfq(:)      |mm H2O       |surface runoff generated on day in HRU
!!    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
!!    ~ ~ ~ SUBROUTINES/FUNCTIONS CALLED ~ ~ ~
!!    Intrinsic: Min, Max

!!    ~ ~ ~ ~ ~ ~ END SPECIFICATIONS ~ ~ ~ ~ ~ ~

      use basin_module
      use organic_mineral_mass_module
      use aug_p_module, only : aug_ceq, aug_ceq_ready, aug_dop,    &
     &                         aug_dop_conc, hype_ready, aug_diss, &
     &                         spec_ready, tb_checked, tb_on, tb_r, &
     &                         tb_cap, tb_kdet, tb_krep, tb_filt,     &
     &                         tb_cropfc, tb_croph, aug_ms,          &
     &                         aug_tilepp, tb_unit
      use time_module, only : time
      use gwflow_module, only : gw_soil_flag, gw_solute_flag, hru_soil, gwflow_percsol
      use hru_module, only : hru, surqsolp, surfq, i_sep, ihru, qtile, gwsoilp 
      use soil_module
      use output_landscape_module
      use hydrograph_module, only : ht1
      use utils
      
      implicit none 

      integer :: j = 0       !none          |HRU number
      integer :: jj = 0      !none          |counter
      real :: xx = 0.        !none          |variable to hold intermediate calculation
                             !              |result
      real :: vap = 0.       !kg P/ha       |exponential coefficient for P leached and tile flow
      real :: plch = 0.      !kg P/ha       |amount of P leached from soil layer
      real :: dopflx = 0.    !kg P/ha       |DOP flux (HYPE branch only)
      logical :: tb_exist = .false.
      character (len=80) :: tb_title = ""
      real :: tb_infl = 0.   !mm            |infiltration proxy
      real :: tb_qmac = 0.   !mm            |macropore flux
      real :: tb_conc = 0.   !mg/L          |bypass dissolved conc.
      real :: tb_fdiss = 0.  !kg P/ha       |bypass dissolved flux
      real :: tb_kd = 0.     !none          |RZWQM Kd (eq 121)
      real :: tb_ms_soil = 0.!kg/ha         |layer 1 soil mass
      real :: tb_e = 0.      !none          |Jarvis E (eq 133)
      real :: tb_crop = 0.   !none          |crop factor (eq 130)
      real :: tb_msmax = 0.  !none          |Msmax (eq 134)
      real :: tb_k = 0.      !none          |eq 139 rate
      real :: tb_gzd = 0.    !g/m2          |gamma * Zd (eq 143)
      real :: tb_d = 0.      !g/m2          |detachment (eq 129)
      real :: tb_csp = 0.    !g/m3          |sediment conc. (eq 140)
      real :: tb_md = 0.     !g/m2          |delivered sed. (eq 141)
      real :: tb_fmd = 0.    !none          |fraction (eq 143)
      real :: tb_tot1 = 0.   !kg P/ha       |layer 1 total P
      real :: tb_mpp = 0.    !kg P/ha       |particulate bypass flux
      
      integer :: ly = 0      !none       

      j = ihru
      
      !rtb gwflow: add P mass transferred to soil profile from the aquifer
      if(gw_soil_flag.eq.1 .and. gw_solute_flag == 1) then
        do jj = 1,soil(j)%nly
          soil1(j)%mp(jj)%lab = soil1(j)%mp(jj)%lab + hru_soil(j,jj,2) !kg/ha
          gwsoilp(j) = gwsoilp(j) + hru_soil(j,jj,2) !HRU total
        enddo
      endif
      
      hls_d(j)%surqsolp = 0.
      hls_d(j)%lchlabp = 0.
      hls_d(j)%tilelabp = 0.
      
      !Add solp into hru from surface runon to calculations HAK/KDW 7/14/22
      soil1(j)%mp(1)%lab = soil1(j)%mp(1)%lab + ht1%solp !HAK/KDW
      
      !! compute soluble P lost in surface runoff
      if ((bsn_cc%sol_P_model == 2 .or. bsn_cc%sol_P_model == 3 .or. bsn_cc%sol_P_model == 5) .and. aug_ceq_ready) then
        !! augmented branch: export at the equilibrium concentration
        !! published by nut_pminrl3 (mg/L * mm / 100 = kg P/ha)
        surqsolp(j) = aug_ceq(j, 1) * surfq(j) / 100.
      else
      xx = soil(j)%phys(1)%bd * soil(j)%phys(1)%d * hru(j)%nut%phoskd
      surqsolp(j) = soil1(j)%mp(1)%lab  * surfq(j) / (xx + 1.)   !dont merge
      end if
      !!units ==> surqsolp = [kg/ha * mm] / [t/m^3 * mm * m^3/t] = kg/ha
      surqsolp(j) = Min(surqsolp(j), soil1(j)%mp(1)%lab)
      surqsolp(j) = Max(surqsolp(j), 0.)
      hls_d(j)%surqsolp = surqsolp(j)
      soil1(j)%mp(1)%lab = soil1(j)%mp(1)%lab - surqsolp(j)
      !! speciation branch: exports debit the tracked
      !! dissolved mass alongside the labile pool
      if (bsn_cc%sol_P_model == 5 .and. spec_ready) then
        aug_diss(j, 1) = Max(0., aug_diss(j, 1) - surqsolp(j))
      end if

      !! HYPE branch: dissolved organic P in surface runoff,
      !! exported at its tracked concentration and debited from
      !! the branch DOP state; reported within surqsolp so the
      !! standard outputs carry total dissolved export
      if (bsn_cc%sol_P_model == 3 .and. hype_ready) then
        dopflx = Min(aug_dop_conc(j, 1) * surfq(j) / 100.,         &
     &               aug_dop(j, 1))
        dopflx = Max(dopflx, 0.)
        aug_dop(j, 1) = aug_dop(j, 1) - dopflx
        surqsolp(j) = surqsolp(j) + dopflx
        hls_d(j)%surqsolp = hls_d(j)%surqsolp + dopflx
      end if

      !! compute soluble P leaching
      do ly = 1, soil(j)%nly
        vap = 0.
       if (ly /= i_sep(j)) then
         vap = -soil(j)%ly(ly)%prk / (.01 * soil(j)%phys(ly)%st + .1 * hru(j)%nut%pperco *  soil(j)%phys(ly)%bd)
         if ((bsn_cc%sol_P_model == 2 .or. bsn_cc%sol_P_model == 3 .or. bsn_cc%sol_P_model == 5) .and. aug_ceq_ready) then
           plch = aug_ceq(j, ly) * soil(j)%ly(ly)%prk / 100.
         else
           plch = .001 * soil1(j)%mp(ly)%lab * (1. - exp_w(vap))
         end if
         plch = Min(plch, soil1(j)%mp(ly)%lab)
         soil1(j)%mp(ly)%lab = soil1(j)%mp(ly)%lab - plch
         if (bsn_cc%sol_P_model == 5 .and. spec_ready) then
           aug_diss(j, ly) = Max(0., aug_diss(j, ly) - plch)
           if (ly /= soil(j)%nly) aug_diss(j, ly+1) =              &
     &       aug_diss(j, ly+1) + plch
         end if
         if (ly == soil(j)%nly) then
           !! leach p from bottom layer
           hls_d(j)%lchlabp = plch
         else
           !! perc p to next layer
           soil1(j)%mp(ly+1)%lab = soil1(j)%mp(ly+1)%lab + plch
         endif
         !! HYPE branch: DOP percolation, credited to the next
         !! layer's DOP state or counted as leached at the bottom
         if (bsn_cc%sol_P_model == 3 .and. hype_ready) then
           dopflx = Min(aug_dop_conc(j, ly) * soil(j)%ly(ly)%prk   &
     &                  / 100., aug_dop(j, ly))
           dopflx = Max(dopflx, 0.)
           aug_dop(j, ly) = aug_dop(j, ly) - dopflx
           if (ly == soil(j)%nly) then
             hls_d(j)%lchlabp = hls_d(j)%lchlabp + dopflx
           else
             aug_dop(j, ly+1) = aug_dop(j, ly+1) + dopflx
           end if
         end if
         !! tile p
         if (ly == hru(j)%lumv%ldrain) then
           vap = -qtile / (.01 * soil(j)%phys(ly)%st + .1 * hru(j)%nut%pperco *  soil(j)%phys(ly)%bd)
           if ((bsn_cc%sol_P_model == 2 .or. bsn_cc%sol_P_model == 3 .or. bsn_cc%sol_P_model == 5) .and. aug_ceq_ready) then
             plch = aug_ceq(j, ly) * qtile / 100.
           else
             plch = .001 * soil1(j)%mp(ly)%lab * (1. - exp_w(vap))
           end if
           plch = Min(plch, soil1(j)%mp(ly)%lab)
           soil1(j)%mp(ly)%lab = soil1(j)%mp(ly)%lab - plch
           if (bsn_cc%sol_P_model == 5 .and. spec_ready) then
             aug_diss(j, ly) = Max(0., aug_diss(j, ly) - plch)
           end if
           hls_d(j)%tilelabp = plch
           !! HYPE branch: DOP in tile flow
           if (bsn_cc%sol_P_model == 3 .and. hype_ready) then
             dopflx = Min(aug_dop_conc(j, ly) * qtile / 100.,       &
     &                    aug_dop(j, ly))
             dopflx = Max(dopflx, 0.)
             aug_dop(j, ly) = aug_dop(j, ly) - dopflx
             hls_d(j)%tilelabp = hls_d(j)%tilelabp + dopflx
           end if
         endif
        endif
     !rtb gwflow: store phosphorus leaching concentration for gwflow module
     if(bsn_cc%gwflow == 1 .and. gw_solute_flag == 1) then
       gwflow_percsol(j,2) = hls_d(j)%lchlabp
     endif
      end do

      !! Tile-drainage bypass (PORT_DESIGN_tile_v1.md): a
      !! file-activated transport switch, independent of the
      !! pool branch. On the first call, look for the control
      !! file tile_bypass.ctl; if it is absent the model is
      !! exactly stock and this block never runs again.
      if (.not. tb_checked) then
        tb_checked = .true.
        inquire (file = "tile_bypass.ctl", exist = tb_exist)
        if (tb_exist) then
          open (931, file = "tile_bypass.ctl")
          read (931, *) tb_title
          read (931, *) tb_r, tb_cap, tb_kdet, tb_krep, tb_filt, &
     &                  tb_cropfc, tb_croph
          close (931)
          allocate (aug_ms(size(surqsolp)))
          allocate (aug_tilepp(size(surqsolp)))
          aug_ms = -1.
          aug_tilepp = 0.
          tb_unit = 932
          open (tb_unit, file = "tile_bypass_out.txt")
          write (tb_unit, *) "hru year jday diss_kg_ha pp_kg_ha"
          tb_on = .true.
        end if
      end if
      if (tb_on) then
        !! event water: percolation out of the surface layer.
        !! The first build used surface runoff plus percolation
        !! (total infiltration); coupled to the stock routine's
        !! fast desorption refill, that basis formed a pump that
        !! exported the profile's mineral store (about 19 kg/ha
        !! per year of dissolved phosphorus on this test
        !! watershed). The percolation basis is also the
        !! formulation's own: in RZWQM2-P the macropore flux is
        !! a share of the water entering the profile's drainage.
        tb_infl = soil(j)%ly(1)%prk
        tb_fdiss = 0.
        tb_mpp = 0.
        if (tb_infl >= 1.) then   !! stated event threshold
          tb_qmac = Min(tb_r * tb_infl, tb_cap)
          !! dissolved pathway: on branches 2, 3 and 5 the flux
          !! is the branch's published equilibrium concentration
          !! times the macropore flux; on the stock branches and
          !! branch 4 it is the RZWQM2-P leached fraction of the
          !! labile pool (Sadhukhan and Qi 2018 eqs 119-121),
          !! with Kd from eq 121 and the retardation denominator
          !! in metres of water (Kd * soil mass per area + layer
          !! water), exactly as verified in Example 6
          if ((bsn_cc%sol_P_model == 2 .or. bsn_cc%sol_P_model &
     &         == 3 .or. bsn_cc%sol_P_model == 5) .and.           &
     &         aug_ceq_ready) then
            tb_conc = aug_ceq(j, 1)
            tb_fdiss = tb_conc * tb_qmac / 100.
          else
            tb_kd = 0.1 + 0.25 * soil(j)%phys(1)%clay / 100.
            tb_ms_soil = soil(j)%phys(1)%bd * soil(j)%phys(1)%d
            tb_fdiss = soil1(j)%mp(1)%lab * (1. - exp(            &
     &        -tb_qmac / 1000. / (tb_kd * tb_ms_soil / 1000.      &
     &        + soil(j)%phys(1)%st / 1000.)))
          end if
          tb_fdiss = Min(tb_fdiss, soil1(j)%mp(1)%lab)
          tb_fdiss = Max(tb_fdiss, 0.)
          soil1(j)%mp(1)%lab = soil1(j)%mp(1)%lab - tb_fdiss
          if (bsn_cc%sol_P_model == 5 .and. spec_ready) then
            aug_diss(j, 1) = Max(0., aug_diss(j, 1) - tb_fdiss)
          end if
          hls_d(j)%tilelabp = hls_d(j)%tilelabp + tb_fdiss
          !! particulate pathway: Jarvis detachment as verified
          !! in Example 6 (Sadhukhan and Qi 2018 eqs 129-143),
          !! with the day's infiltration proxy as the event
          !! rain and a stated 1 m depth to groundwater
          tb_e = 29. * (1. - 0.72 * exp(-0.05 * tb_infl))
          tb_crop = 1. - tb_cropfc * exp(-0.34 * tb_croph)
          tb_msmax = 0.362 * soil(j)%phys(1)%clay ** (-0.518)
          if (aug_ms(j) < 0.) aug_ms(j) = 0.5 * tb_msmax
          tb_gzd = soil(j)%phys(1)%bd * soil(j)%phys(1)%d
          tb_k = tb_kdet * tb_e * tb_infl * tb_crop               &
     &           + tb_krep / tb_msmax
          aug_ms(j) = (tb_krep + (tb_k * aug_ms(j) - tb_krep)     &
     &                * exp(-tb_k / tb_gzd)) / tb_k
          tb_d = tb_kdet * tb_e * tb_infl * aug_ms(j) * tb_crop
          tb_csp = tb_d / (tb_infl + soil(j)%phys(1)%st)
          tb_md = tb_qmac * tb_csp * exp(-tb_filt * 1.0)
          tb_fmd = tb_md / tb_gzd
          tb_tot1 = soil1(j)%mp(1)%lab + soil1(j)%mp(1)%act       &
     &            + soil1(j)%mp(1)%sta + soil1(j)%hact(1)%p       &
     &            + soil1(j)%hsta(1)%p
          if (tb_tot1 > 0.) then
            tb_mpp = tb_fmd * tb_tot1
            tb_mpp = Min(tb_mpp, tb_tot1)
            soil1(j)%mp(1)%lab = soil1(j)%mp(1)%lab               &
     &        - tb_mpp * soil1(j)%mp(1)%lab / tb_tot1
            soil1(j)%mp(1)%act = soil1(j)%mp(1)%act               &
     &        - tb_mpp * soil1(j)%mp(1)%act / tb_tot1
            soil1(j)%mp(1)%sta = soil1(j)%mp(1)%sta               &
     &        - tb_mpp * soil1(j)%mp(1)%sta / tb_tot1
            soil1(j)%hact(1)%p = soil1(j)%hact(1)%p               &
     &        - tb_mpp * soil1(j)%hact(1)%p / tb_tot1
            soil1(j)%hsta(1)%p = soil1(j)%hsta(1)%p               &
     &        - tb_mpp * soil1(j)%hsta(1)%p / tb_tot1
          end if
          aug_tilepp(j) = aug_tilepp(j) + tb_mpp
        end if
        write (tb_unit, *) j, time%yrc, time%day, tb_fdiss, tb_mpp
      end if

      return
      end subroutine nut_solp