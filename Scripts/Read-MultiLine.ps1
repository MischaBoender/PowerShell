function Read-MultiLine {
    param(
        [string]$Prompt
    )

    $EndInputText = "Press Ctrl+Enter to exit"

    Write-Host "$Prompt`:"
    Write-Host ""
    Write-Host $EndInputText -ForegroundColor DarkGray -NoNewline
    [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)

    $MultiLine = New-Object System.Collections.ArrayList
    $MultiLine.Add("") | Out-Null
    $CurrentLine = 0

    $TreatControlCAsInput = [console]::TreatControlCAsInput
    [console]::TreatControlCAsInput = $true

    do {
        $Key = [Console]::ReadKey($true)

        if ($Key.Modifiers -band [ConsoleModifiers]::Control -and $Key.Key -eq "C") {
            Write-Host ""
            [console]::TreatControlCAsInput = $TreatControlCAsInput
            throw "Control-C"
        }
        elseif ($Key.Modifiers -band [ConsoleModifiers]::Control -and $Key.Key -eq "Enter") {
            [Console]::SetCursorPosition(0, [Console]::CursorTop + 1)
            Write-Host (" " * $EndInputText.Length) -NoNewline
            [Console]::SetCursorPosition(0, [Console]::CursorTop)
            break
        }
        elseif ($Key.Key -eq "Enter") {
            $CurrentLine += 1
            $MultiLine.Insert($CurrentLine, "")
            Write-Host ""
            Write-Host (" " * $EndInputText.Length)
            Write-Host $EndInputText -ForegroundColor DarkGray -NoNewline
            [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
        }
        elseif ($Key.Key -eq "Backspace") {
            if ($MultiLine[$CurrentLine].Length -gt 0) {
                $MultiLine[$CurrentLine] = $MultiLine[$CurrentLine].Substring(0, $MultiLine[$CurrentLine].Length - 1)
                Write-Host "`b `b" -NoNewline
            }
            elseif ($CurrentLine -gt 0) {
                $MultiLine.RemoveAt($CurrentLine)
                $CurrentLine -= 1

                [Console]::SetCursorPosition(0, [Console]::CursorTop + 1)
                Write-Host (" " * $EndInputText.Length) -NoNewline
                [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
                Write-Host $EndInputText -ForegroundColor DarkGray -NoNewline
                if ($MultiLine[$CurrentLine].Length -lt [Console]::BufferWidth) {
                    [Console]::SetCursorPosition($MultiLine[$CurrentLine].Length, [Console]::CursorTop - 1)
                }
                else {
                    $MultiLine[$CurrentLine] = $MultiLine[$CurrentLine].Substring(0, $MultiLine[$CurrentLine].Length - 1)
                    [Console]::SetCursorPosition([Console]::BufferWidth - 1, [Console]::CursorTop - 1)
                    Write-Host " `b" -NoNewline
                }
            }
        }
        elseif (32..126 -contains [int]$Key.KeyChar) {
            $CursorTop = [Console]::CursorTop
            Write-Host $Key.KeyChar.ToString() -NoNewline
            if ([Console]::CursorTop -gt $CursorTop) {
                $CurrentLine += 1
                $MultiLine.Insert($CurrentLine, "")
                Write-Host (" " * $EndInputText.Length)
                Write-Host $EndInputText -ForegroundColor DarkGray -NoNewline
                [Console]::SetCursorPosition(1, [Console]::CursorTop - 1)
            }
            $MultiLine[$CurrentLine] += $Key.KeyChar.ToString()
        }
    } while ($true)
    
    [console]::TreatControlCAsInput = $TreatControlCAsInput

    if ([string]::IsNullOrEmpty($MultiLine[$CurrentLine])) {
        $MultiLine.RemoveAt($CurrentLine)
    }

    return [string]::Join("`r`n", $MultiLine.ToArray())
}
