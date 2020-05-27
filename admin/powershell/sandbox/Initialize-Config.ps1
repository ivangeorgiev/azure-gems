param(
    [Hashtable]$Arguments,
    [Hashtable]$Settings,
    [Array]$SettingsList,
    [switch]$PublishToEnv,
    [switch]$UpperEnvNames,
    [switch]$WriteToHost,
    [String]$WriteToHostTemplate,
    [switch]$CreateVars
)

function Initialize-Config {
    param(
        [Hashtable]$Arguments,
        [Hashtable]$Settings,
        [Array]$SettingsList,
        [switch]$PublishToEnv,
        [switch]$UpperEnvNames,
        [switch]$WriteToHost,
        [String]$WriteToHostTemplate='##vso[task.setvariable variable=$Key]$Value',
        [switch]$CreateVars
    )

    if ($Arguments) {
        $Args = Initialize-Config -Settings $Arguments
    } else {
        $Args = @{}
    }
    $A = $Args
    $Result = @{}
    $S = $V = $Vars = $Result

    if (!$SettingsList) {
        $SettingsList = @()
    }
    if ($Settings) {
        $SettingsList += $Settings
    }

    ForEach ($SettingsTable in $SettingsList) {
        ForEach( $SettingKey in $SettingsTable.Keys ) {
            $SettingName = $ExecutionContext.InvokeCommand.ExpandString($SettingKey)
            $SettingValue = $ExecutionContext.InvokeCommand.ExpandString($SettingsTable[$SettingKey])
            if ($CreateVars) {
                New-Variable -Name $SettingName -Value $SettingValue -Scope 1 -Force
                Set-Variable -Name $SettingName -Value $SettingValue -Force
            }
            $Result[$SettingName] = $SettingValue
        }
    }

    if ($PublishToEnv) {
        ForEach ($Key in $Result.Keys) {
            $EnvVarName = if ($UpperEnvNames) { $Key.ToUpper() } else { $Key }
            [System.Environment]::SetEnvironmentVariable($EnvVarName, $null)
            [System.Environment]::SetEnvironmentVariable($EnvVarName, $Result[$Key])
        }
    }
    if ($WriteToHost) {
        ForEach ($Key in $Result.Keys) {
            $Value = $Result[$Key]
            Write-Host $ExecutionContext.InvokeCommand.ExpandString($WriteToHostTemplate)
        }
    }
    $Result
}

if ($Settings -or $SettingsList) {
    $invocation = 'Initialize-Config -Arguments $Arguments -Settings $Settings -SettingsList $SettingsList'
    if ($PublishToEnv) {
        $invocation += ' -PublishToEnv'
    }
    if ($UpperEnvNames) {
        $invocation += ' -UpperEnvNames'
    }
    if ($WriteToHost) {
        $invocation += ' -WriteToHost'
    }
    if ($WriteToHostTemplate) {
        $invocation += ' -WriteToHostTemplate $WriteToHostTemplate'
    }
    if ($CreateVars) {
        $invocation += ' -CreateVars'
    }
    Invoke-Expression $invocation
}
