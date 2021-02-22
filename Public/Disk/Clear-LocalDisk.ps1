function Clear-LocalDisk {
    <#
    .SYNOPSIS
    Clears Local Disks (non-USB) for OS Deployment in WinPE
    Disks are Initialized in MBR or GPT PartitionStyle

    .DESCRIPTION
    Clears Local Disks (non-USB) for OS Deployment in WinPE
    Disks are Initialized in MBR or GPT PartitionStyle

    .PARAMETER InputObject
    Get-OSDDisk or Get-LocalDisk Object

    .PARAMETER DiskNumber
    Specifies the disk number for which to get the associated Disk object
    Alias = Disk, Number

    .PARAMETER Force
    Required for execution
    Alias = F

    .PARAMETER Force
    Required for execution
    Alias = F

    .PARAMETER PartitionStyle
    Override the automatic Partition Style of the Initialized Disk
    EFI Default = GPT
    BIOS Default = MBR
    Alias = PS

    .EXAMPLE
    Clear-LocalDisk
    Displays Get-Help Clear-LocalDisk -Examples

    .EXAMPLE
    Clear-LocalDisk -Force
    Interactive.  Prompted to Confirm Clear-Disk for each Local Disk

    .EXAMPLE
    Clear-LocalDisk -Force -Confirm:$false
    Non-Interactive. Clears all Local Disks without being prompted to Confirm

    .LINK
    https://osd.osdeploy.com/module/disk/clear-localdisk

    .NOTES
    21.2.22     Initial Release
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [Object[]]$InputObject,

        [Alias('Disk','Number')]
        [uint32]$DiskNumber,

        [Alias('I')]
        [switch]$Initialize,

        [Alias('PS')]
        [ValidateSet('GPT','MBR')]
        [string]$PartitionStyle,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('F')]
        [switch]$Force
    )
    #======================================================================================================
    #	PSBoundParameters
    #======================================================================================================
    $IsConfirmPresent   = $PSBoundParameters.ContainsKey('Confirm')
    $IsForcePresent     = $PSBoundParameters.ContainsKey('Force')
    $IsVerbosePresent   = $PSBoundParameters.ContainsKey('Verbose')
    #======================================================================================================
    #	Enable Verbose if Force parameter is not $true
    #======================================================================================================
    if ($IsForcePresent -eq $false) {
        $VerbosePreference = 'Continue'
    }
    #======================================================================================================
    #	OSD Module and Command Information
    #======================================================================================================
    $OSDVersion = $($MyInvocation.MyCommand.Module.Version)
    Write-Verbose "OSD $OSDVersion $($MyInvocation.MyCommand.Name)"
    #======================================================================================================
    #	Get Local Disks (not USB and not Virtual)
    #======================================================================================================
    $GetLocalDisk = $null
    if ($InputObject) {
        $GetLocalDisk = $InputObject
    } else {
        $GetLocalDisk = Get-LocalDisk -IsBoot:$false | Sort-Object Number
    }
    #======================================================================================================
    #	Get DiskNumber
    #======================================================================================================
    if ($PSBoundParameters.ContainsKey('DiskNumber')) {
        $GetLocalDisk = $GetLocalDisk | Where-Object {$_.DiskNumber -eq $DiskNumber}
    }
    #======================================================================================================
    #	OSDisks must be large enough for a Windows installation
    #======================================================================================================
    <# $GetLocalDisk = $GetLocalDisk | Where-Object {$_.Size -gt 15GB} #>
    #======================================================================================================
    #	-PartitionStyle
    #======================================================================================================
    if (-NOT ($PSBoundParameters.ContainsKey('PartitionStyle'))) {
        if (Get-OSDGather -Property IsUEFI) {
            Write-Verbose "IsUEFI = $true"
            $PartitionStyle = 'GPT'
        } else {
            Write-Verbose "IsUEFI = $false"
            $PartitionStyle = 'MBR'
        }
    }
    Write-Verbose "PartitionStyle = $PartitionStyle"
    #======================================================================================================
    #	Get-Help
    #======================================================================================================
    if ($IsForcePresent -eq $false) {
        Get-Help $($MyInvocation.MyCommand.Name) -Examples
    }
    #======================================================================================================
    #	Display Disk Information
    #======================================================================================================
    $GetLocalDisk | Select-Object -Property Number, BusType, MediaType, FriendlyName, PartitionStyle, NumberOfPartitions | Format-Table
    
    if ($IsForcePresent -eq $false) {
        Break
    }
    #======================================================================================================
    #	IsWinPE
    #======================================================================================================
    if (-NOT (Get-OSDGather -Property IsWinPE)) {
        Write-Warning "WinPE is required for execution"
        Break
    }
    #======================================================================================================
    #	IsAdmin
    #======================================================================================================
    if (-NOT (Get-OSDGather -Property IsAdmin)) {
        Write-Warning "Administrative Rights are required for execution"
        Break
    }
    #======================================================================================================
    #	Clear-Disk
    #======================================================================================================
    $ClearLocalDisk = @()
    foreach ($Item in $GetLocalDisk) {
        if ($PSCmdlet.ShouldProcess(
            "Disk $($Item.Number) $($Item.BusType) $($Item.MediaType) $($Item.FriendlyName) [$($Item.PartitionStyle) $($Item.NumberOfPartitions) Partitions]",
            "Clear-Disk"
            )){
            Write-Warning "Cleaning Disk $($Item.Number) $($Item.BusType) $($Item.MediaType) $($Item.FriendlyName) [$($Item.PartitionStyle) $($Item.NumberOfPartitions) Partitions]"
            Diskpart-Clean -DiskNumber $Item.Number

            if ($Initialize -eq $true) {
                Write-Warning "Initializing $PartitionStyle Disk $($Item.Number) $($Item.BusType) $($Item.MediaType) $($Item.FriendlyName)"
                $Item | Initialize-Disk -PartitionStyle $PartitionStyle
            }
            
            $ClearLocalDisk += Get-OSDDisk -Number $Item.Number
        }
    }
    $ClearLocalDisk | Select-Object -Property Number, BusType, MediaType, FriendlyName, PartitionStyle, NumberOfPartitions | Format-Table
    #======================================================================================================
}