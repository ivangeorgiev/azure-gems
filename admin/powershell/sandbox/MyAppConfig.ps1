param(
    [String]$EnvironmentCode
)

function GetConfigForEnvironment {
    param (
        [String]$EnvironmentCode
    )

    $SettingsTable = @{
        'Location' = 'westeurope'
        'ResourceGroupName' = 'azadmin-demo-rg'
        'KeyVaultName' = 'azadmin-demo-kv'
        'KeyVaultPermissions' = 'list,get,set,delete'.split(',')
        'UserPrincipalName' = 'ivan.georgiev_gmail.com#EXT#@ivangeorgievgmail.onmicrosoft.com'
        'SecretName' = 'MySecret'
        'SecretValue' = 'Not Your Business'
        'PipelineVars' = @{}
    }
    $Settings = New-Object -TypeName psobject -Property $SettingsTable
    $Settings.PipelineVars['RGName'] = $Settings.ResourceGroupName
    return $Settings
}

function PrintHashTable {
    param (
        [hashtable]$Variables,
        [String]$Template='[$Key]=[$Value]'
    )
    ForEach ($Key in $Variables.Keys) {
        $Value = $Variables[$Key]
        Write-Host $ExecutionContext.InvokeCommand.ExpandString($Template)
    }
}

$config = GetConfigForEnvironment($EnvironmentCode)
PrintHashTable($config.PipelineVars)
$config