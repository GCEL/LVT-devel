!-----------------------BEGIN NOTICE -- DO NOT EDIT-----------------------------
! NASA GSFC Land surface Verification Toolkit (LVT) V1.0
!-------------------------END NOTICE -- DO NOT EDIT-----------------------------
#include "LVT_misc.h"
!BOP
! 
! !ROUTINE: readGL6JULESObs
! \label{readGL6JULESObs}
!
! !INTERFACE: 
subroutine readGL6JULESObs(source)
! 
! !USES:   
  use ESMF
  use LVT_coreMod
  use LVT_timeMgrMod
  use LVT_logMod
  use LVT_histDataMod
  use GL6JULES_obsMod
  use map_utils

#if(defined USE_NETCDF3 || defined USE_NETCDF4)
  use netcdf
#endif

  implicit none
!
! !INPUT PARAMETERS: 
  integer, intent(in) :: source
! 
! !OUTPUT PARAMETERS:
!
! !DESCRIPTION: 
! 
!  NOTES: 
!   This is a test implementation using the GL6 JULES model output
!   
! 
! !FILES USED:
!
! !REVISION HISTORY: 
!  8 July 2015: Sujay Kumar, Initial Specification
!  18 Jan 2018: Declan Valters, change JULES lat lon ingestion
! 
!EOP

  character*100           :: filename
  logical                 :: file_exists
  integer                 :: nid, ios
  integer                 :: qleid, timeid, tId, xId, yId, gppid
  integer                 :: latid, lonid
  integer                 :: nx, ny
  real,  allocatable      :: qle(:,:,:), lat(:), lon(:), gpp(:,:,:)
  integer                 :: c,r,t,kk, tindex
  integer                 :: yr, mo, da, hr, mn, ss
  type(ESMF_Time)         :: currTime
  type(ESMF_TimeInterval) :: ts
  integer                 :: status
  integer                 :: stn_row, stn_col
  real                    :: col,row
  real                    :: varfield(LVT_rc%lnc,LVT_rc%lnr)


#if (defined USE_NETCDF3 || defined USE_NETCDF4)  
  if(GL6JULESobs(source)%yr.ne.LVT_rc%dyr(source)) then      

     GL6JULESobs(source)%yr = LVT_rc%dyr(source)

     filename = GL6JULESobs(source)%odir
     inquire(file=trim(filename),exist=file_exists) 
     
     if(file_exists) then 
        write(LVT_logunit,*) '[INFO] Reading GL6JULES LH file ',trim(filename)
        
        ios = nf90_open(path=trim(filename),mode=NF90_NOWRITE,ncid=nid)
        call LVT_verify(ios, 'Error opening file '//trim(filename))
        
        ! dimensions
        ios = nf90_inq_dimid(nid,'x',xId)
        call LVT_verify(ios, 'Error nf90_inq_dimid: x')
        
        ios = nf90_inquire_dimension(nid,xId, len=nx)
        call LVT_verify(ios, 'Error nf90_inquire_dimension: x')
        
        ios = nf90_inq_dimid(nid,'y',yId)
        call LVT_verify(ios, 'Error nf90_inq_dimid: y')
        
        ios = nf90_inquire_dimension(nid,yId, len=ny)
        call LVT_verify(ios, 'Error nf90_inquire_dimension: y')
        
        ios = nf90_inq_dimid(nid,'time',tId)
        call LVT_verify(ios, 'Error nf90_inq_dimid: t')  ! ought to say 'time'
        
        ios = nf90_inquire_dimension(nid,tId, len=GL6JULESobs(source)%ntimes)
        call LVT_verify(ios, 'Error nf90_inquire_dimension: time')
        
        !allocate(qle(nx,ny,GL6JULESobs(source)%ntimes))
        allocate(gpp(nx,ny,GL6JULESobs(source)%ntimes))
        allocate(lat(ny))
        allocate(lon(nx))
        
        if(allocated(GL6JULESobs(source)%qle_c) .or. & 
           allocated(GL6JULESobs(source)%gpp_c)) then 
           deallocate(GL6JULESobs(source)%time_val)
        endif
        if(allocated(GL6JULESobs(source)%qle_c)) then
           deallocate(GL6JULESobs(source)%qle_c)
        endif
        if(allocated(GL6JULESobs(source)%gpp_c)) then
           deallocate(GL6JULESobs(source)%gpp_c)
        endif
        allocate(GL6JULESobs(source)%qle_c(LVT_rc%lnc,LVT_rc%lnr,GL6JULESobs(source)%ntimes))
        allocate(GL6JULESobs(source)%gpp_c(LVT_rc%lnc,LVT_rc%lnr,GL6JULESobs(source)%ntimes))
        allocate(GL6JULESobs(source)%time_val(GL6JULESobs(source)%ntimes))
        GL6JULESobs(source)%qle_c = LVT_rc%udef
        GL6JULESobs(source)%qle_c = LVT_rc%udef
        GL6JULESobs(source)%time_val = LVT_rc%udef

        !values
        ios = nf90_inq_varid(nid,'latitude',latid)
        call LVT_verify(ios, 'Error nf90_inq_varid: latitude')
        
        ios = nf90_get_var(nid,latid, lat)
        call LVT_verify(ios, 'Error nf90_get_var: latitude')
        
        ios = nf90_inq_varid(nid,'longitude',lonid)
        call LVT_verify(ios, 'Error nf90_inq_varid: longitude')
        
        ios = nf90_get_var(nid,lonid, lon)
        call LVT_verify(ios, 'Error nf90_get_var: longitude')
        
        !ios = nf90_inq_varid(nid,'latent_heat',qleid)
        !call LVT_verify(ios, 'Error nf90_inq_varid: latent_heat')
        
        !ios = nf90_get_var(nid,qleid, qle)
        !call LVT_verify(ios, 'Error nf90_get_var: latent_heat')

        ! DV - ingest GPP
        ios = nf90_inq_varid(nid,'GPP', gppid)
        call LVT_verify(ios, 'Error nf90_inq_varid: gpp')
        
        ios = nf90_get_var(nid, gppid, gpp)
        call LVT_verify(ios, 'Error nf90_get_var: gpp')


        ios = nf90_inq_varid(nid,'time',timeid)
        call LVT_verify(ios, 'Error nf90_inq_varid: time')
        
        ios = nf90_get_var(nid,timeid,GL6JULESobs(source)%time_val)
        call LVT_verify(ios, 'Error nf90_get_var: time')
        
        ios = nf90_close(nid)
        call LVT_verify(ios, 'Error in nf90_close')
       
        print *, "INGESTION of arrays complete, ntimes: ", GL6JULESobs(source)%ntimes
        !map to the LVT grid           
        do t=1,GL6JULESobs(source)%ntimes
           do c=1,nx
              do r=1,ny
                 call latlon_to_ij(LVT_domain%lvtproj, lat(r), lon(c),&
                      col,row)
                 stn_col = nint(col)
                 stn_row = nint(row)
                 !print *, "CONVERTED LAT LON TO IJ." 
                 if(stn_col.ge.1.and.stn_col.le.LVT_rc%lnc.and.&
                      stn_row.ge.1.and.stn_row.le.LVT_rc%lnr) then 
                    !GL6JULESobs(source)%qle_c(stn_col,stn_row,t) = &
                    !     qle(c,r,t)
                    GL6JULESobs(source)%gpp_c(stn_col,stn_row,t) = &
                          gpp(c,r,t)
                    !print *, "COPIED GPP ARRAY TO gpp_c."
                 endif
              enddo
           enddo
        enddo

     endif
  end if
#endif

  call ESMF_TimeIntervalSet(ts, s=3600,rc=status)
  call LVT_verify(status, 'error in ESMF_TimeIntervalSet')

  varfield = LVT_rc%udef
  currTime = GL6JULESobs(source)%refTime
  tindex = -1

  do t=1,GL6JULESobs(source)%ntimes
     currTime = currTime +ts

     call ESMF_TimeGet(currTime, yy=yr, mm=mo, dd=da, &
          h = hr, m = mn, s = ss, calendar = LVT_calendar, &
          rc=status)
     call LVT_verify(status, 'error in ESMF_TimeSet in readGL6JULESobs')
     
     if(yr.eq.LVT_rc%dyr(source).and.&
          mo.eq.LVT_rc%dmo(source).and.&
          da.eq.LVT_rc%dda(source).and.&
          hr.eq.LVT_rc%dhr(source).and.&
          mn.eq.LVT_rc%dmn(source).and.&
          ss.eq.LVT_rc%dss(source)) then 
        tindex = t
        exit
     endif
  enddo
  if(tindex.ne.-1) then 
     write(LVT_logunit,*) '[INFO] Reading GL6JULES data '
     do r=1, LVT_rc%lnr
        do c=1, LVT_rc%lnc
           varfield(c,r) = GL6JULESobs(source)%gpp_c(c,r,tindex)
        enddo
     enddo
  else
     varfield = LVT_rc%udef
  endif
  !call LVT_logSingleDataStreamVar(LVT_MOC_QLE,source,varfield,vlevel=1,units="W/m2")
  call LVT_logSingleDataStreamVar(LVT_MOC_GPP,source,varfield,vlevel=1,units="gC/m2")
  
end subroutine readGL6JULESObs

