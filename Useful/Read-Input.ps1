function Read-Input {
    param(
        $Prompt = "Select",
        [string[]]$AllowedCharacters = "A-Za-z0-9",
        [string[]]$SpecialCharacters = "",
        [switch]$CaseSensitive
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
    Write-Host "$Prompt`: " -NoNewline
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
            $UserInput = $null
            break
        }
    }
    while ($true)
    [console]::TreatControlCAsInput = $TreatControlCAsInput
    Write-Host ""

    Return $UserInput
}