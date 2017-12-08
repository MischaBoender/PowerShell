# PowerShell Stuff
Useful and useless PowerShell Stuff I've created. **Use at your own risk!**

## Scripts
Colleaction of random scripts

- **Select-FromList.ps1**  
This function presents the user with a on-screen list of objects and allows the user to select which objects continue through the pipeline. *Requires the Read-Input function*.

- **Read-Input.ps1**  
Get user input, but restricted to pre-defined allowed characters. Also has a *SingleCharacterMode* and ability to handle special keys, for example  PageUp/Down, Arrow keys, etc.

- **Read-MultiLine.ps1**
Like the default Read-Host, but allowes multi-line. Use Ctrl+Enter to submit the input.

- **Format-ColoredTable.ps1**  
Formats the output as a table with a per row foreground color. The function uses dynamic parameters to add all possible console colors as a parameter that accepts scriptblock. If the InputObject passes through this scriptblock the resulting output row will be colored.

- **Get-MyPublicIPAddress.ps1**  
Tries to get the (NATted) public IP address of the client using up to 3 methods in this order: DNS query to "ifcfg.me", DNS query to "208.67.222.222" (OpenDNS) or as a last resort a WebRequest to "http://icanhazip.com".

- **New-TypeDefinition.ps1**
Helper function for creating .NET types. *Still a work in progress!*

## PowerFIGlet
PowerShell Module for FIGlet fonts

## Use-LessStuff
All useless PowerShell stuff goes here

- **Use-LessIntelliSense.ps1**  
I created this function at a PowerShell training (by Stefan Stranger) during a coffee break. This function will never execute successfully because it requires a (dynamic) switch parameter that has changed when you try to execute it.

- **Invoke-ExpectedError.ps1**  
Shows an error message claiming that the user caused an *expected* error.

- **Start-RickRoll.ps1**  
Rolls Rick across the title bar.


