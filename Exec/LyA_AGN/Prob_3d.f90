
      subroutine amrex_probinit (init,name,namlen,problo,probhi) bind(c)

      use probdata_module
      use comoving_module
      implicit none

      integer init, namlen
      integer name(namlen)
      double precision problo(3), probhi(3)

      integer untin,i

      namelist /fortin/ comoving_OmM, comoving_OmB, comoving_h, max_num_part

!
!     Build "probin" filename -- the name of file containing fortin namelist.
!     
      integer maxlen
      parameter (maxlen=256)
      character probin*(maxlen)

      if (namlen .gt. maxlen) then
         write(6,*) 'probin file name too long'
         stop
      end if

      do i = 1, namlen
         probin(i:i) = char(name(i))
      end do

!     Read namelists
      untin = 9
      open(untin,file=probin(1:namlen),form='formatted',status='old')
      read(untin,fortin)
      close(unit=untin)

      end

! ::: -----------------------------------------------------------
! ::: This routine is called at problem setup time and is used
! ::: to initialize data on each grid.  
! ::: 
! ::: NOTE:  all arrays have one cell of ghost zones surrounding
! :::        the grid interior.  Values in these cells need not
! :::        be set here.
! ::: 
! ::: INPUTS/OUTPUTS:
! ::: 
! ::: level     => amr level of grid
! ::: time      => time at which to init data             
! ::: lo,hi     => index limits of grid interior (cell centered)
! ::: nstate    => number of state components.  You should know
! :::		   this already!
! ::: state     <=  Scalar array
! ::: delta     => cell size
! ::: xlo,xhi   => physical locations of lower left and upper
! :::              right hand corner of grid.  (does not include
! :::		   ghost region).
! ::: -----------------------------------------------------------
      subroutine ca_initdata(level,time,lo,hi, &
                             ns, state   ,s_l1,s_l2,s_l3,s_h1,s_h2,s_h3, &
                             nd, diag_eos,d_l1,d_l2,d_l3,d_h1,d_h2,d_h3, &
                             delta,xlo,xhi)
      use probdata_module
      use atomic_rates_module, only : XHYDROGEN
      use meth_params_module, only : URHO, UMX, UMZ, UEDEN, UEINT, UFS, &
                                     small_dens, TEMP_COMP, NE_COMP
 
      implicit none
 
      integer level, ns, nd
      integer lo(3), hi(3)
      integer s_l1,s_l2,s_l3,s_h1,s_h2,s_h3
      integer d_l1,d_l2,d_l3,d_h1,d_h2,d_h3
      double precision xlo(3), xhi(3), time, delta(3)
      double precision    state(s_l1:s_h1,s_l2:s_h2,s_l3:s_h3,ns)
      double precision diag_eos(d_l1:d_h1,d_l2:d_h2,d_l3:d_h3,nd)

      integer i,j,k

      ! This is the case where we have compiled with states defined 
      !  but they have only one component each so we fill them this way.
      if (ns.eq.1 .and. nd.eq.1) then

            state(:,:,:,1)    = 0.0d0
         diag_eos(:,:,:,1)    = 0.0d0

      ! This is the regular case with NO_HYDRO = FALSE
      else if (ns.gt.1 .and. nd.eq.2) then

         do k = lo(3), hi(3)
         do j = lo(2), hi(2)
         do i = lo(1), hi(1)

            state(i,j,k,URHO)    = 1.5d0 * small_dens
            state(i,j,k,UMX:UMZ) = 0.0d0

            ! These will both be set later in the call to init_e.
            state(i,j,k,UEINT) = 0.d0
            state(i,j,k,UEDEN) = 0.d0
   
            if (UFS .gt. -1) then
               state(i,j,k,UFS  ) = XHYDROGEN
               state(i,j,k,UFS+1) = (1.d0 - XHYDROGEN)
            end if

            diag_eos(i,j,k,TEMP_COMP) = 1000.d0
            diag_eos(i,j,k,  NE_COMP) =    0.d0
         enddo
         enddo
         enddo

      end if

      end subroutine ca_initdata