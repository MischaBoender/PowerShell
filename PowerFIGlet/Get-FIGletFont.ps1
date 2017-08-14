function Get-FIGletFont {
    [CmdletBinding(DefaultParameterSetName="Font")]
    param(
        [Parameter(ParameterSetName="Font")]
        [string]$Font="standard",
        [Parameter(ParameterSetName="ListAvailable")]
        [switch]$ListAvailable,
        [string]$Directory=$PWD
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            "ListAvailable" {
                foreach ($FontFile in @(Get-ChildItem -Path $Folder -Filter "*.flf" -Recurse)) {
                    $FontObject = [PSCustomObject]@{
                        Font = $FontFile.BaseName
                        Directory = $FontFile.Directory
                    }
                    $FontObject.PSObject.TypeNames.Insert(0, "MischaBoender.PowerShell.PowerFiglet.FigletFont")
                    Write-Output $FontObject
                }
            }
            "Font" {
                $FontFile = Get-ChildItem -Path $Folder -Filter "$Font.flf" -Recurse | Select-Object -First 1

                if ($FontFile) {
                    $FontFileContent = Get-Content -Path $FontFile.FullName
                    $FontMetadata = @($FontFileContent[0] -split ' ') + @(0,0,0)
                    if ($FontMetadata[0].Substring(0,5) -ne "flf2a") {
                        Write-Error "`"$Font`" is not a Figlet font"    
                    }
                    $CharacterHeight = [int]$FontMetadata[1]
                    $BlankCharacter = [string]$FontMetadata[0].Substring(5,1)
                    $LineEndCharacter = $FontFileContent[[int]$FontMetadata[5] + 1][-1]

                    $FontTable = @{}
                    $FontCharacters = $FontFileContent[([int]$FontMetadata[5] + 1)..($FontFileContent.Length - 1)] -join "`r`n" -split "$LineEndCharacter$LineEndCharacter`r`n"

                    for ($iFontCharacter = 0; $iFontCharacter -lt $FontCharacters.Length; $iFontCharacter++) {
                        $FIGletCharacter = @()
                        $CharacterLines = $FontCharacters[$iFontCharacter] -split "`r`n"
                        foreach ($CharacterLine in $CharacterLines[($CharacterLines.Length - $CharacterHeight)..($CharacterLines.Length - 1)]) {
                            if ($CharacterLine.EndsWith($LineEndCharacter)) {
                                $FIGletCharacter += $CharacterLine.Substring(0, ($CharacterLine.Length - 1)).Replace($BlankCharacter, " ")
                            }
                            else {
                                $FIGletCharacter += $CharacterLine.Replace($BlankCharacter, " ")
                            }
                            
                        }
                        try {
                            if ($CharacterLines.Length -gt $CharacterHeight) {
                                $sCharacterValue = $CharacterLines[0].Split(" ")[0]
                                if ($sCharacterValue.IndexOf("x") -eq 1) {
                                    $iCharacterValue = [convert]::ToInt32($sCharacterValue,16)
                                }
                                else {
                                    $iCharacterValue = [convert]::ToInt32($sCharacterValue,10)
                                }
                                $FontTable.Add($iCharacterValue, $FIGletCharacter)
                            }
                            else {
                                $FontTable.Add($iFontCharacter + 32, $FIGletCharacter)
                            }
                        } catch {}
                    }

                    $FontObject = [PSCustomObject]@{
                        Font = $FontFile.BaseName
                        Directory = $FontFile.Directory
                        BlankCharacter = [string]$FontMetadata[0].Substring(5,1)
                        Height = [int]$FontMetadata[1] 
                        BaseLine = [int]$FontMetadata[2]
                        #MaxLen = [int]$FontMetadata[3]
                        #OldLayout = [int]$FontMetadata[4] 
                        #CommentLines = [int]$FontMetadata[5]
                        RightToLeft = [bool][int]$FontMetadata[6]
                        #FullLayout = [int]$FontMetadata[7]
                        #CodeTagCount = [int]$FontMetadata[8]
                        Comment = $FontFileContent[1..$FontMetadata[5]]
                        Characters = $FontTable
                    }
                    $FontObject.PSObject.TypeNames.Insert(0, "MischaBoender.PowerShell.PowerFiglet.FigletFont")
                    Write-Output $FontObject
                }
                else {
                    Write-Error "Font `"$Font`" not found in `"$Folder`""
                }
            }
        }
    }
}
