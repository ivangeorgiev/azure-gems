<#

Examples

1. Basic Example

```powershell
$Table = @{ 'name' = 'Ivan'; 'age' = 32 }
Write-TableToHost -Table $Table
```

2. Publish Hashtable content as Azure Pipeline variables

```powershell
$Table = @{ 'name' = 'Ivan'; 'age' = 32 }
Write-TableToHost -Table $Table -Template '##vso[task.setvariable variable=$Key]$Value'
```

3. Print object properties

```powershell
$Table = New-Object -TypeName psobject -Property @{ 'name' = 'Ivan'; 'age' = 32 }
Write-TableToHost -Table $Table
```

#>

param (
    $Variables,
    [String]$Table,
    [switch]$Sorted
)

function Write-TableToHost {
    param (
        $Table,
        [String]$Template='[$Key]=[$Value]',
        [switch]$Sorted
    )
    $Keys = if ($Table -Is [hashtable]) {
        $Table.Keys
    } else {
        ($Table | Get-Member -MemberType '*Property').Name
    }
    
    $Keys = if ($Sorted) { $Keys | Sort-Object } else { $Keys }

    ForEach ($Key in $Keys) {
        $Value = $Table.($Key)
        Write-Host $ExecutionContext.InvokeCommand.ExpandString($Template)
    }
}

if ($Table) {
    $invocation = 'Write-TableToHost -Table $Table'
    if ($Template) {
        $invocation += ' -Template $Template'
    }
    if ($Sorted) {
        $invocation += ' -Sorted'
    }
    Invoke-Expression $invocation
}

