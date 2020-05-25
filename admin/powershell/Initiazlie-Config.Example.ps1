

# Call using the script file
.\Initialize-Config.ps1 -SettingsList @(@{'HereWeGo'=1}, @{ 'b'='$HereWeGo'}) -PublishToEnv -CreateVars


# Load the file - it will not execute the function unless parameters are supplied
. .\Initialize-Config.ps1

$Conf = Initialize-Config -SettingsList @(@{'HereWeGo'=1}, @{ 'b'='$HereWeGo'}) -PublishToEnv -CreateVars

$Env:HereWeGo

$Args = @{
    'Env' = 'd'
    'AppName' = 'datacrunch'
    'VarNamePrefix' = 'DCR_'
}

$Settings = @{
    '$($Args.VarNamePrefix)WebAppName' = '$($Args.AppName)-$($Args.Env)-apps'
    '$($Args.VarNamePrefix)SqlServerName' = '$($Args.AppName)$($Args.Env)sqlsrv'
    '$($Args.VarNamePrefix)SqlDatabaseName' = '$($Args.AppName)$($Args.Env)sqldb'
}

$Conf = Initialize-Config -Arguments $Args -Settings $Settings -PublishToEnv -UpperEnvNames

Get-ChildItem Env: | Where-Object -Property Name -Like "DCR_*"

####

. .\Initialize-Config.ps1

$Arguments = @{
    'Env' = 'd'
    'AppName' = 'datacrunch'
    'VarNamePrefix' = 'DCR_'
}

$Settings = @{
    '$($A.VarNamePrefix)WebAppName' = '$($Args.AppName)-$($Args.Env)-apps'
    '$($A.VarNamePrefix)SqlServerName' = '$($Args.AppName)$($Args.Env)sqlsrv'
    '$($A.VarNamePrefix)SqlDatabaseName' = '$($Args.AppName)$($Args.Env)sqldb'
}

$Conf = Initialize-Config -Arguments $Arguments -Settings $Settings -PublishToEnv -UpperEnvNames -WriteToHost -WriteToHostTemplate '[$Key]=[$Value]' 6>.\vso-output.txt
Write-Output "============================ Expanded Settings ======================"
$Conf

Write-Output "`n============================ Environment Vars ======================"
Get-ChildItem Env: | Where-Object -Property Name -Like "DCR_*"

Write-Output "`n============================ Host Output ======================"
Get-Content .\vso-output.txt
Remove-Item .\vso-output.txt

