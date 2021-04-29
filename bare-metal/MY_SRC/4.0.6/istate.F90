MODULE istate
   !!======================================================================
   !!                     ***  MODULE  istate  ***
   !! Ocean state   :  initial state setting
   !!=====================================================================
   !! History :  OPA  !  1989-12  (P. Andrich)  Original code
   !!            5.0  !  1991-11  (G. Madec)  rewritting
   !!            6.0  !  1996-01  (G. Madec)  terrain following coordinates
   !!            8.0  !  2001-09  (M. Levy, M. Ben Jelloul)  istate_eel
   !!            8.0  !  2001-09  (M. Levy, M. Ben Jelloul)  istate_uvg
   !!   NEMO     1.0  !  2003-08  (G. Madec, C. Talandier)  F90: Free form, modules + EEL R5
   !!             -   !  2004-05  (A. Koch-Larrouy)  istate_gyre 
   !!            2.0  !  2006-07  (S. Masson)  distributed restart using iom
   !!            3.3  !  2010-10  (C. Ethe) merge TRC-TRA
   !!            3.4  !  2011-04  (G. Madec) Merge of dtatem and dtasal & suppression of tb,tn/sb,sn 
   !!            3.7  !  2016-04  (S. Flavoni) introduce user defined initial state 
   !!----------------------------------------------------------------------

   !!----------------------------------------------------------------------
   !!   istate_init   : initial state setting
   !!   istate_uvg    : initial velocity in geostropic balance
   !!----------------------------------------------------------------------
   USE oce            ! ocean dynamics and active tracers 
   USE dom_oce        ! ocean space and time domain 
   USE daymod         ! calendar
   USE divhor         ! horizontal divergence            (div_hor routine)
   USE dtatsd         ! data temperature and salinity   (dta_tsd routine)
   USE dtauvd         ! data: U & V current             (dta_uvd routine)
   USE domvvl          ! varying vertical mesh
   USE iscplrst        ! ice sheet coupling
   USE wet_dry         ! wetting and drying (needed for wad_istate)
   USE usrdef_istate   ! User defined initial state
   !
   USE in_out_manager  ! I/O manager
   USE iom             ! I/O library
   USE lib_mpp         ! MPP library
   USE restart         ! restart

   IMPLICIT NONE
   PRIVATE

   PUBLIC   istate_init   ! routine called by step.F90

   !! * Substitutions
#  include "vectopt_loop_substitute.h90"
   !!----------------------------------------------------------------------
   !! NEMO/OCE 4.0 , NEMO Consortium (2018)
   !! $Id: istate.F90 10068 2018-08-28 14:09:04Z nicolasmartin $
   !! Software governed by the CeCILL license (see ./LICENSE)
   !!----------------------------------------------------------------------
CONTAINS

   SUBROUTINE istate_init
      !!----------------------------------------------------------------------
      !!                   ***  ROUTINE istate_init  ***
      !! 
      !! ** Purpose :   Initialization of the dynamics and tracer fields.
      !!----------------------------------------------------------------------
      INTEGER ::   ji, jj, jk   ! dummy loop indices
!!gm see comment further down
      REAL(wp), ALLOCATABLE, DIMENSION(:,:,:,:) ::   zuvd    ! U & V data workspace
!!gm end
      !!----------------------------------------------------------------------
      !
      IF(lwp) WRITE(numout,*)
      IF(lwp) WRITE(numout,*) 'istate_init : Initialization of the dynamics and tracers'
      IF(lwp) WRITE(numout,*) '~~~~~~~~~~~'

      CALL day_init       ! need this to read initial conditions with interpolation

!!gm  Why not include in the first call of dta_tsd ?  
!!gm  probably associated with the use of internal damping...
                     CALL dta_tsd_init        ! Initialisation of T & S input data
!!gm to be moved in usrdef of C1D case
!      IF( lk_c1d )   CALL dta_uvd_init        ! Initialization of U & V input data
!!gm

      rhd  (:,:,:  ) = 0._wp   ;   rhop (:,:,:  ) = 0._wp      ! set one for all to 0 at level jpk
      rn2b (:,:,:  ) = 0._wp   ;   rn2  (:,:,:  ) = 0._wp      ! set one for all to 0 at levels 1 and jpk
      tsa  (:,:,:,:) = 0._wp                                   ! set one for all to 0 at level jpk
      rab_b(:,:,:,:) = 0._wp   ;   rab_n(:,:,:,:) = 0._wp      ! set one for all to 0 at level jpk
#if defined key_agrif
      ua   (:,:,:  ) = 0._wp   ! used in agrif_oce_sponge at initialization
      va   (:,:,:  ) = 0._wp   ! used in agrif_oce_sponge at initialization    
#endif

      IF( ln_rstart ) THEN                    ! Restart from a file
         !                                    ! -------------------
         CALL rst_read                        ! Read the restart file
         IF (ln_iscpl)       CALL iscpl_stp   ! extrapolate restart to wet and dry
         CALL day_init                        ! model calendar (using both namelist and restart infos)
         !
      ELSE                                    ! Start from rest
         !                                    ! ---------------
         numror = 0                           ! define numror = 0 -> no restart file to read
         neuler = 0                           ! Set time-step indicator at nit000 (euler forward)
         CALL day_init                        ! model calendar (using both namelist and restart infos)
         !                                    ! Initialization of ocean to zero
         !
         IF( ln_tsd_init ) THEN               
            CALL dta_tsd( nit000, tsb )       ! read 3D T and S data at nit000
            !
            sshb(:,:)   = 0._wp               ! set the ocean at rest
            IF( ll_wd ) THEN
               sshb(:,:) =  -ssh_ref  ! Added in 30 here for bathy that adds 30 as Iterative test CEOD 
               !
               ! Apply minimum wetdepth criterion
               !
               DO jj = 1,jpj
                  DO ji = 1,jpi
                     IF( ht_0(ji,jj) + sshb(ji,jj)  < rn_wdmin1 ) THEN
                        sshb(ji,jj) = tmask(ji,jj,1)*( rn_wdmin1 - (ht_0(ji,jj)) )
                     ENDIF
                  END DO
               END DO 
            ENDIF 
            ub  (:,:,:) = 0._wp
            vb  (:,:,:) = 0._wp  
            !
         ELSE                                 ! user defined initial T and S
            CALL usr_def_istate( gdept_b, tmask, tsb, ub, vb, sshb  )         
         ENDIF
         tsn  (:,:,:,:) = tsb (:,:,:,:)       ! set now values from to before ones
         sshn (:,:)     = sshb(:,:)   
         un   (:,:,:)   = ub  (:,:,:)
         vn   (:,:,:)   = vb  (:,:,:)
         hdivn(:,:,jpk) = 0._wp               ! bottom divergence set one for 0 to zero at jpk level
         CALL div_hor( 0 )                    ! compute interior hdivn value  
!!gm                                    hdivn(:,:,:) = 0._wp

!!gm POTENTIAL BUG :
!!gm  ISSUE :  if sshb /= 0  then, in non linear free surface, the e3._n, e3._b should be recomputed
!!             as well as gdept and gdepw....   !!!!! 
!!      ===>>>>   probably a call to domvvl initialisation here....


         !
!!gm to be moved in usrdef of C1D case
!         IF ( ln_uvd_init .AND. lk_c1d ) THEN ! read 3D U and V data at nit000
!            ALLOCATE( zuvd(jpi,jpj,jpk,2) )
!            CALL dta_uvd( nit000, zuvd )
!            ub(:,:,:) = zuvd(:,:,:,1) ;  un(:,:,:) = ub(:,:,:)
!            vb(:,:,:) = zuvd(:,:,:,2) ;  vn(:,:,:) = vb(:,:,:)
!            DEALLOCATE( zuvd )
!         ENDIF
         !
!!gm This is to be changed !!!!
!         ! - ML - sshn could be modified by istate_eel, so that initialization of e3t_b is done here
!         IF( .NOT.ln_linssh ) THEN
!            DO jk = 1, jpk
!               e3t_b(:,:,jk) = e3t_n(:,:,jk)
!            END DO
!         ENDIF
!!gm 
         ! 
      ENDIF 
      ! 
      ! Initialize "now" and "before" barotropic velocities:
      ! Do it whatever the free surface method, these arrays being eventually used
      !
      un_b(:,:) = 0._wp   ;   vn_b(:,:) = 0._wp
      ub_b(:,:) = 0._wp   ;   vb_b(:,:) = 0._wp
      !
!!gm  the use of umsak & vmask is not necessary below as un, vn, ub, vb are always masked
      DO jk = 1, jpkm1
         DO jj = 1, jpj
            DO ji = 1, jpi
               un_b(ji,jj) = un_b(ji,jj) + e3u_n(ji,jj,jk) * un(ji,jj,jk) * umask(ji,jj,jk)
               vn_b(ji,jj) = vn_b(ji,jj) + e3v_n(ji,jj,jk) * vn(ji,jj,jk) * vmask(ji,jj,jk)
               !
               ub_b(ji,jj) = ub_b(ji,jj) + e3u_b(ji,jj,jk) * ub(ji,jj,jk) * umask(ji,jj,jk)
               vb_b(ji,jj) = vb_b(ji,jj) + e3v_b(ji,jj,jk) * vb(ji,jj,jk) * vmask(ji,jj,jk)
            END DO
         END DO
      END DO
      !
      un_b(:,:) = un_b(:,:) * r1_hu_n(:,:)
      vn_b(:,:) = vn_b(:,:) * r1_hv_n(:,:)
      !
      ub_b(:,:) = ub_b(:,:) * r1_hu_b(:,:)
      vb_b(:,:) = vb_b(:,:) * r1_hv_b(:,:)
      !
   END SUBROUTINE istate_init

   !!======================================================================
END MODULE istate
