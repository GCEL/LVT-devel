!-----------------------BEGIN NOTICE -- DO NOT EDIT-----------------------------
! NASA GSFC Land surface Verification Toolkit (LVT) V1.0
!-------------------------END NOTICE -- DO NOT EDIT-----------------------------
!BOP
! 
! !MODULE: AGRMET_dataMod
!
! !INTERFACE:
! 
! !USES:   
!
! !INPUT PARAMETERS: 
! 
! !OUTPUT PARAMETERS:
!
! !DESCRIPTION: 
!
!   This subroutine provides the observation plugin for reading the 
!   operational AGRMET output from the Air Force Weather Agency (AFWA)
!   This plugin only handles the LIS-style outputs and not the old
!   AGRMET grib files at 1/2 deg.
! 
! !FILES USED:
!
! !REVISION HISTORY: 
!  09 Dec 2010   Sujay Kumar  Initial Specification
! 
!EOP
!
module AGRMET_dataMod
! !USES: 
  use ESMF

  implicit none

  PRIVATE 
!-----------------------------------------------------------------------------
! !PUBLIC MEMBER FUNCTIONS:
!-----------------------------------------------------------------------------
  PUBLIC :: AGRMET_datainit
!-----------------------------------------------------------------------------
! !PUBLIC TYPES:
!-----------------------------------------------------------------------------
  PUBLIC :: AGRMETdata
!EOP
  type, public :: agrmetdatadec
     character*100           :: odir
     real*8                  :: changetime1,changetime2
     real, allocatable           :: rlat(:)
     real, allocatable           :: rlon(:)
     integer, allocatable        :: n11(:)
     integer, allocatable        :: n12(:)
     integer, allocatable        :: n21(:)
     integer, allocatable        :: n22(:)     
     real,    allocatable        :: w11(:)
     real,    allocatable        :: w12(:)
     real,    allocatable        :: w21(:)
     real,    allocatable        :: w22(:)

     character*20           :: security_class
     character*20           :: distribution_class
     character*20           :: data_category
     character*20           :: area_of_data

     integer                 :: nc
     integer                 :: nr
     type(ESMF_TimeInterval) :: ts
  end type agrmetdatadec

  type(agrmetdatadec),save:: agrmetdata(2)

contains
  
!BOP
! 
! !ROUTINE: AGRMET_dataInit
! \label{AGRMET_dataInit}
!
! !INTERFACE: 
  subroutine AGRMET_datainit(i)
! 
! !USES: 
    use LVT_coreMod
    use LVT_logMod
    use LVT_histDataMod
    use LVT_timeMgrMod

    implicit none
!
! !INPUT PARAMETERS: 
! 
! !OUTPUT PARAMETERS:
!
! !DESCRIPTION: 
!
!   This subroutine initializes and sets up the data structures required
!   for reading the AGRMET data, including the setup of spatial interpolation
!   weights. 
! 
! !FILES USED:
!
! !REVISION HISTORY: 
! 
!EOP
!BOP
! !ARGUMENTS: 
    integer,   intent(IN) :: i 
!EOP
    integer              :: status
    real                 :: gridDesci(50)
    integer              :: updoy, yr1,mo1,da1,hr1,mn1,ss1
    real                 :: upgmt
    character*10         :: time
    integer              :: ts

    call ESMF_ConfigGetAttribute(LVT_Config, agrmetdata(i)%odir, &
         label='AGRMET data directory:', rc=status)
    call LVT_verify(status, 'AGRMET data directory: not defined')

    call ESMF_ConfigGetAttribute(LVT_Config, agrmetdata(i)%security_class, &
         label='AGRMET data security class name:', rc=status)
    call LVT_verify(status, 'AGRMET data security class name: not defined')

    call ESMF_ConfigGetAttribute(LVT_Config, agrmetdata(i)%distribution_class, &
         label='AGRMET data distribution class name:', rc=status)
    call LVT_verify(status, 'AGRMET data distribution class name: not defined')

    call ESMF_ConfigGetAttribute(LVT_Config, agrmetdata(i)%data_category, &
         label='AGRMET data category name:', rc=status)
    call LVT_verify(status, 'AGRMET data category name: not defined')

    call ESMF_ConfigGetAttribute(LVT_Config, agrmetdata(i)%area_of_data, &
         label='AGRMET data area of data:', rc=status)
    call LVT_verify(status, 'AGRMET data area of data: not defined')

    call ESMF_ConfigGetAttribute(LVT_Config, time, &
         label='AGRMET data output interval:', rc=status)
    call LVT_verify(status, 'AGRMET data output interval: not defined')

    call LVT_parseTimeString(time,ts)

    call LVT_update_timestep(LVT_rc,ts)

    allocate(agrmetdata(i)%rlat(LVT_rc%lnc*LVT_rc%lnr))
    allocate(agrmetdata(i)%rlon(LVT_rc%lnc*LVT_rc%lnr))

    allocate(agrmetdata(i)%n11(LVT_rc%lnc*LVT_rc%lnr))
    allocate(agrmetdata(i)%n12(LVT_rc%lnc*LVT_rc%lnr))
    allocate(agrmetdata(i)%n21(LVT_rc%lnc*LVT_rc%lnr))
    allocate(agrmetdata(i)%n22(LVT_rc%lnc*LVT_rc%lnr))
    allocate(agrmetdata(i)%w11(LVT_rc%lnc*LVT_rc%lnr))
    allocate(agrmetdata(i)%w12(LVT_rc%lnc*LVT_rc%lnr))
    allocate(agrmetdata(i)%w21(LVT_rc%lnc*LVT_rc%lnr))
    allocate(agrmetdata(i)%w22(LVT_rc%lnc*LVT_rc%lnr))

    gridDesci = 0 
    gridDesci(1) = 0 
    gridDesci(2) = 1440
    gridDesci(3) = 600
    gridDesci(4) = -59.875
    gridDesci(5) = -179.875
    gridDesci(7) = 89.875
    gridDesci(8) = 179.875
    gridDesci(6) = 128
    gridDesci(9) = 0.250
    gridDesci(10) = 0.250
    gridDesci(20) = 64

    agrmetdata(i)%nc = 1440
    agrmetdata(i)%nr =  600
    call bilinear_interp_input(gridDesci,LVT_rc%gridDesc,&
         LVT_rc%lnc*LVT_rc%lnr, &
         agrmetdata(i)%rlat, agrmetdata(i)%rlon,&
         agrmetdata(i)%n11, agrmetdata(i)%n12, &
         agrmetdata(i)%n21, agrmetdata(i)%n22, & 
         agrmetdata(i)%w11, agrmetdata(i)%w12, &
         agrmetdata(i)%w21, agrmetdata(i)%w22)

#if 0
    yr1 = 2002     !grid update time
    mo1 = 5
    da1 = 29
    hr1 = 12
    mn1 = 0; ss1 = 0
    call LVT_date2time(agrmetdata(i)%changetime1,updoy,upgmt,&
         yr1,mo1,da1,hr1,mn1,ss1 )
    
    yr1 = 2002     !grid update time
    mo1 = 11
    da1 = 6
    hr1 = 12
    mn1 = 0; ss1 = 0
    call LVT_date2time(agrmetdata(i)%changetime2,updoy,upgmt,&
         yr1,mo1,da1,hr1,mn1,ss1 )
#endif

    call ESMF_TimeIntervalSet(agrmetdata(i)%ts, s = 10800, &
         rc=status)
    call LVT_verify(status)

  end subroutine AGRMET_datainit


end module AGRMET_dataMod
