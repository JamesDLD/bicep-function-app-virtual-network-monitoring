param($Timer)

try
{
    # Variable & Depedency
    Import-Module -Name logFunctions
    $APPLICATIONINSIGHTS_CONNECTION_STRING = $env:APPLICATIONINSIGHTS_CONNECTION_STRING

    $vNets = Get-AzVirtualNetwork


    # Audit
    foreach ($vNet in $vNets) {
        $vNetUsageList = Get-AzVirtualNetworkUsageList -ResourceGroupName $vNet.ResourceGroupName -Name $vNet.Name

        foreach ($subnet in $vNet.Subnets) {
            $subnetUsageList = $vNetUsageList | Where-Object { $_.Id -eq $subnet.Id }

            Write-Host "IPaddressesCount [$( $subnetUsageList.CurrentValue )] under AddressPrefix [$( $subnet.AddressPrefix )] for resourceId [$( $subnet.Id )]"

            $CustomProperties = @{
                VirtualNetworkAddressPrefixes = $vNet.AddressSpace.AddressPrefixes
                SubnetId                      = $subnet.Id
                SubnetName                    = $subnet.Name
                SubnetAddressPrefix           = $subnet.AddressPrefix
                SubnetIPaddressesCount        = $subnetUsageList.CurrentValue 
                SubnetIPaddressesLimit        = $subnetUsageList.Limit
            }

            Write-Host "Send custom event telemetry [dld_telemetry_azure_vnets_counter] for the subnet [$( $subnet.Name )] located in the virtual network [$( $vNet.Name )]"

            Send-DldAzAppInsightsEventTelemetry                                         `
                -EventName 'dld_telemetry_azure_vnets_counter'                          `
                -CustomProperties $CustomProperties                                     `
                -ConnectionString $APPLICATIONINSIGHTS_CONNECTION_STRING | Out-Null
        }
    }
}
catch
{
    $FunctionError = $_
    switch ($PSItem.Exception.Message)
    {
        'Some error'
        {
        }
        default
        {
            Send-Tf1Notification                                                                                `
                -Title "Error on Azure Function [$( $env:WEBSITE_SITE_NAME )] for function [VnetProbe]"         `
                -Description "$( '```' + $FunctionError + '```' )"
        }
    }
    Write-Error $FunctionError
}
