# $here = Split-Path -Parent $MyInvocation.MyCommand.Path
$here = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Write-TableToHost" {

    It "should print keys and values from hashtable with default template" {
        $CaptureFileName = New-TemporaryFile
        $Table = @{ 'name' = 'Ivan'; 'age' = 32 }
        Write-TableToHost -Table $Table 6>$CaptureFileName
        $CapturedOutput = Get-Content $CaptureFileName
        Remove-Item $CaptureFileName

        $CapturedOutput | Should BeExactly @('[age]=[32]', '[name]=[Ivan]')
    }

    It "should print sorted keys and values from PSCustomObject with default template" {
        $CaptureFileName = New-TemporaryFile
        $Table = New-Object -TypeName psobject -Property @{ 'name' = 'Ivan'; 'age' = 32; 'bongo' = 'yes' }
        Write-TableToHost -Table $Table -Sorted 6>$CaptureFileName
        $CapturedOutput = Get-Content $CaptureFileName
        Remove-Item $CaptureFileName

        $CapturedOutput | Should BeExactly @('[age]=[32]', '[bongo]=[yes]', '[name]=[Ivan]')
    }


    It "should print sorted keys and values with custome template" {
        $CaptureFileName = New-TemporaryFile
        $Table = @{ 'name' = 'Ivan'; 'age' = 32 }
        Write-TableToHost -Table $Table -Sorted -Template '${Key}: ${Value}' 6>$CaptureFileName
        $CapturedOutput = Get-Content $CaptureFileName
        Remove-Item $CaptureFileName

        $CapturedOutput | Should BeExactly @('age: 32', 'name: Ivan')
    }
    
}
