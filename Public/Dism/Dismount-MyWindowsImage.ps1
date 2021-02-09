<#
.SYNOPSIS
Dismounts a Windows image from the directory it is mapped to.

.DESCRIPTION
The Dismount-WindowsImage cmdlet either saves or discards the changes to a Windows image and then dismounts the image.

.LINK
https://osd.osdeploy.com/module/functions/dism/dismount-mywindowsimage

.NOTES
19.11.21 David Segura @SeguraOSD
#>
function Dismount-MyWindowsImage {
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'DismountDiscard'
    )]
    param ( 
        #Specifies the full path to the root directory of the offline Windows image that you will service.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$Path,

        #Discard Changes to the Mounted Windows Image
        [Parameter(ParameterSetName = 'DismountDiscard', Mandatory = $true)]
        [switch]$Discard,

        #Save Changes to the Mounted Windows Image
        [Parameter(ParameterSetName = 'DismountSave', Mandatory = $true)]
        [switch]$Save
    )

    begin {
        #===================================================================================================
        #   Require Admin Rights
        #===================================================================================================
        if ((Get-OSDGather -Property IsAdmin) -eq $false) {
            Write-Warning "$($MyInvocation.MyCommand) requires Admin Rights ELEVATED"
            Break
        }
        #===================================================================================================
        #   Get-WindowsImage Mounted
        #===================================================================================================
        if ($null -eq $Path) {
            $Path = (Get-WindowsImage -Mounted | Select-Object -Property Path).Path
        }
    }
    process {
        foreach ($Input in $Path) {
            #===================================================================================================
            #   Path
            #===================================================================================================
            $MountPath = (Get-Item -Path $Input | Select-Object FullName).FullName
            Write-Verbose "Path: $MountPath"
            #===================================================================================================
            #   Validate Mount Path
            #===================================================================================================
            if (-not (Test-Path $Input -ErrorAction SilentlyContinue)) {
                Write-Warning "Dismount-MyWindowsImage: Unable to locate Mounted WindowsImage at $Input"
                Break
            }
            #===================================================================================================
            #   Dismount-WindowsImage
            #===================================================================================================
            if ($Discard.IsPresent) {
                if ($PSCmdlet.ShouldProcess($Input, "Dismount-MyWindowsImage -Discard")) {
                    Dismount-WindowsImage -Path $Input -Discard | Out-Null
                }
            }
            if ($Save.IsPresent) {
                if ($PSCmdlet.ShouldProcess($Input, "Dismount-MyWindowsImage -Save")) {
                    Dismount-WindowsImage -Path $Input -Save | Out-Null
                }
            }
        }
    }
    end {}
}