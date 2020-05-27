# $here = Split-Path -Parent $MyInvocation.MyCommand.Path
$here = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "WriteHashTable" {

    It "should print keys and values with default template" {
        $CaptureFileName = New-TemporaryFile
        $Table = @{ 'name' = 'Ivan'; 'age' = 32 }
        WriteHashTable -Table $Table 6>$CaptureFileName
        $CapturedOutput = Get-Content $CaptureFileName
        Remove-Item $CaptureFileName

        $CapturedOutput | Should BeExactly @('[age]=[32]', '[name]=[Ivan]')
    }

    It "should print keys and values with custome template" {
        $CaptureFileName = New-TemporaryFile
        $Table = @{ 'name' = 'Ivan'; 'age' = 32 }
        WriteHashTable -Table $Table -Template '${Key}: ${Value}' 6>$CaptureFileName
        $CapturedOutput = Get-Content $CaptureFileName
        Remove-Item $CaptureFileName

        $CapturedOutput | Should BeExactly @('age: 32', 'name: Ivan')
    }
}
