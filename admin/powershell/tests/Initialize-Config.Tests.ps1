# $here = Split-Path -Parent $MyInvocation.MyCommand.Path
$here = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Initialize-Config" {
    It "should run with no arguments" {
        Initialize-Config
    }

    It "should return empty hashtable with no arguments" {
        $output = Initialize-Config
        ($output | ConvertTo-Json) | Should Be (@{} | ConvertTo-Json)
    }

    It "should return hashtable" {
        $Settings = @{
            'name' = 'Ivan'
        }
        $output = Initialize-Config -Settings $Settings
        $output | Should BeOfType [hashtable]
    }

    It "should return hashtable with settings with same keys and values" {
        $Settings = @{
            'name' = 'Ivan'
        }
        $output = Initialize-Config -Settings $Settings
        ($output | ConvertTo-Json) | Should Be (@{ "name" = "Ivan" } | ConvertTo-Json)
    }

    It "should return hashtable with settings with interpolated values" {
        $Settings = @{
            'sum' = '$(1+1)'
        }
        $output = Initialize-Config -Settings $Settings
        ($output | ConvertTo-Json) | Should Be (@{ "sum" = "2" } | ConvertTo-Json)
    }

    It "should interpolate setting name" {
        $Settings = @{
            'x$(2)' = '3'
        }
        $output = Initialize-Config -Settings $Settings
        ($output | ConvertTo-Json) | Should Be (@{ "x2" = "3" } | ConvertTo-Json)
    }



    It "should accept list as Settings argument" {
        $Settings = @( @{ 'a' = '1'}, @{ 'b' = '2' } )

        $output = Initialize-Config -SettingsList $Settings
        ($output | ConvertTo-Json) | Should Be (@{ "a" = "1"; 'b' = '2' } | ConvertTo-Json)
    }
    
    It "should interpolate with already evaulated settings" {
        $Settings = @( @{ 'a' = '1'}, @{ 'b' = '$(($V.a -as [int]) +1)' } )

        $output = Initialize-Config -SettingsList $Settings
        ($output | ConvertTo-Json) | Should Be (@{ "a" = "1"; 'b' = '2' } | ConvertTo-Json)
    }

    It "should create local vars" {
        $Settings = @( @{ 'a' = '1'}, @{ 'b' = '$a' } )

        $output = Initialize-Config -SettingsList $Settings -CreateVars
        ($output | ConvertTo-Json) | Should Be (@{ "a" = "1"; 'b' = '1' } | ConvertTo-Json)
    }
    
    It "should interpolate with parameters" {
        $Args = @{ 'Env' = 'Test'}
        $Settings = @{ 'e' = '$($A.Env)'}

        $output = Initialize-Config -SettingsList $Settings -Arguments $Args
        ($output | ConvertTo-Json) | Should Be (@{ "e" = "Test" } | ConvertTo-Json)
    }

    It "should publish to Env" {
        $Settings = @{ 'MyFavoriteVar' = 'Test'}
        [Environment]::SetEnvironmentVariable("MyFavoriteVar",$null)
        $Env:MyFavoriteVar | Should BeNullOrEmpty

        $output = Initialize-Config -SettingsList $Settings -PublishToEnv
        ($output | ConvertTo-Json) | Should Be (@{ "MyFavoriteVar" = "Test" } | ConvertTo-Json)

        $var = Get-ChildItem Env: | Where-Object -Property Name -Eq MYFAVORITEVAR
        $var.Name | Should BeExactly 'MyFavoriteVar'
        $var.Value | Should Be 'Test'
    }
    
    It "should publish to Env with upper case variable name" {
        $Settings = @{ 'My_Favorite_Var' = 'Test'}
        [Environment]::SetEnvironmentVariable("My_Favorite_Var",$null)
        $Env:MY_FAVORITE_VAR | Should BeNullOrEmpty

        $output = Initialize-Config -SettingsList $Settings -PublishToEnv -UpperEnvNames
        ($output | ConvertTo-Json) | Should Be (@{ "My_Favorite_Var" = "Test" } | ConvertTo-Json)

        $var = Get-ChildItem Env: | Where-Object -Property Name -Eq 'My_Favorite_Var'
        $var.Name | Should BeExactly 'MY_FAVORITE_VAR'
        $var.Value | Should Be 'Test'
    }

    It "should publish to VSO with default template" {
        $Settings = @{ 'My_Favorite_Var' = 'Test'}

        
        $CaptureFileName = '.\Initialize-Config.Output.Capture.txt'
        $output = Initialize-Config -SettingsList $Settings -WriteToHost 6>$CaptureFileName
        $CapturedOutput = Get-Content $CaptureFileName
        ($output | ConvertTo-Json) | Should Be (@{ "My_Favorite_Var" = "Test" } | ConvertTo-Json)

        # Remove-Item $CaptureFileName
        $CapturedOutput | Should BeExactly '##vso[task.setvariable variable=My_Favorite_Var]Test'
    }
    


    It "should publish to Host with template" {
        $Settings = @{ 'My_Favorite_Var' = 'Test'}

        
        $CaptureFileName = '.\Initialize-Config.Output.Capture.txt'
        $output = Initialize-Config -SettingsList $Settings -WriteToHost -WriteToHostTemplate '[$Key]=[$Value]' 6>$CaptureFileName
        $CapturedOutput = Get-Content $CaptureFileName
        ($output | ConvertTo-Json) | Should Be (@{ "My_Favorite_Var" = "Test" } | ConvertTo-Json)

        # Remove-Item $CaptureFileName
        $CapturedOutput | Should BeExactly '[My_Favorite_Var]=[Test]'
    }
    
    
}
