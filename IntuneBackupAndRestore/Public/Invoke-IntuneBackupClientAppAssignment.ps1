function Invoke-IntuneBackupClientAppAssignment {
    <#
    .SYNOPSIS
    Backup Intune Client App Assignments
    
    .DESCRIPTION
    Backup Intune Client App  Assignments as JSON files per Client App to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupClientAppAssignment -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Create folder if not exists
    if (-not (Test-Path "$Path\Client Apps\Assignments")) {
        $null = New-Item -Path "$Path\Client Apps\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $clientApps = Get-DeviceAppManagement_MobileApps | Get-MSGraphAllPages

    foreach ($clientApp in $clientApps) {
        $assignments = Get-DeviceAppManagement_MobileApps_Assignments -MobileAppId $clientApp.id 
        if ($assignments) {
            Write-Output "Backing Up - Client App - Assignments: $($clientApp.displayName)"
            $fileName = ($clientApp.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json -Depth 3 | Out-File -LiteralPath "$path\Client Apps\Assignments\$($clientApp.id) - $fileName.json"
        }
    }
}