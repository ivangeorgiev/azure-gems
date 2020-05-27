<#

Examples

1. Basic Example

```powershell
$Table = @{ 'name' = 'Ivan'; 'age' = 32 }
WriteHashTable -Table $Table
```

2. Publish Hashtable content as Azure Pipeline variables

```powershell
$Table = @{ 'name' = 'Ivan'; 'age' = 32 }
WriteHashTable -Table $Table -Template '##vso[task.setvariable variable=$Key]$Value'
```

#>

param (
    [hashtable]$Variables,
    [String]$Table
)

function WriteHashTable {
    param (
        [hashtable]$Table,
        [String]$Template='[$Key]=[$Value]'
    )
    ForEach ($Key in $Table.Keys) {
        $Value = $Table[$Key]
        Write-Host $ExecutionContext.InvokeCommand.ExpandString($Template)
    }
}

if ($Table) {
    $invocation = 'WriteHashTable -Table $Table'
    if ($Template) {
        $invocation += ' -Template $Template'
    }
    Invoke-Expression $invocation
}

