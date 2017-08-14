function ConvertTo-FIGlet {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true, Position=0)]
        [object]$InputObject,
        [string]$Font="Standard",
        [string]$FontDirectory=$PWD,
        [int]$TerminalWidth=$Host.UI.RawUI.BufferSize.Width,
        [switch]$Center
    )
    
    begin {
        $FIGletFont = Get-FIGletFont -Font $Font -Directory $FontDirectory
        $TerminalWidth += 1
    }
 
    process {
        $OutputLines = @()
        for ($Line=0; $Line -lt $FIGletFont.Height; $Line++) {
            $TotalWidth = 0

            foreach ($Char in [char[]]($InputObject.ToString())) {
                $CharLine = $FIGletFont.Characters[[int]$Char][$Line]
                $TotalWidth += $CharLine.Length
                $OutputLineIndex = [math]::Floor($TotalWidth / $TerminalWidth)
                if (-not $OutputLines[$OutputLineIndex]) {$OutputLines += ,@("")}
                if (-not $OutputLines[$OutputLineIndex][$Line]) {$OutputLines[$OutputLineIndex] += ""}
                $OutputLines[$OutputLineIndex][$Line] += $CharLine
            }
        }

        for ($i=0; $i -lt $OutputLines.Count; $i++) {
            if ($Center.IsPresent) {
                $LineWidth = $OutputLines[$i][0].Length
                $Prepend = ($TerminalWidth - $LineWidth) /2
                Write-Output ([string]::Join("`r`n", ($OutputLines[$i] | %{(" " * $Prepend) + $_})))
            }
            else {
                Write-Output ([string]::Join("`r`n", $OutputLines[$i]))
            }
        }
    }
}
