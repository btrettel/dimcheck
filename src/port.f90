! Module for cross-platform portability.
! Standard: Fortran 2018
! Preprocessor: none
! Author: Ben Trettel (<http://trettel.us/>)
! Project: [flt](https://github.com/btrettel/flt)
! License: [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html)

module port

implicit none
private

integer, public, parameter :: PLATFORM_UNKNOWN  = -1
integer, public, parameter :: PLATFORM_UNIXLIKE = 1
integer, public, parameter :: PLATFORM_WINDOWS  = 2

character(len=1), public, parameter :: DIR_SEPS(2) = ["/", achar(92)]
! For Windows (index 2), nvfortran thinks `\` is trying to escape something, so I need to use `achar`.

public :: platform, path_join

contains

function platform()
    ! Similar to sys.platform in Python, but returns an integer instead of a string.
    ! <https://docs.python.org/3/library/sys.html#sys.platform>
    
    ! Based on the following:
    ! <https://fortran-lang.discourse.group/t/how-to-access-a-subdirectory-in-a-win-unix-compatible-way/6630/4>
    
    ! Also see:
    ! <https://en.wikipedia.org/wiki/Path_(computing)#Representations_of_paths_by_operating_system_and_shell>
    
    use prec, only: CL
    use checks, only: assert
    
    integer :: platform
    
    character(len=CL) :: path
    integer           :: forward_slash_index, backslash_index
    
    call get_environment_variable("PATH", path)
    
    forward_slash_index = index(path, DIR_SEPS(PLATFORM_UNIXLIKE))
    backslash_index     = index(path, DIR_SEPS(PLATFORM_WINDOWS))
    
    if ((forward_slash_index > 0) .and. (backslash_index == 0)) then
        platform = PLATFORM_UNIXLIKE
    else if ((forward_slash_index == 0) .and. (backslash_index > 0)) then
        platform = PLATFORM_WINDOWS
    else
        platform = PLATFORM_UNKNOWN
    end if
    
    call assert(platform >= PLATFORM_UNKNOWN, "port (platform): platform is below the range")
    call assert(platform <= PLATFORM_WINDOWS, "port (platform): platform is above the range")
end function platform

function path_join(path_array)
    use prec, only: CL
    use checks, only: assert
    
    character(len=CL), intent(in) :: path_array(:)
    
    character(len=CL) :: path_join
    character(len=1)  :: DIR_SEP
    
    integer :: i_path
    
    call assert(size(path_array) >= 1, "port (path_join): path_array is too short to join")
    call assert(platform() > 0, "port (path_join): unknown platform")
    
    DIR_SEP = DIR_SEPS(platform())
    
    path_join = ""
    do i_path = lbound(path_array, dim=1), ubound(path_array, dim=1) ! SERIAL
        path_join = trim(path_join) // trim(path_array(i_path))
        
        if (i_path /= ubound(path_array, dim=1)) then
            path_join = trim(path_join) // DIR_SEP
        end if
    end do
    
    call assert(len(trim(path_join)) >= 1, "port (path_join): joined path should have a length of at least 1")
end function path_join

end module port
