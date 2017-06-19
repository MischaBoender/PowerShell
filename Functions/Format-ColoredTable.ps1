<#
.SYNOPSIS
Formats the output as a table with colored rows

.DESCRIPTION
Formats the output as a table with a per row foreground color based on the scriptblock passed to the color parameter

.PARAMETER InputObject
Specifies the object(s) to format

.PARAMETER Property
Specifies the object properties to display in the output

.PARAMETER AutoSize
Adjust the column size based on ALL the objects

.EXAMPLE
Get-Service | Format-ColoredTable -Green {$_.Status -eq "Running"} -Red {$_.Status -ne "Running"}

.NOTES
Created by Mischa@Boender.eu
#>

function Format-ColoredTable {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [PSObject[]]$InputObject,
        [string[]]$Property,
        [switch]$AutoSize
    )


  DynamicParam {
    $ConsoleColors = [enum]::GetValues([System.ConsoleColor])
    $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
    foreach ($ConsoleColor in $ConsoleColors) {
        $paramAttributes = New-Object -TypeName System.Management.Automation.ParameterAttribute
        $paramAttributes.Mandatory = $false
        $paramAttributes.HelpMessage = 'Color'
        $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($paramAttributes)
        $ColorParameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList ($ConsoleColor, [scriptblock], $attributeCollection)
        $paramDictionary.Add($ConsoleColor, $ColorParameter)
    }
    return $paramDictionary
  }

    begin {
        $psWindow = (Get-Host).UI.RawUI
        $TableHeaderWritten = $false
        $PropertyColumns = [ordered]@{}
        $ColorFilters = [ordered]@{}
        $InputObjects = @()
        $Time = [System.Diagnostics.Stopwatch]::StartNew()
        $OutputDelay = 100

        function GetPropertyColumns {
            param(
                [PSObject[]]$InputObject,
                [string[]]$Property,
                [switch]$ReturnPropertiesOnly
            )

            $FormatTableParams = @{
                InputObject = $InputObject
                AutoSize = [switch]::Present
            }

            if ($Property -and $ReturnPropertiesOnly.IsPresent) {
                $FormatTableParams.Add("Property", $Property)
            }
            elseif ($Property -and -not $ReturnPropertiesOnly.IsPresent) {
                $FormatTableProperties = @()
                foreach ($Prop in $Property) {
                    $FormatTableProperties += @{
                        Label = $Prop
                        Expression = [scriptblock]::Create("`$_.'$Prop'")
                        Alignment = 'Left'
                    }
                }
                $FormatTableParams.Add("Property", $FormatTableProperties)
            }

            $FormatTableOutput = (Format-Table @FormatTableParams | Out-String).Trim().Replace("`r","").Split("`n")
            $PropertyColumns = [ordered]@{}
            $IndexOf = 0
            
            do {
                $NextIndexOf = $FormatTableOutput[1].IndexOf(" -", $IndexOf)

                if ($NextIndexOf -gt 0){$PropertyLength = $NextIndexOf - $IndexOf}
                else {$PropertyLength = $FormatTableOutput[0].Length - $IndexOf}
                $PropertyName = $FormatTableOutput[0].Substring($IndexOf, $PropertyLength).Trim()

                $PropertyColumns.Add($PropertyName, [PSCustomObject]@{
                    Name = $PropertyName
                    FieldLength = $PropertyLength + 1
                })
                $IndexOf = $NextIndexOf + 1
            }
            until ($NextIndexOf -eq -1) 

            if ($ReturnPropertiesOnly.IsPresent) {
                return $PropertyColumns.Keys
            }
            else {
                return $PropertyColumns
            }
        }
        
        function WriteColoredTableHeader {
            param(
                $PropertyColumns
            )

            $TableHeader = ""
            $TableHeaderSeparator = ""
            foreach ($PropertyColumn in $PropertyColumns.GetEnumerator()) {
                $TableHeader += $PropertyColumn.Value.Name
                $TableHeaderSeparator += ("-" * $PropertyColumn.Value.Name.Length)

                $Spacing = (" " * ($PropertyColumn.Value.FieldLength - $PropertyColumn.Value.Name.Length))
                $TableHeader += $Spacing
                $TableHeaderSeparator += $Spacing
            }

            Write-Host $TableHeader
            Write-Host $TableHeaderSeparator

            return $True
        }

        function WriteColoredTableRow {
            param(
                [PSObject]$InputObject,
                $PropertyColumns,
                [consolecolor]$ForegroundColor
            )
            
            $TableRow = ""
            foreach ($PropertyColumn in $PropertyColumns.GetEnumerator()) {
                if ($InputObject.($PropertyColumn.Value.Name) -ne $null) {
                $PropertyValue = $InputObject.($PropertyColumn.Value.Name).ToString()
                }

                if ($PropertyValue.Length -ge $PropertyColumn.Value.FieldLength) {
                    $PropertyValue = $PropertyValue.Substring(0, ($PropertyColumn.Value.FieldLength - 2)) + [string][char]0x2026
                }

                $TableRow += $PropertyValue
                $Spacing = (" " * ($PropertyColumn.Value.FieldLength - $PropertyValue.Length))
                $TableRow += $Spacing
            }

            Write-Host $TableRow -ForegroundColor $ForegroundColor
        }

        function ProcessObject {
            param(
                [PSObject[]]$InputObject,
                $PropertyColumns,
                $ColorFilters
            )
            
            foreach ($Object in $InputObject) {
                $InputObjectWritten = $false
                foreach ($ColorFilter in $ColorFilters.GetEnumerator()) {
                    if (@(Where-Object -InputObject $Object -FilterScript $ColorFilter.Value).Count) {
                        WriteColoredTableRow -InputObject $Object -ForegroundColor $ColorFilter.Key -PropertyColumns $PropertyColumns
                        $InputObjectWritten = $true
                        break
                    }
                }
                if (-not $InputObjectWritten) {
                    WriteColoredTableRow -InputObject $Object -ForegroundColor $psWindow.ForegroundColor -PropertyColumns $PropertyColumns
                }
            }
        }
    }

    process {
        if (-not $ColorFilters.Count -gt 0) {
            foreach ($PSBoundParameter in $PSBoundParameters.GetEnumerator()) {
                if ([enum]::GetNames([consolecolor]) -contains $PSBoundParameter.Key) {
                    $ColorFilters.Add($PSBoundParameter.Key, $PSBoundParameter.Value)
                }
            }
        }

        foreach ($Object in $InputObject) {
            if ($AutoSize.IsPresent) {
                $InputObjects += $Object
            }
            elseif ($Time.IsRunning -and $Time.ElapsedMilliseconds -lt $OutputDelay) {
                $InputObjects += $Object
            }
            elseif ($Time.IsRunning -and $Time.ElapsedMilliseconds -ge $OutputDelay) {
                $InputObjects += $Object

                if (-not $PropertyColumns.Count -gt 0) {
                    $PropertyColumns = GetPropertyColumns -InputObject $InputObjects -Property $(
                        GetPropertyColumns -InputObject $InputObjects -Property $Property -ReturnPropertiesOnly
                    )
                }

                if (-not $TableHeaderWritten) {
                    $TableHeaderWritten = WriteColoredTableHeader -PropertyColumns $PropertyColumns
                }

                ProcessObject -InputObject $InputObjects -PropertyColumns $PropertyColumns -ColorFilters $ColorFilters

                $Time.Stop()
                $InputObject = @()
            }
            else {
                ProcessObject -InputObject $Object -PropertyColumns $PropertyColumns -ColorFilters $ColorFilters
            }
        }
    }

    end {
        if ($AutoSize.IsPresent -or $Time.IsRunning) {
            $Time.Stop()

            if (-not $PropertyColumns.Count -gt 0) {
                $PropertyColumns = GetPropertyColumns -InputObject $InputObjects -Property $(
                     GetPropertyColumns -InputObject $InputObjects -Property $Property -ReturnPropertiesOnly
                )
            }

            if (-not $TableHeaderWritten) {
                $TableHeaderWritten = WriteColoredTableHeader -PropertyColumns $PropertyColumns
            }

            ProcessObject -InputObject $InputObjects -PropertyColumns $PropertyColumns -ColorFilters $ColorFilters
        }
    }
}
