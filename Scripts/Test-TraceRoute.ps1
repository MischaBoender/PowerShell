function Test-TraceRoute {
    param(
        [Parameter(Position=0)]
        [string]$Destination,
        [int]$TimeOut = 1000,
        [int]$MaxTTL = 30,
        [int]$BufferSize = 32
    )

    [byte[]]$Buffer = New-Object -TypeName Byte[] -ArgumentList $BufferSize
    (New-Object Random).NextBytes($Buffer)
    [System.Net.NetworkInformation.Ping]$Ping = New-Object -TypeName System.Net.NetworkInformation.Ping

    for ([int]$TTL = 1; $TTL -le $MaxTTL; $TTL++) {
        [System.Net.NetworkInformation.PingOptions]$PingOptions = New-Object -TypeName System.Net.NetworkInformation.PingOptions -ArgumentList $TTL, $True
        [System.Net.NetworkInformation.PingReply]$PingReply = $Ping.Send($Destination, $TimeOut, $Buffer, $PingOptions)

        [PSCustomObject]@{
            Hop = $TTL
            Address = $(if ($PingReply.Address) {$PingReply.Address.ToString()} else {"*"})
            RoundtripTime = $PingReply.RoundtripTime
            Complete = $PingReply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success
        } | Write-Output

        if (
            $PingReply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success -or
            $PingReply.Status -eq [System.Net.NetworkInformation.IPStatus]::DestinationNetworkUnreachable
        ) {break}
    }
}