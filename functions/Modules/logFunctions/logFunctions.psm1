<#
    The module manifest (.psd1) defines this file as the entry point or root of the module.
    Ensure that all of the module functionality is loaded directly from this file.

    Module location : $env:PSModulePath
    #To add a temporary value that is available only for the current session, run the following command at the command line:
    foreach ($functionFile in (Get-ChildItem -Path "./functions/Modules/" -Recurse -Include "*.ps1")) {. $functionFile }
#>

# load functions

foreach ($functionFile in (Get-ChildItem -Path "$PSScriptRoot\functions" -Recurse -Include "*.ps1"))
{
    . $functionFile
}