@{
    # The module version should be SemVer.org compatible
    ModuleVersion          = '1.0.0'

    # The main script module that is automatically loaded as part of this module
    RootModule             = 'ParameterTester.psm1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules        = @('Pester')
    PrivateData            = @{
        # PSData hashtable is metadata used by PowerShellGet
        PSData = @{
            PreRelease = "False"

            # Release Notes have to be here, so we can update them
            ReleaseNotes = '
            First release to the PowerShell gallery ...
            '
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = 'Reflection', 'Testing'

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/PoshCode/ParameterTester/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/PoshCode/ParameterTester'

            # A URL to an icon representing this module.
            IconUri      = 'https://github.com/PoshCode/ParameterTester/blob/resources/ParameterTester.png?raw=true'
        } # End of PSData hashtable
    } # End of PrivateData hashtable

    FunctionsToExport      = @()
    AliasesToExport        = @()
    FormatsToProcess       = "Format.ps1xml"

    # ID used to uniquely identify this module
    GUID                   = '969e7c56-25ca-4688-a06c-83ec448ccc7c'
    Description            = 'Functions for viewing and testing parameters and parameter sets'

    # Common stuff for all our modules:
    CompanyName            = 'PoshCode'
    Author                 = 'Joel Bennett'
    Copyright              = 'Copyright 2018 Joel Bennett, All Rights Reserved'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion      = '4.0'
    CompatiblePSEditions = @('Core', 'Desktop')
}

