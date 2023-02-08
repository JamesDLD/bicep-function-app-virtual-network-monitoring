function Send-DldAzAppInsightsEventTelemetry
{
    <#
    .SYNOPSIS
        Sends custom event telemetry to an Azure Application Insights instance.

    .DESCRIPTION
        Sends custom event telemetry to an Azure Application Insights instance. This function uses the Azure Application Insights REST API instead of a compiled client library, so it works without additional dependencies.

        NOTE: Telemetry ingestion to Azure Application Insights typically has a ~2-3 minute delay due to the eventual-consistency nature of the service.

    .PARAMETER ConnectionString
        Specify the Connection String of your Azure Application Insights instance. This determines where the data ends up.

    .PARAMETER EventName
        Specify the name of your custom event.

    .PARAMETER CustomProperties
        Optionally specify additional custom properties, in the form of a hashtable (key-value pairs) that should be logged with this telemetry.

    .EXAMPLE
        C:\> Send-DldAzAppInsightsEventTelemetry -EventName 'MyEvent1' `
                                               -ConnectionString <InstrumentationKey=guid;IngestionEndpoint=https://westeurope-3.in.applicationinsights.azure.com/;LiveEndpoint=https://westeurope.livediagnostics.monitor.azure.com/>
        Sends a custom event telemetry to application insights.

     .EXAMPLE
        C:\> Send-DldAzAppInsightsEventTelemetry  -EventName 'MyEvent1' `
                                                -CustomProperties @{ 'CustomProperty1'='abc'; 'CustomProperty2'='xyz' } `
                                                -ConnectionString <InstrumentationKey=guid;IngestionEndpoint=https://westeurope-3.in.applicationinsights.azure.com/;LiveEndpoint=https://westeurope.livediagnostics.monitor.azure.com/>

        Sends a custom event telemetry to application insights, with additional custom properties tied to this event.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
                Mandatory = $true,
                HelpMessage = 'Specify the connection string of your Azure Application Insights instance. This is the recommended method as it will point to the correct region and the the instrumentation key method support will end, see https://learn.microsoft.com/azure/azure-monitor/app/migrate-from-instrumentation-keys-to-connection-strings?WT.mc_id=AZ-MVP-5003548')]
        $ConnectionString,

        [Parameter(
                Mandatory = $true,
                HelpMessage = 'Specify the name of your custom event.')]
        [System.String]
        [ValidateNotNullOrEmpty()]
        $EventName,

        [Parameter(
                Mandatory = $false)]
        [Hashtable]
        $CustomProperties
    )
    Process {
        # App Insights has an endpoint where all incoming telemetry is processed.
        # The reference documentation is available here: https://learn.microsoft.com/azure/azure-monitor/app/api-custom-events-metrics?WT.mc_id=AZ-MVP-5003548

        function ParseConnectionString
        {
            param ([string]$ConnectionString)
            $Map = @{ }
            foreach ($Part in $ConnectionString.Split(";"))
            {
                $KeyValue = $Part.Split("=")
                $Map.Add($KeyValue[0], $KeyValue[1])
            }
            return $Map
        }

        $Map = ParseConnectionString($ConnectionString)
        $AppInsightsIngestionEndpoint = $Map["IngestionEndpoint"] + "v2/track"
        $InstrumentationKey = $Map["InstrumentationKey"]

        # Prepare custom properties.
        # Convert the hashtable to a custom object, if properties were supplied.

        if ($PSBoundParameters.ContainsKey('CustomProperties') -and $CustomProperties.Count -gt 0)
        {
            $CustomPropertiesObj = [PSCustomObject]$CustomProperties
        }
        else
        {
            $CustomPropertiesObj = [PSCustomObject]@{ }
        }

        # Prepare the REST request body schema.
        # NOTE: this schema represents how events are sent as of the app insights .net client library v2.9.1.
        # Newer versions of the library may change the schema over time and this may require an update to match schemas found in newer libraries.

        $BodyObject = [PSCustomObject]@{
            'name' = "Microsoft.ApplicationInsights.$InstrumentationKey.Event"
            'time' = ([System.dateTime]::UtcNow.ToString('o'))
            'iKey' = $InstrumentationKey
            'tags' = [PSCustomObject]@{
                'ai.cloud.roleInstance' = $ENV:COMPUTERNAME
                'ai.internal.sdkVersion' = 'AzurePowerShellUtilityFunctions'
            }
            'data' = [PSCustomObject]@{
                'baseType' = 'EventData'
                'baseData' = [PSCustomObject]@{
                    'ver' = '2'
                    'name' = $EventName
                    'properties' = $CustomPropertiesObj
                }
            }
        }

        # Uncomment one or more of the following lines to test client TLS/SSL protocols other than the machine default option
        # [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::SSL3
        # [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::TLS
        # [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::TLS11
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::TLS12
        # [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::TLS13

        # Convert the body object into a json blob.
        # Prepare the headers.
        # Send the request.

        $BodyAsCompressedJson = $bodyObject | ConvertTo-JSON -Depth 10 -Compress
        $Headers = @{
            'Content-Type' = 'application/x-json-stream';
        }

        Invoke-RestMethod -Uri $AppInsightsIngestionEndpoint -Method Post -Headers $Headers -Body $BodyAsCompressedJson
    }
}
