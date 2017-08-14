function Get-MyPublicIPAddress {
    [CmdletBinding()]
    param()
    
    try {
        Write-Verbose "Trying to resolve your public IP through `"ifcfg.me`""
        return (Resolve-DnsName -Name . -Server 4.ifcfg.me -ErrorAction Stop -Verbose:$false | Select-Object -First 1).IPAddress
    }
    catch {
        Write-Verbose "Failed to resolve  your public IP through `"ifcfg.me`""
        try {
            Write-Verbose "Trying to resolve your public IP through `"opendns.com`""
            return (Resolve-DnsName -Name myip.opendns.com -Server 208.67.222.222 -ErrorAction Stop -Verbose:$false | Select-Object -First 1).IPAddress
        }
        catch {
            Write-Verbose "Failed to resolve  your public IP through `"opendns.com`""
            try {
                Write-Verbose "Trying to get your public IP from `"http://icanhazip.com`""
                return (Invoke-WebRequest -Uri http://icanhazip.com -ErrorAction Stop -Verbose:$false).Content
            }
            catch {
                Write-Verbose "Failed to get your public IP from `"http://icanhazip.com`""
                throw "Unable to get your public IP address"
            }
        }
    }
}