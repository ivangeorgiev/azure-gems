param ( 
    [Parameter(  
        Position = 0,   
        ValueFromPipeline = $true,  
        ValueFromPipelineByPropertyName = $true  
    )] [object] $PSCustomObject 
);

function ConvertTo-HashtableFromPSCustomObject { 
    param ( 
        [Parameter(  
            Position = 0,   
            Mandatory = $true,   
            ValueFromPipeline = $true,  
            ValueFromPipelineByPropertyName = $true  
        )] [object] $PSCustomObject 
    );

    $Output = @{}; 
    $PSCustomObject | Get-Member -MemberType *Property | % {
        $Output.($_.name) = $PSCustomObject.($_.name); 
    } 
    
    return  $Output;
}

if ($PSCustomObject) {
    $invocation = 'ConvertTo-HashtableFromPSCustomObject -PSCustomObject $PSCustomObject'
    Invoke-Expression $invocation
}
