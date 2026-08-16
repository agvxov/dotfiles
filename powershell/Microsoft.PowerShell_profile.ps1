# NOTE:
#  Dear FutureMyself,
#  install this by making your $PROFILE the following:
#     Get-Content "\\wsl.localhost\Ubuntu\home\anon\stow\powershell\Microsoft.PowerShell_profile.ps1" -Raw | Invoke-Expression
#  this is to get around execution policy restrictions.

$env:PAGER = "more"

function prompt {
    $esc  = [char]27
    $blue = "$esc[38;2;0;120;215m"
    $win  = [char]::ConvertFromUtf32(0x1FA9F)
    $path = $PWD.Path -replace '^Microsoft\.PowerShell\.Core\\FileSystem::', ''
    return "$blue$win $path > "
}

function :q { exit }

# --

Get-Content "\\wsl.localhost\Ubuntu\home\anon\Swap\my-notes\cd-rc-bump\cd.ps1" -Raw | Invoke-Expression
