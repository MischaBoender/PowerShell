function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Message,
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet("Info","Warning","Error")]
        [string]$Level="Info",
        [string]$Category="Log",
        [ValidateSet("Info","Warning","Error")]
        [string[]]$ToHost,
        [consolecolor]$ForegroundColor=[consolecolor]::White,
        [string]$FilePath
    )

    begin {
        $CallerInfo = @("$env:USERNAME@$env:COMPUTERNAME")
        try {$CalledFrom = (Get-PSCallStack)[1]}
        catch {$CalledFrom = $null}

        if ($CalledFrom) {
            $CallerInfo += $CalledFrom.Location.Replace(" line ","")
            $CallerInfo += $CalledFrom.Command
        }
    }

    process {
        $LogLine = [string]::Format("{0} - {1}:{2} - {3}`r`n{4}", $(Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Category.ToUpper(), $Level.ToUpper(), [string]::Join("/", $CallerInfo), $Message)
        Write-Verbose $LogLine

        if ($ToHost -contains $Level) {
            Write-Host $LogLine -ForegroundColor $ForegroundColor
        }

        if ($FilePath) {
            Out-File -InputObject $LogLine -FilePath $FilePath -Append -ErrorAction SilentlyContinue
        }
    }
}
