function Start-RickRoll {
    $RollRick = {
        param($RawUi)

        $Roll = @(
            "Never gonna give you up,",
            "Never gonna let you down,",
            "Never gonna run around and desert you.",
            "Never gonna make you cry,",
            "Never gonna say goodbye,",
            "Never gonna tell a lie and hurt you."
        )

        do {
            foreach ($Rick in $Roll) {
                $RawUI.WindowTitle = $Rick
                Start-Sleep -Milliseconds 500
                foreach ($i in 1..($Rick.Length - 1)) {
                    $RawUI.WindowTitle = $Rick.Substring($i, $Rick.Length - $i)
                    Start-Sleep -Milliseconds 50
                }
            }
        } while ($true)
    }

    $PSInstance = [PowerShell]::Create()
    $PSInstance.AddScript($RollRick).AddArgument($host.UI.RawUI) | Out-Null
    $PSInstance.BeginInvoke() | Out-Null
}