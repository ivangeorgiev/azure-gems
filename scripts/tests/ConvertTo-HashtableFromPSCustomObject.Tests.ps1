# $here = Split-Path -Parent $MyInvocation.MyCommand.Path
$here = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "ConvertTo-HashtableFromPSCustomObject" {
    
    It "does something useful" {
        $Table = @{ 'name' = 'Ivan'; 'age' = 32 }
        $Object = New-Object -TypeName psobject -Property $Table

        $actual = ConvertTo-HashtableFromPSCustomObject $Object
        ($actual | ConvertTo-Json) | Should -BeExactly (ConvertTo-Json $Table)
    }
}
