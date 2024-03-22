function Invoke-IntuneBackupdeviceshellScript {
    <#
    .SYNOPSIS
    Backup Intune Device Management Scripts
    
    .DESCRIPTION
    Backup Intune Device Management Scripts as JSON files per Device Management Script to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupdeviceshellScript -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Device Shell Scripts\Script Content")) {
        $null = New-Item -Path "$Path\Device Shell Scripts\Script Content" -ItemType Directory
    }

    # Get all device management scripts
    $deviceshellScripts = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/deviceShellScripts" | Get-MSGraphAllPages

    foreach ($deviceshellScript in $deviceshellScripts) {
        # ScriptContent returns null, so we have to query Microsoft Graph for each script
        $deviceshellScriptObject = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/deviceShellScripts/$($deviceshellScript.Id)"
        $deviceshellScriptFileName = ($deviceshellScriptObject.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $deviceshellScriptObject | ConvertTo-Json | Out-File -LiteralPath "$path\Device Shell Scripts\$deviceshellScriptFileName.json"

        $deviceshellScriptContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($deviceshellScriptObject.scriptContent))
        $deviceshellScriptContent | Out-File -LiteralPath "$path\Device Shell Scripts\Script Content\$deviceshellScriptFileName.ps1"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Device Shell Script"
            "Name"   = $deviceshellScript.displayName
            "Path"   = "Device Shell Scripts\$deviceshellScriptFileName.json"
        }
    }
}