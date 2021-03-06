!-----------------------BEGIN NOTICE -- DO NOT EDIT-----------------------------
! NASA GSFC Land surface Verification Toolkit (LVT) V1.0
!-------------------------END NOTICE -- DO NOT EDIT-----------------------------
!BOP
! 
! !MODULE: MOD17A2_obsMod
! \label(MOD17A2_obsMod)
!
! !INTERFACE:
module MOD17A2_obsMod
! 
! !USES:   
  use ESMF

  implicit none

  PRIVATE 
!
! !INPUT PARAMETERS: 
! 
! !OUTPUT PARAMETERS:
!
! !DESCRIPTION: 
! 
! !FILES USED:
!
! !REVISION HISTORY: 
! 23 January 2018   Declan Valters   Initial Specification from MOD16A2 
! 
!EOP
!-----------------------------------------------------------------------------
! !PUBLIC MEMBER FUNCTIONS:
!-----------------------------------------------------------------------------
  PUBLIC :: MOD17A2_obsinit !Initializes structures for reading MOD17A2 data
!-----------------------------------------------------------------------------
! !PUBLIC TYPES:
!-----------------------------------------------------------------------------
  PUBLIC :: MOD17A2obs !Object to hold MOD17A2 observation attributes
!EOP

  type, public :: mod17a2dec
     character*100           :: odir
     integer                 :: nc, nr
     integer, allocatable        :: n11(:)
     real,    allocatable        :: qle(:)
     integer                 :: yr
     integer                 :: mo
     real                    :: gridDesc(50)
     logical                 :: startFlag
  end type mod17a2dec
     
  type(mod17a2dec), save :: MOD17A2Obs(2)

contains
  
!BOP
! 
! !ROUTINE: MOD17A2_obsInit
! \label{MOD17A2_obsInit}
!
! !INTERFACE: 
  subroutine MOD17A2_obsinit(i)
! 
! !USES: 
    use LVT_coreMod,   only : LVT_rc, LVT_Config
    use LVT_histDataMod
    use LVT_logMod
    use LVT_timeMgrMod

    implicit none
!
! !INPUT PARAMETERS: 
    integer,   intent(IN) :: i 
! 
! !OUTPUT PARAMETERS:
!
! !DESCRIPTION: 
!   This subroutine initializes and sets up the data structures required
!   for reading the MOD17A2 data, including the computation of spatial 
!   interpolation weights. The MOD17A2 data is provides in the 
!   EASE grid projection. 
! 
! !FILES USED:
!
! !REVISION HISTORY: 
! 
!EOP

    integer               :: status
    real                  :: cornerlat1, cornerlat2
    real                  :: cornerlon1, cornerlon2

    call ESMF_ConfigGetAttribute(LVT_Config, MOD17A2Obs(i)%odir, &
         label='MOD17A2 data directory: ',rc=status)
    call LVT_verify(status, 'MOD17A2 data directory: not defined')

    call LVT_update_timestep(LVT_rc, 2592000)

    allocate(MOD17A2obs(i)%qle(LVT_rc%lnc*LVT_rc%lnr))

    mod17a2obs(i)%gridDesc = 0
    
    cornerlat1 = max(-59.995,nint((LVT_rc%gridDesc(4)+59.995)/0.01)*0.01-59.995-2*0.01)
    cornerlon1 = max(-179.995,nint((LVt_rc%gridDesc(5)+179.995)/0.01)*0.01-179.995-2*0.01)
    cornerlat2 = min(89.995,nint((LVT_rc%gridDesc(7)+59.995)/0.01)*0.01-59.995+2*0.01)
    cornerlon2 = min(179.995,nint((LVT_rc%gridDesc(8)+179.995)/0.01)*0.01-179.995+2*0.01)
    
    mod17a2obs(i)%nr = nint((cornerlat2-cornerlat1)/0.01)+1
    mod17a2obs(i)%nc = nint((cornerlon2-cornerlon1)/0.01)+1

    allocate(MOD17A2Obs(i)%n11(mod17a2obs(i)%nc*mod17a2obs(i)%nr))

    !filling the items needed by the interpolation library
    mod17a2obs(i)%gridDesc(1) = 0  !input is EASE grid
    mod17a2obs(i)%gridDesc(2) = mod17a2obs(i)%nc
    mod17a2obs(i)%gridDesc(3) = mod17a2obs(i)%nr
    mod17a2obs(i)%gridDesc(4) = cornerlat1
    mod17a2obs(i)%gridDesc(5) = cornerlon1
    mod17a2obs(i)%gridDesc(7) = cornerlat2
    mod17a2obs(i)%gridDesc(8) = cornerlon2
    mod17a2obs(i)%gridDesc(6) = 128
    mod17a2obs(i)%gridDesc(9) = 0.01
    mod17a2obs(i)%gridDesc(10) = 0.01
    mod17a2obs(i)%gridDesc(20) = 64

    call upscaleByAveraging_input(mod17a2obs(i)%gridDesc,&
         LVT_rc%gridDesc,mod17a2obs(i)%nc*mod17a2obs(i)%nr,&
         LVT_rc%lnc*LVT_rc%lnr,mod17a2obs(i)%n11)

    MOD17A2obs(i)%mo = LVT_rc%mo
    MOD17A2obs(i)%yr = -1
    mod17a2obs(i)%startFlag = .true.

    if(LVT_rc%tavgInterval.lt.2592000) then 
       write(LVT_logunit,*) '[ERR] The time averaging interval must be greater than'
       write(LVT_logunit,*) '[ERR] equal to a month since the MOD17A2 data is monthly'
       call LVT_endrun()
    endif

  end subroutine MOD17A2_obsinit


end module MOD17A2_obsMod
