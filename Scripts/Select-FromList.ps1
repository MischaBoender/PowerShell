<#
.SYNOPSIS
Allows a user to select specific objects from the pipeline

.DESCRIPTION
This function presents the user with a on-screen list of objects and allows to select which objects continue through the pipeline

.PARAMETER InputObject

.PARAMETER Numbered
Use a numbered list

.PARAMETER StartNumber
The start number for a numbered list

.PARAMETER Alphanumeric
Use an alphanumeric (A-Z and 0-9) list. An error will be raised when more than 35 items are added to the list

.PARAMETER UseAmpersandKey
Use the character prefix with an "&" as the key

.PARAMETER NoEnter
Return immediately after an alphanumeric character is typed without waiting for the user to press the enter key

.PARAMETER Multiple
Enable selection of multiple objects

.PARAMETER AllowNone
Allow to continue when no objects have been selected

.PARAMETER DisplayProperty
The name of the object property that will be displayed in the list 

.PARAMETER DisplayAdditionalProperty
The name of the object property that will be displayed in the list on the second row 

.PARAMETER DisplayAdditionalScriptBlock
ScribtBlock that will be executed to get a string value that will be displayed in the list on the second row 

.PARAMETER ReturnProperty
The object property to return to the pipeline. If not specified the InputObject will be returned

.PARAMETER Prompt
Text displayed above the list

.PARAMETER ShowSelected
Print the selection to the screen before returning to the pipeline

.PARAMETER ItemsPerPage
Maximum number of objects to display per page 

.PARAMETER ClearScreen
Clear the console when changing pages

.PARAMETER HighlightColor
The Highlight color to use

.PARAMETER LowlightColor
The Lowlight color to use

.PARAMETER HelpColor
The color to use for the builtin help

.PARAMETER Process
Scriptblock to process selected objects before returning

.PARAMETER ShowListWhenProcessReturnsNull
If the process block returns $null the list selection is restarted

.NOTES
Uses Read-Input function
Created by Mischa@Boender.eu
#>
Function Select-FromList {
    [CmdletBinding(DefaultParameterSetName="Numbered")]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [object[]]$InputObject,
        [Parameter(ParameterSetName="Numbered")]
        [switch]$Numbered,
        [Parameter(ParameterSetName="Numbered")]
        [ValidateNotNullOrEmpty()]
        [int]$StartNumber=1,
        [Parameter(ParameterSetName="Alphanumeric")]
        [switch]$Alphanumeric,
        [Parameter(ParameterSetName="Alphanumeric")]
        [switch]$UseAmpersandKey,
        [Parameter(ParameterSetName="Alphanumeric")]
        [switch]$NoEnter,
        [Alias("ShowProperty")]
        [string]$DisplayProperty,
        [string]$DisplayAdditionalProperty,
        [scriptblock]$DisplayAdditionalScriptBlock,
        [int]$ItemsPerPage = [int]::MaxValue,
        [switch]$ClearScreen,
        [switch]$Multiple,
        [switch]$AllowNone,
        [switch]$AllowEscape,
        [string]$ReturnProperty,
        [string]$Prompt = "Select",
        [switch]$ShowSelected=$false,
        [ConsoleColor]$HighlightColor = [ConsoleColor]::Cyan,
        [ConsoleColor]$LowlightColor = [ConsoleColor]::DarkGray,
        [ConsoleColor]$HelpColor = [ConsoleColor]::Yellow,
        [scriptblock]$Process,
        [ValidateSet("OnNull","Always")]
        [string]$ReturnFromProcess
    )
    
    begin {
        if ($DisplayAdditionalProperty -and $DisplayAdditionalScriptBlock) {
            throw "Parameters `"DisplayAdditionalProperty`" and `"DisplayAdditionalScriptBlock`" cannot be used at the same time"
        }

        $List = [System.Collections.Specialized.OrderedDictionary]@{}
        $Selected = [System.Collections.Specialized.OrderedDictionary]@{}
        
        $Paging = $false
        $CurrentPage = 1

        $AlphanumericKeys = [System.Collections.Specialized.OrderedDictionary]@{}
        0..25 | %{$AlphanumericKeys.Add([string][char]($_ + 65), $null)}
        1..9 | %{$AlphanumericKeys.Add($_.ToString(), $null)}
        $AlphanumericKeys.Add("0", $null)
    }
    
    process {
        foreach ($Object in $InputObject) {
            if ($DisplayProperty) {$OptionText = $Object.$DisplayProperty.ToString()} 
            else {$OptionText = $Object.ToString()}

            if ($DisplayAdditionalProperty) {
                $OptionTextAdditional = $Object.$DisplayAdditionalProperty.ToString()
            }
            elseif ($DisplayAdditionalScriptBlock) {
                try {
                    $OptionTextAdditional = ($Object | .$DisplayAdditionalScriptBlock).ToString()
                }
                catch {
                    throw $_
                }
            }

            switch -wildcard ($PSCmdlet.ParameterSetName) {
                "Numbered*" {
                    $List.Add(
                        ($StartNumber + $List.Count).ToString(),
                        [PSCustomObject]@{
                            OptionText = $OptionText
                            OptionTextAdditional = $OptionTextAdditional
                            Object = $Object
                        }
                    )
                }
                "Alphanumeric*" {
                    $HotKeyRegex = "\&(?<HOTKEY>[A-Za-z0-9])"
                    if ($UseAmpersandKey.IsPresent -and $OptionText -match $HotKeyRegex) {
                        $HotKey = $Matches["HOTKEY"].ToUpper()
                        if (-not $List.Contains($HotKey)) {
                            $List.Add(
                                $HotKey,
                                [PSCustomObject]@{
                                    OptionText = ($OptionText -replace $HotKeyRegex,$Matches["HOTKEY"])
                                    OptionTextAdditional = $OptionTextAdditional
                                    Object = $Object
                                }
                            )
                            continue
                        }
                        else {
                            $OptionText = $OptionText -replace $HotKeyRegex,$Matches["HOTKEY"]
                        }
                    }
                    
                    $KeyFound = $null
                    foreach ($AlphanumericKey in $AlphanumericKeys.Keys) {
                        if (-not $List.Contains($AlphanumericKey)) {
                            $KeyFound = $AlphanumericKey
                            break
                        }
                    }

                    if ($KeyFound) {
                            $List.Add(
                                $KeyFound,
                                [PSCustomObject]@{
                                    OptionText = $OptionText
                                    OptionTextAdditional = $OptionTextAdditional
                                    Object = $Object
                                }
                            )
                    }
                    else {
                        throw "An alphanumeric list can contain a maximum of 36 items (A-Z and 0-9)"
                    }
                }
            }
        }
    }
    
    end {
        switch -wildcard ($PSCmdlet.ParameterSetName) {
            "Numbered*" {
                $AllowedInputCharacters = "0-9"
            }
            "Alphanumeric*" {
                $AllowedInputCharacters = $List.Keys.Clone()
            }
        }

        $SpecialKeysMap = @{}
        $SpecialKeysMap.Add("?", "?")
        
        if ($Multiple.IsPresent) {
            $SpecialKeysMap.Add("*", "*")
        }
        
        if ($ItemsPerPage -ge $List.Count) {
            $ItemsPerPage = $List.Count
        }
        else {  
            $Paging = $true

            $SpecialKeysMap.Add("PageUp", "{PrevPage}")
            $SpecialKeysMap.Add("PageDown", "{NextPage}")
            $SpecialKeysMap.Add("Home", "{FirstPage}")
            $SpecialKeysMap.Add("End", "{LastPage}")

            $SpecialKeysMap.Add("LeftArrow", "{PrevPage}")
            $SpecialKeysMap.Add("RightArrow", "{NextPage}")
            $SpecialKeysMap.Add("UpArrow", "{FirstPage}")
            $SpecialKeysMap.Add("DownArrow", "{LastPage}")
        }

        function ShowList {
            if ($ClearScreen.IsPresent) {Clear-Host}
            Write-Host "`n$Prompt" -ForegroundColor $HighlightColor
            foreach ($Key in ($List.Keys | Select-Object -First $ItemsPerPage -Skip (($CurrentPage - 1) * $ItemsPerPage))) {
                Write-Host "  $Key" -ForegroundColor $HighlightColor -NoNewline
                Write-Host ": $(" " * (($List.Keys | Select-Object -Last 1).Length - $Key.Length))" -NoNewline
                Write-Host $List[$Key].OptionText
                if ($DisplayAdditionalProperty -or $DisplayAdditionalScriptBlock) {
                    Write-Host $(" " * (($List.Keys | Select-Object -Last 1).Length + 4)) -NoNewline
                    Write-Host $List[$Key].OptionTextAdditional -ForegroundColor $LowlightColor
                }
            }
            
            if ($Paging) {
                Write-Host "Page $CurrentPage of $([Math]::Ceiling($List.Count / $ItemsPerPage)) " -NoNewline
                Write-Host " | " -NoNewline -ForegroundColor $LowlightColor
            }
            Write-Host "Press '?' for help" -ForegroundColor $LowlightColor
        }

        function ShowHelp {
            Write-Host ""
            if ($Multiple.IsPresent) {
                Write-Host "Select one or more objects from the list ('*' (de)selects all objects). Leave empty to continue." -ForegroundColor $HelpColor
            }
            else {
                Write-Host "Select an object from the list" -NoNewLine -ForegroundColor $HelpColor
                if (-not $NoEnter.IsPresent) {
                    Write-Host " and press 'Enter' to continue" -NoNewline -ForegroundColor $HelpColor
                }
                if ($AllowEscape.IsPresent) {
                    Write-Host ", or press 'Escape' to exit" -NoNewline -ForegroundColor $HelpColor
                }
                Write-Host "." -ForegroundColor $HelpColor
            }

            if ($Paging) {
                Write-Host "Use PageUp, PageDown, Home, End and Arrow keys to change pages." -ForegroundColor $HelpColor
            }
        }

        do {
            ShowList

            $RestartList = $false
            $Prompt = "Select"
            do {
                if ($Prompt) {
                    Write-Host ""
                    if ($Selected.Count -eq $List.Count) {
                        Write-Host "$($Selected.Count) items selected: ALL" -ForegroundColor $LowlightColor
                    }
                    elseif ($Selected.Count -eq 1) {
                        Write-Host "1 item selected: $([string]::Join(', ', ($Selected.Keys | %{$_})))" -ForegroundColor $LowlightColor
                    }
                    elseif ($Selected.Count -gt 1) {
                        Write-Host "$($Selected.Count) items selected: $([string]::Join(', ', ($Selected.Keys | %{$_})))" -ForegroundColor $LowlightColor
                    }
                    elseif ($Selected.Count -eq 0 -and $Multiple.IsPresent) {
                        Write-Host "No items selected" -ForegroundColor $LowlightColor
                    }
                }

                $ReadInputParameters = @{
                    Prompt = $Prompt
                    NoNewLine = [switch]::Present
                    AllowedCharacters = $AllowedInputCharacters
                    SpecialKeysMap = $SpecialKeysMap
                    AllowEscape = $AllowEscape.IsPresent
                    SingleCharacter = $NoEnter.IsPresent
                }

                $UserInput = Read-Input @ReadInputParameters
                $Prompt = "Select"

                if ($UserInput -and $UserInput.Length -gt 0) {$UserInput = $UserInput.ToUpper()}

                if ($UserInput -eq "?") {
                    ShowHelp
                }
                elseif ($UserInput -eq "*") {
                    if ($Selected.Count -eq $List.Count) {
                        $Selected = [System.Collections.Specialized.OrderedDictionary]@{}
                    }
                    else {
                        $Selected = [System.Collections.Specialized.OrderedDictionary]@{}
                        foreach ($Key in $List.Keys) {$Selected.Add($Key, $List[$Key])}
                    }
                }
                elseif ($UserInput -ne $null -and $Selected.Contains($UserInput)) {
                    $Selected.Remove($UserInput)
                }
                elseif ($UserInput -ne $null -and $List.Contains($UserInput)) {
                    $Selected.Add($UserInput, $List[$UserInput])
                }
                elseif ($Paging -and -not [string]::IsNullOrWhiteSpace($UserInput)) {
                    if ($UserInput -eq "{PrevPage}" -and $CurrentPage -gt 1) {
                        Write-Host "{PrevPage}"
                        $CurrentPage -= 1
                        ShowList
                    }
                    elseif ($UserInput -eq "{NextPage}" -and $CurrentPage -lt [Math]::Ceiling($List.Count / $ItemsPerPage)) {
                        Write-Host "{NextPage}"
                        $CurrentPage = $CurrentPage += 1
                        ShowList
                    }
                    elseif ($UserInput -eq "{FirstPage}" -and $CurrentPage -ne 1) {
                        Write-Host "{FirstPage}"
                        $CurrentPage = 1
                        ShowList
                    }
                    elseif ($UserInput -eq "{LastPage}" -and $CurrentPage -ne [Math]::Ceiling($List.Count / $ItemsPerPage)) {
                        Write-Host "{LastPage}"
                        $CurrentPage = [Math]::Ceiling($List.Count / $ItemsPerPage)
                        ShowList
                    }
                    else {$Prompt = $null}
                }
                elseif ($UserInput -eq $null -and $AllowEscape.IsPresent) {
                    return $null
                }
                elseif ($UserInput -eq "") {
                    $Prompt = $null
                }
                elseif (-not [string]::IsNullOrWhiteSpace($UserInput)) {
                    Write-Host ""
                    Write-Host "Selection incorrect" -NoNewline -ForegroundColor $HighlightColor
                }
            } while (($UserInput -eq "" -and $Selected.Count -eq 0 -and -not $AllowNone.IsPresent) -or -not ([string]::IsNullOrWhiteSpace($UserInput) -or (-not $Multiple.IsPresent -and $Selected.Count -eq 1)))
            Write-Host ""

            if ($Selected.Count -eq 0 -and -not $AllowNone.IsPresent) {
                throw "Nothing selected"
            }
            elseif ($Selected.Count -eq 0 -and $AllowNone.IsPresent) {
                return $null
            }
            else {
                $ReturnObjects = @()

                foreach ($Key in $Selected.Keys) {
                    if ($ShowSelected) {
                        Write-Host "`"$($Selected[$Key].OptionText)`" selected." -ForegroundColor $HighlightColor
                    }

                    if ($ReturnProperty) { 
                        $ReturnObjects += $Selected[$Key].Object.$ReturnProperty
                    }
                    else {
                        $ReturnObjects += $Selected[$Key].Object
                    }
                }

                if ($Process) {
                    $ProcessedObjects = $ReturnObjects | &$Process

                    if ($ReturnFromProcess -eq "OnNull" -and $ProcessedObjects) {
                        return $ProcessedObjects
                    }
                    elseif ($ReturnFromProcess -eq "Always" -and $ProcessedObjects) {
                        Write-Output $ProcessedObjects
                        $RestartList = $true
                        $Selected = [System.Collections.Specialized.OrderedDictionary]@{}
                        Write-Host ""
                    }
                    elseif ($ReturnFromProcess -eq "OnNull") {
                        $RestartList = $true
                        $Selected = [System.Collections.Specialized.OrderedDictionary]@{}
                        Write-Host ""
                    }
                }
                else {
                    return $ReturnObjects
                }
            }
        } while ($RestartList)
    }
}
