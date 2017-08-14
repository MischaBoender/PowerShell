function Invoke-ExpectedError {
    param(
        [string]$Message="User `"$env:USERNAME`" caused an unrecoverable expected error."
    )
    
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($Message, "Expected Error", 0, 16)
}