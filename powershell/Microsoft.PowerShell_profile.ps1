# NOTE:
#  Dear FutureMyself,
#  install this by making your $PROFILE the following:
#     Get-Content "\\wsl.localhost\Ubuntu\home\anon\stow\powershell\Microsoft.PowerShell_profile.ps1" -Raw | Invoke-Expression
#  this is to get around execution policy restrictions.
if ($PSVersionTable.PSEdition -eq "Core") {
    Import-Module WslInterop
    Import-WslCommand vim
    # XXX not found because of esoteric (cargo bin) path
    #Import-WslCommand gitui
}

# Process title as understood by multiplexers
Write-Host -NoNewline "`e]2;pwsh`a"

$env:PAGER = "more"

function prompt {
    function git_sub_prompt {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            return ""
        }

        if ((git rev-parse --is-inside-work-tree 2>$null) -ne "true") {
            return ""
        }

        $branch = git branch --show-current 2>$null

        if (-not ($branch)) {
            return ""
        }

        return "($branch)"
    }

    $esc  = [char]27
    $blue = "$esc[38;2;0;120;215m"
    $gray = "$esc[38;2;64;64;64m"
    $win  = [char]::ConvertFromUtf32(0x1FA9F)
    $path = $PWD.Path -replace '^Microsoft\.PowerShell\.Core\\FileSystem::', ''
    $git  = git_sub_prompt
    return "$blue$win $path $gray$git$blue> "
}

function :q { exit }

# --

Get-Content "\\wsl.localhost\Ubuntu\home\anon\Swap\my-notes\cd-rc-bump\cd.ps1" -Raw | Invoke-Expression
