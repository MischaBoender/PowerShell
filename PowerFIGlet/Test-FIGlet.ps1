function Test-FIGlet {
    param(
        [string]$Text
    )
    
    Get-FigletFont -ListAvailable | %{
        try {
        Write-Host "Font: $($_.Font)"
        if (-not $Text) {
            ConvertTo-FIGlet -InputObject $_.Font -Font $_.Font
        }
        else {
            ConvertTo-FIGlet -InputObject $Text -Font $_.Font
        }
        } catch {}
    }
}