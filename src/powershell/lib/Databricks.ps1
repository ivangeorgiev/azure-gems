<#

.SYNOPSIS
Helper routines for calling Databricks REST API.

.DESCRIPTION
This library implements a series of routines which call the Databricks API.

Before calling a routine, you need to estabilish a connection to a Databricks
instance. For this purpose, us the Connect-Databricks scriptlet.

.EXAMPLE

Following example connects to Databricks and gets a list of clusters.

```powershell
Connect-Databricks -AccessToken 'dapi0123456'
Get-DatabricksCluster
```

#>

function Get-DatabricksErrorCodeFromException($Exception) {
    try {
        Return ($Exception.ErrorDetails.Message | ConvertFrom-Json).error_code
    } catch {
        Throw $Exception
    }
}

function Get-DatabricksExpectErrorCode($Exception, $ErrorCode, [bool]$Forced) {
    if (!$Forced) {
        Throw $Exception
    }
    if ($ErrorCode -ne (Get-DatabricksErrorCodeFromException $Exception) ) {
        Throw $Exception
    }
}

function Connect-Databricks {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BearerToken,

        [string]$URI = "https://westeurope.azuredatabricks.net",

        [String]$ClusterId
    )

    $Global:DoDatabricksBearerToken = $BearerToken
    $Global:DoDatabricksURI = $URI
    $Global:DoDatabricksClusterId = $ClusterId
    $Global:DoDatabricksHeaders = @{
        "Authorization"="Bearer $BearerToken"
    }
}

function Get-DatabricksHeaders {
    if (!$Global:DoDatabricksHeaders) {
        Throw "Databricks is not connected. Consider using Connect-Databricks first"
    }

    return $Global:DoDatabricksHeaders
}

function Get-DatabricksCluster([string]$ClusterName) {
    $Headers = Get-DatabricksHeaders

    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/clusters/list"
    $RequestUri = [uri]::EscapeUriString($RequestUri)

    $Response = (Invoke-RestMethod -Uri "$RequestUri" -Method 'GET' -Headers $Headers).clusters
    if ($ClusterName) {
        $Response = $Response | Where-Object -Property cluster_name -EQ $ClusterName
    }
    return $Response
}

function Ensure-DatabricksCluster {
    param(
        [string]$ClusterName,
        
        [string]$SparkVersion = "6.4.x-scala2.11",
        [string]$WorkerNodeType = "Standard_DS3_v2",
        [string]$DriverNodeType = "Standard_DS3_v2",
        [int]$AutoterminationMinutes = 60,
        [int]$MinWorkers = 1,
        [int]$MaxWorkers = 2
    )

    $Headers = Get-DatabricksHeaders
    $CurrentCluster = Get-DatabricksCluster -ClusterName $ClusterName
    if ($CurrentCluster) {
        if ($CurrentCluster -is [array]) {
            Write-Warning "Mulltiple results returned for $ClusterName"
            $CurrentCluster = $CurrentCluster[0]
        }
        return $CurrentCluster.cluster_id
    }


    $ClusterSettings = @{
       "cluster_name" = $ClusterName;
       "spark_version" = $SparkVersion;
       "node_type_id" = $WorkerNodeType;
       "driver_node_type_id" = $DriverNodeType;
       "autotermination_minutes" = $AutoterminationMinutes;
       "autoscale" = @{
         "min_workers" = $MinWorkers;
         "max_workers" = $MaxWorkers
       }
    }

    $Body = $ClusterSettings | ConvertTo-Json -Depth 10
    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/clusters/create"
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    $Response = Invoke-RestMethod -Uri "$RequestUri" -Method 'POST' -Headers $Headers -Body $Body

    return $Response.cluster_id
}

function Get-DatabricksSecretScope([string]$ScopeName) {
    $Headers = Get-DatabricksHeaders

    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/secrets/scopes/list"
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    $Response = Invoke-RestMethod -Uri "$RequestUri" -Method 'GET' -Headers $Headers

    if ($ScopeName) {
        return ($Response.scopes | Where-Object -Property name -EQ $ScopeName)
    }
    return $Response.scopes
}

function Create-DatabricksSecretScope {
    param(
        [string]$ScopeName,
        [string]$ManagePrincipal = 'users',
        [switch]$Force
    )
    $Headers = Get-DatabricksHeaders

    $ScopeSettings = @{
       "scope" = $ScopeName;
       "initial_manage_principal" = $ManagePrincipal;
    }

    $Body = $ScopeSettings | ConvertTo-Json -Depth 10
    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/secrets/scopes/create"
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    try {
        Invoke-RestMethod -Uri "$RequestUri" -Method 'POST' -Headers $Headers -Body $Body
    } catch {
        Get-DatabricksExpectErrorCode -Exception $_ -ErrorCode 'RESOURCE_ALREADY_EXISTS' -Forced $Force
    }
}


function Remove-DatabricksSecretScope([string]$ScopeName, [switch]$Force) {
    $Headers = Get-DatabricksHeaders

    $ScopeSettings = @{
       "scope" = $ScopeName;
    }

    $Body = $ScopeSettings | ConvertTo-Json -Depth 10
    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/secrets/scopes/delete"
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    try {
        Invoke-RestMethod -Uri "$RequestUri" -Method 'POST' -Headers $Headers -Body $Body
    } catch {
        Get-DatabricksExpectErrorCode -Exception $_ -ErrorCode 'RESOURCE_DOES_NOT_EXIST' -Forced $Force
    }
}


function Get-DatabricksSecret() {
    param(
        [string]$ScopeName, 
        [string]$SecretName
    )
    $Headers = Get-DatabricksHeaders

    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/secrets/list?scope=$ScopeName"
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    $Result = Invoke-RestMethod -Uri "$RequestUri" -Method 'GET' -Headers $Headers
    if ($SecretName) {
        return ($Result.secrets | Where-Object -Property key -EQ $SecretName)
    }
    return $Result
}

function Set-DatabricksSecret([string]$ScopeName, [string]$SecretName, [string]$SecretValue) {
    $Headers = Get-DatabricksHeaders

    $SecretSettings = @{
       "scope" = $ScopeName;
       "key" = $SecretName;
       "string_value" = $SecretValue;
    }

    $Body = $SecretSettings | ConvertTo-Json -Depth 10
    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/secrets/put"
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    Invoke-RestMethod -Uri "$RequestUri" -Method 'POST' -Headers $Headers -Body $Body
}


function Remove-DatabricksSecret([string]$ScopeName, [string]$SecretName, [switch]$Force) {
    $Headers = Get-DatabricksHeaders

    $SecretSettings = @{
       "scope" = $ScopeName;
       "key" = $SecretName;
    }

    $Body = $SecretSettings | ConvertTo-Json -Depth 10
    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/secrets/delete"
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    try {
        Invoke-RestMethod -Uri "$RequestUri" -Method 'POST' -Headers $Headers -Body $Body
    } catch {
        Get-DatabricksExpectErrorCode -Exception $_ -ErrorCode 'RESOURCE_DOES_NOT_EXIST' -Forced $Force
    }
}



function List-DatabricksRuns() {
    [cmdletbinding()]
    param(
        [Int]$JobId,
        [Int]$Offset,
        [Int]$Limit,
        [Bool]$ActiveOnly,
        [Bool]$CompletedOnly
    )

    $Headers = Get-DatabricksHeaders

    $Params = @()
    If ($JobId) { $Params += "job_id=$JobId" }
    If ($Offset) { $Params += "offset=$Offset" }
    If ($Limit) { $Params += "limit=$Limit" }
    If ($ActiveOnly) { $Params += "active_only=true" }
    If ($CompletedOnly) { $Params += "completed_only=true" }

    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/jobs/runs/list"
    If ($Params) {
        $RequestUri += "?$($Params -join '&')"
    }
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    $Result = Invoke-RestMethod -Uri "$RequestUri" -Method 'GET' -Headers $Headers
    Return $Result
}


Function Submit-DatabricksNotebook() {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)][String]$NotebookPath,
        [String]$RunName,
        [String]$ClusterId,
        [Hashtable]$NotebookParams
    )

    If (!$NotebookParams) { $NotebookParams = @{} }
    If (!$RunName) { $RunName = "PSSubmit-$NotebookPath" }
    If (!$ClusterId) { $ClusterId = $Global:DoDatabricksClusterId }

    $Data = @{
        run_name = $RunName;
        existing_cluster_id = $ClusterId;
        libraries = @();
        notebook_task = @{
            notebook_path = $NotebookPath;
            base_parameters = $NotebookParams
        }

    }

    $Body = $Data | ConvertTo-Json -Depth 10
    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/jobs/runs/submit"
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    $Result = Invoke-RestMethod -Uri "$RequestUri" -Method 'POST' -Headers $Headers -Body $Body
    Return $Result
}


Function Get-DatabricksRunOutput() {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)][Int]$RunId
    )
    $Headers = Get-DatabricksHeaders


    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/jobs/runs/get-output?run_id=$RunId"
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    $Result = Invoke-RestMethod -Uri "$RequestUri" -Method 'GET' -Headers $Headers
    If ($Result.notebook_output.result) {
        $Result.notebook_output.result = (ConvertFrom-Json $Result.notebook_output.result)
    }
    Return $Result
}


Function Get-DatabricksRun() {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)][Int]$RunId
    )
    $Headers = Get-DatabricksHeaders


    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/jobs/runs/get?run_id=$RunId"
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    $Result = Invoke-RestMethod -Uri "$RequestUri" -Method 'GET' -Headers $Headers
    Return $Result
}


Function Wait-DatabricksRun() {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)][Int]$RunId,
        [Float]$TimeoutSeconds=300.0,
        [Float]$WaitIntervalMilliseconds=3000
    )

    $ExitStates = @('TERMINATED', 'SKIPPED', 'INTERNAL_ERROR')
    $ExpiresAt = [convert]::ToDouble( (Get-Date -UFormat %s) ) + $TimeoutSeconds
    $RunMeta = (Get-DatabricksRun -RunId $RunId)
    Write-Verbose "Waiting for run $RunId ($($RunMeta.run_page_url))"
    While (1) {
        $RunState = $RunMeta.state.life_cycle_state
        If ($RunState -in $ExitStates) {
            Write-Verbose "Run $RunId finished with state $RunState"
            break
        }
        If ( [convert]::ToDouble( (Get-Date -UFormat %s) ) -gt $ExpiresAt ) {
            Throw "Timeout of $TimeoutSeconds seconds reached for run $RunId. Last state was $($RunMeta.state.life_cycle_state). Giving up."
        }
        Write-Verbose "Run $RunId is not in final state ($RunState). Sleeping for $WaitIntervalMilliseconds ms"
        Start-Sleep -Milliseconds $WaitIntervalMilliseconds
        $RunMeta = (Get-DatabricksRun -RunId $RunId)
    }
    Return $RunMeta
}

