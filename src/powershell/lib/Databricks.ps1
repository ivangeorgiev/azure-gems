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
        [string]
        $AccessToken,

        [string]
        $AzureRegion = 'westeurope'
    )

    $Global:DoDatabricksAccessToken = $AccessToken
    $Global:DoDatabricksURI = "https://$AzureRegion.azuredatabricks.net"
    $Global:DoDatabricksHeaders = @{
        "Authorization"="Bearer $AccessToken"
    }
}

function Get-DatabricksHeaders {
    if (!$Global:DoDatabricksAccessToken -or !$Global:DoDatabricksHeaders) {
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
        [string]
        $ClusterName,
        
        [string]$SparkVersion = "6.4.x-scala2.11",
        [string]$WorkerNodeType = "Standard_DS3_v2",
        [string]$DriverNodeType = "Standard_DS3_v2",
        [int]$AutoterminationMinutes = 60,
        [int]$MinWorkers = 1,
        [int]$MaxWorkers = 2
    )

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

    $Headers = Get-DatabricksHeaders

    $Body = $ClusterSettings | ConvertTo-Json -Depth 10
    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/clusters/create"
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    $Response = Invoke-RestMethod -Uri "$RequestUri" -Method 'POST' -Headers $Headers -Body $Body

    return $Response.cluster_id
}

function Get-DatabricksSecretScope([string]$ScopeName) {
    if (!$Global:DoDatabricksAccessToken -or !$Global:DoDatabricksHeaders) {
        Throw "Databricks is not connected. Consider using Connect-Databricks first"
    }

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
        [string]
        $ScopeName,
        $ManagePrincipal = 'users',
        [switch] $Force
    )
    if (!$Global:DoDatabricksAccessToken -or !$Global:DoDatabricksHeaders) {
        Throw "Databricks is not connected. Consider using Connect-Databricks first"
    }

    $ScopeSettings = @{
       "scope" = $ScopeName;
       "initial_manage_principal" = $ManagePrincipal;
    }

    $Headers = Get-DatabricksHeaders

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
    if (!$Global:DoDatabricksAccessToken -or !$Global:DoDatabricksHeaders) {
        Throw "Databricks is not connected. Consider using Connect-Databricks first"
    }

    $ScopeSettings = @{
       "scope" = $ScopeName;
    }

    $Headers = Get-DatabricksHeaders

    $Body = $ScopeSettings | ConvertTo-Json -Depth 10
    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/secrets/scopes/delete"
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    try {
        Invoke-RestMethod -Uri "$RequestUri" -Method 'POST' -Headers $Headers -Body $Body
    } catch {
        Get-DatabricksExpectErrorCode -Exception $_ -ErrorCode 'RESOURCE_DOES_NOT_EXIST' -Forced $Force
    }
}


function Get-DatabricksSecret([string]$ScopeName, [string]$SecretName, [string]$SecretValue) {
    if (!$Global:DoDatabricksAccessToken -or !$Global:DoDatabricksHeaders) {
        Throw "Databricks is not connected. Consider using Connect-Databricks first"
    }

    $Headers = Get-DatabricksHeaders

    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/secrets/list?scope=$ScopeName"
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    $Result = Invoke-RestMethod -Uri "$RequestUri" -Method 'GET' -Headers $Headers
    return $Result
}

function Set-DatabricksSecret([string]$ScopeName, [string]$SecretName, [string]$SecretValue) {
    if (!$Global:DoDatabricksAccessToken -or !$Global:DoDatabricksHeaders) {
        Throw "Databricks is not connected. Consider using Connect-Databricks first"
    }

    $SecretSettings = @{
       "scope" = $ScopeName;
       "key" = $SecretName;
       "string_value" = $SecretValue;
    }

    $Headers = Get-DatabricksHeaders

    $Body = $SecretSettings | ConvertTo-Json -Depth 10
    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/secrets/put"
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    Invoke-RestMethod -Uri "$RequestUri" -Method 'POST' -Headers $Headers -Body $Body
}


function Remove-DatabricksSecret([string]$ScopeName, [string]$SecretName, [switch]$Force) {
    if (!$Global:DoDatabricksAccessToken -or !$Global:DoDatabricksHeaders) {
        Throw "Databricks is not connected. Consider using Connect-Databricks first"
    }

    $SecretSettings = @{
       "scope" = $ScopeName;
       "key" = $SecretName;
    }

    $Headers = Get-DatabricksHeaders

    $Body = $SecretSettings | ConvertTo-Json -Depth 10
    $RequestUri = "${Global:DoDatabricksURI}/api/2.0/secrets/delete"
    $RequestUri = [uri]::EscapeUriString($RequestUri)
    try {
        Invoke-RestMethod -Uri "$RequestUri" -Method 'POST' -Headers $Headers -Body $Body
    } catch {
        Get-DatabricksExpectErrorCode -Exception $_ -ErrorCode 'RESOURCE_DOES_NOT_EXIST' -Forced $Force
    }
}
