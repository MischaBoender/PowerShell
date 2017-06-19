<#
.SYNOPSIS
This function will never execute successfully

.DESCRIPTION
This function will never execute successfully because it requires a switch parameter that does not exist

.EXAMPLE
Use-LessIntelliSense -Notexist

.NOTES
Created by Mischa@Boender.eu
Created in April 2015 during a PowerShell training
#>
function Use-LessIntelliSense
{
  [CmdletBinding()]
  param()
  
  dynamicparam {
    $randomParam = (Get-Random -InputObject (65..90|ForEach-Object -Process {
          [char]$_ 
    }) -Count 1) + 
    [string]::Concat((Get-Random -InputObject (97..122|ForEach-Object -Process {
            [char]$_
    }) -Count 7))
    $attributes = New-Object -TypeName System.Management.Automation.ParameterAttribute
    $attributes.Mandatory = $true
    $attributes.HelpMessage = 'This parameter does not exist'
    $attributes.ParameterSetName = 'Random'
    $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
    $attributeCollection.Add($attributes)
    $random = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList ($randomParam, [switch], $attributeCollection)
    $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
    $paramDictionary.Add($randomParam, $random)
    return $paramDictionary
  }

  process {
      Write-Host "This will never happen..."
      return $true
  }
}