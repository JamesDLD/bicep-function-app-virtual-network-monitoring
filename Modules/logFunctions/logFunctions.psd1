@{
    RootModule = 'logFunctions.psm1'
    Description = 'A collection of log functions'
    FunctionsToExport = @(
    'Send-DldAzAppInsightsEventTelemetry'
    )
    ModuleVersion = '1.0'
}
