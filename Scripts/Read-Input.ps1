function Read-Input {
    param(
        $Prompt = "Select",
        [switch]$NoPrompt,
        [switch]$NoNewLine,
        [string[]]$AllowedCharacters = "A-Za-z0-9",
        [string[]]$SpecialCharacters = "",
        [switch]$CaseSensitive,
        [hashtable]$SpecialKeysMap,
        [switch]$AllowEscape
    )

    if ($CaseSensitive.IsPresent) {$RegexModifier = "(?-i)"}
    else {$RegexModifier = "(?i)"}

    if ($SpecialCharacters) {
        $SpecialCharactersRegex = "$RegexModifier^[$([regex]::Escape([string]::Join('', $SpecialCharacters)))]$"
    }
    else {
        $SpecialCharactersRegex = "^$"
    }

    if ($AllowedCharacters) {
        $AllowedCharactersRegex = "$RegexModifier^[$([regex]::Escape([string]::Join('', $AllowedCharacters)))]$"
    }
    else {
        $AllowedCharactersRegex = "^$"
    }

    $TreatControlCAsInput = [console]::TreatControlCAsInput
    $UserInput = ""

    [console]::TreatControlCAsInput = $true
    if (-not $NoPrompt.IsPresent) {Write-Host "$Prompt`: " -NoNewline}
    do {
        $Key = [System.Console]::ReadKey($true)
        $KeyString = $Key.KeyChar.ToString()

        if ($KeyString -match $SpecialCharactersRegex -and $UserInput.Length -eq 0) {
            $UserInput = $KeyString
            Write-Host $KeyString -NoNewline
            break
        }
        elseif ($KeyString -match $AllowedCharactersRegex) {
            $UserInput += $KeyString
            Write-Host $KeyString -NoNewline
        }
        elseif ($Key.Key -eq "Backspace") {
            if ($UserInput.Length -gt 0) {
                $UserInput = $UserInput.Substring(0, $UserInput.Length - 1)
                Write-Host "`b `b" -NoNewline
            }
        }
        elseif ($Key.Key -eq "Enter") {
            break
        }
        elseif ($Key.Modifiers -band [consolemodifiers]"control" -and $Key.Key -eq "C") {
            Write-Host ""
            throw "Control-C"
        }
        elseif ($AllowEscape.IsPresent -and $Key.Key.ToString() -eq "Escape") {
            $UserInput = $null
            break
        }
        elseif ($SpecialKeysMap -and $SpecialKeysMap.ContainsKey($Key.Key.ToString()) -and $UserInput.Length -eq 0) {
            $UserInput = $SpecialKeysMap[$Key.Key.ToString()]
            break
        }
    } while ($true)
    [console]::TreatControlCAsInput = $TreatControlCAsInput
    if (-not $NoNewLine.IsPresent) {Write-Host ""}
    
    return $UserInput
}
