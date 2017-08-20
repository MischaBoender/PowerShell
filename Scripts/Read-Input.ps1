function Read-Input {
    param(
        [string]$Prompt,
        [string]$DefaultValue,
        [string[]]$AllowedCharacters,
        [switch]$CaseSensitive,
        [switch]$NoNewLine,
        [hashtable]$SpecialKeysMap,
        [switch]$AllowEscape,
        [switch]$SingleCharacter,
        [string]$ValidatePattern,
        [string]$ValidatePatternTip
    )

    if ($AllowedCharacters) {
        if ($CaseSensitive.IsPresent) {
            $AllowedCharactersRegex = "(?-i)^[$([regex]::Escape([string]::Join('', $AllowedCharacters)))]$"
        }
        else {
            $AllowedCharactersRegex = "(?i)^[$([regex]::Escape([string]::Join('', $AllowedCharacters)))]$"
        }
    }
    else {$AllowedCharactersRegex = "[ -~]+"}

    if ($DefaultValue) {$UserInput = $DefaultValue}
    else {$UserInput = ""}

    $TreatControlCAsInput = [console]::TreatControlCAsInput
    [console]::TreatControlCAsInput = $true

    if (-not [string]::IsNullOrEmpty($Prompt)) {Write-Host "$Prompt`: " -NoNewline}
    Write-Host $UserInput -NoNewline

    do {
        do {
            $Key = [System.Console]::ReadKey($true)
            $KeyString = $Key.KeyChar.ToString()

            if (-not [int][char]$KeyString) {
                $KeyString = $null
            }

            if ($Key.Modifiers -band [consolemodifiers]"control" -and $Key.Key -eq "C") {
                Write-Host ""
                [console]::TreatControlCAsInput = $TreatControlCAsInput
                throw "Control-C"
            }
            elseif ($Key.Key -eq "Enter") {
                break
            }
            elseif ($Key.Key -eq "Backspace") {
                if ($UserInput.Length -gt 0) {
                    $UserInput = $UserInput.Substring(0, $UserInput.Length - 1)
                    Write-Host "`b `b" -NoNewline
                }
            }
            elseif ($Key.Key -eq "Escape" -and $AllowEscape.IsPresent) {
                $UserInput = $null
                break
            }
            elseif ($SpecialKeysMap -and $SpecialKeysMap.ContainsKey($Key.Key.ToString()) -and $UserInput.Length -eq 0) {
                $UserInput = $SpecialKeysMap[$Key.Key.ToString()]
                break
            }
            elseif ($SpecialKeysMap -and $SpecialKeysMap.ContainsKey($Key.KeyChar.ToString()) -and $UserInput.Length -eq 0) {
                $UserInput = $SpecialKeysMap[$Key.KeyChar.ToString()]
                break
            }
            elseif ($KeyString -match $AllowedCharactersRegex) {
                Write-Host $KeyString -NoNewline
                if ($SingleCharacter.IsPresent) {
                    $UserInput = $KeyString
                    break
                }
                else {
                    $UserInput += $KeyString
                }
            }
        } while ($true)

        if (-not ($Key.Key -eq "Escape" -and $AllowEscape.IsPresent) -and ($ValidatePattern -and $UserInput -notmatch $ValidatePattern)) {
            Write-Host ""
            if ($ValidatePatternTip) {Write-Host $ValidatePatternTip -ForegroundColor DarkGray}
            if (-not [string]::IsNullOrEmpty($Prompt)) {Write-Host "$Prompt`: " -NoNewline}
            Write-Host $UserInput -NoNewline
        }
    } while (($ValidatePattern -and $UserInput -notmatch $ValidatePattern) -and -not ($Key.Key -eq "Escape" -and $AllowEscape.IsPresent))

    [console]::TreatControlCAsInput = $TreatControlCAsInput
    if (-not $NoNewLine.IsPresent) {Write-Host ""}
    
    return $UserInput
}
