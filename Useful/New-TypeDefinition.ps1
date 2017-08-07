<#
.SYNOPSIS
Create a new Type definition

.DESCRIPTION
Create a new Type definition and optionally save it as CS or PS1 file

.PARAMETER Properties
HashTable containing the properties and their types

.PARAMETER Namespace

.PARAMETER Class

.PARAMETER FilePath

.PARAMETER PowerShell

.PARAMETER CSharp

.EXAMPLE
$MyType = @{
    Name = [string]
    Number = [int]
    Bool = [bool]
}
New-TypeDefinition -Properties $MyType -Namespace "MischaBoender.PowerShell" -Class MyType

.NOTES
Created by Mischa@Boender.eu
#>

function New-TypeDefinition {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Properties,
        [Parameter(Mandatory=$true)]
        [string]$Namespace,
        [Parameter(Mandatory=$true)]
        [string]$Class,
        [Parameter(ParameterSetName="ReturnString", Mandatory=$false)]
        [Parameter(ParameterSetName="PowerShellFile", Mandatory=$true)]
        [Parameter(ParameterSetName="CSharpFile", Mandatory=$true)]
        [string]$FilePath,
        [Parameter(ParameterSetName="PowerShellFile", Mandatory=$true)]
        [switch]$PowerShell,
        [Parameter(ParameterSetName="CSharpFile", Mandatory=$true)]
        [switch]$CSharp
    )

    process {
        $PowerShellFileTemplate = @"
`$TypeDefinition = @`"
{0}
`"@

Add-Type -TypeDefinition `$TypeDefinition

"@

        $ClassTemplate = @"
namespace $Namespace {{
    public class $Class {{
        public $Class({0}) {{
{1}
        }}

{2}        
    }}
}}
"@
        $ConstructorParameterTemplate = "{0} {1}"
        $ConstructorContentTemplate = (" " * 12) + "this.{0} = {0};"
        $ClassContentTemplate = (" " * 8) + "public {0} {1} {{ private set; get; }}"
        $ConstructorParameter = @()
        $ConstructorContent = @()
        $ClassContent = @()

        $Members = @(Get-Member -InputObject $Properties -MemberType NoteProperty | Select-Object -ExpandProperty Name)

        foreach ($Member in $Members) {
            if ($Properties.$Member -isnot [type]) {
                throw "`"$Member`" is not a type"
            }

            $ConstructorParameter += $ConstructorParameterTemplate -f $Properties.$Member.FullName, $Member
            $ConstructorContent += $ConstructorContentTemplate -f $Member
            $ClassContent += $ClassContentTemplate -f $Properties.$Member.FullName, $Member
        }

        $TypeDefinition = $ClassTemplate -f [string]::Join(", ", $ConstructorParameter),
                                            [string]::Join("`r`n", $ConstructorContent),
                                            [string]::Join("`r`n", $ClassContent)
        
        switch ($PSCmdlet.ParameterSetName) {
            "ReturnString" {
                Return $TypeDefinition
            }
            "PowerShellFile" {
                Out-File -Properties ($PowerShellFileTemplate -f $TypeDefinition) -FilePath $FilePath
            }
            "CSharpFile" {
                Out-File -Properties $TypeDefinition -FilePath $FilePath
            }
        }
    }
}
