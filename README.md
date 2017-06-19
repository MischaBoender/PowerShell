# PowerShell Stuff
Useful and useless PowerShell Stuff I've created. **Use at your own risk!**

## Functions
### Select-FromList.ps1
This function presents the user with a on-screen list of objects and allows the user to select which objects continue through the pipeline. *Uses the Read-Input function*.

### Read-Input.ps1
Allows user input, but restricted to pre-defined allowed characters. Can also immediately *return* for specific keys. 

### Format-ColoredTable.ps1
Formats the output as a table with a per row foreground color. The function uses dynamic parameters to add all possible console colors as a parameter that accepts scriptblock. If the InputObject passes through this scriptblock the resulting output row will be colored.

## Scripts
### Use-LessIntelliSense.ps1
Created this function at a PowerShell training (by Stefan Stranger) during a coffee break. This function will never execute successfully because it requires a (dynamic) switch parameter that has changed when you try to execute it.
