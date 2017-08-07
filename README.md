# PowerShell Stuff
Useful and useless PowerShell Stuff I've created. **Use at your own risk!**

## Useful
- **Select-FromList.ps1**  
This function presents the user with a on-screen list of objects and allows the user to select which objects continue through the pipeline. *Uses the Read-Input function*.

- **Read-Input.ps1**  
Allows user input, but restricted to pre-defined allowed characters. Can also immediately *return* for specific keys. 

- **Format-ColoredTable.ps1**  
Formats the output as a table with a per row foreground color. The function uses dynamic parameters to add all possible console colors as a parameter that accepts scriptblock. If the InputObject passes through this scriptblock the resulting output row will be colored.

- **Get-MyPublicIPAddress.ps1**  
Tries to get the (NATted) public IP address of the client using up to 3 methods in this order: DNS query to "ifcfg.me", DNS query to "208.67.222.222" (OpenDNS) or as a last resort a WebRequest to "http://icanhazip.com".

- **New-TypeDefinition.ps1**
Helper function for creating .NET types. *Still a work in progress!*

## Useless
- **Use-LessIntelliSense.ps1**  
I created this function at a PowerShell training (by Stefan Stranger) during a coffee break. This function will never execute successfully because it requires a (dynamic) switch parameter that has changed when you try to execute it.

- **Invoke-ExpectedError.ps1**  
Shows an error message claiming that the user caused an *expected* error.

- **Start-RickRoll.ps1**  
Rolls Rick acroos the title bar.