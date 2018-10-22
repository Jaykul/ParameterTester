This module is based on the Get-Parameter function written by Hal Rottenberg, Oisin Grehan, Jason Archer, and Shay Levy, and Joel Bennett over the years ...


### Example Usage:

This first example avoids testing parameter sets explicitly by using the -AllowMissedSets switch

```PowerShell
    Test-ParametersOf -Command Import-QMTenant -AllowMissedSets {
        Assert-Parameter LogFilePrefix -Type String -Mandatory:$False
        Assert-Parameter ArchivePath -Type String -Mandatory
        Assert-Parameter TenantID -ParameterSet SingleArchive, BackupWithRepoFiles
        Assert-Parameter DatabaseBackup -Type String -Mandatory -ParameterSet BackupWithRepoFiles
        Assert-Parameter RepositoryFilesFolder -Type String -Mandatory
    }
```

A more specific test of the same commands would require specifying every parameter set, and even duplicating parameters which appear in more than one parameter set unless they appear in ALL parameter sets:

```PowerShell
    Test-ParametersOf -Command Import-QMTenant {
        Assert-Parameter LogFilePrefix -Type String -Mandatory:$False

        Select-ParameterSet SingleArchive {
            Assert-Parameter ArchivePath -Type String -Mandatory
            Assert-Parameter TenantID -Type String -Mandatory
        }
        Select-ParameterSet BackupWithRepoFiles {
            Assert-Parameter DatabaseBackup -Type String -Mandatory
            Assert-Parameter RepositoryFilesFolder -Type String -Mandatory
            Assert-Parameter TenantID -Type String -Mandatory
        }

        Select-ParameterSet ThirdParameterSet { }
    }
```

For historical reasons, the original versions of Get-Parameter:

    Version 0.80 - April 2008 - By Hal Rottenberg http://poshcode.org/186
    Version 0.81 - May 2008 - By Hal Rottenberg http://poshcode.org/255
    Version 0.90 - June 2008 - By Hal Rottenberg http://poshcode.org/445
    Version 0.91 - June 2008 - By Oisin Grehan http://poshcode.org/446
    Version 0.92 - April 2008 - By Hal Rottenberg http://poshcode.org/549
                - ADDED resolving aliases and avoided empty output
    Version 0.93 - Sept 24, 2009 - By Hal Rottenberg http://poshcode.org/1344
    Version 1.0  - Jan 19, 2010 - By Joel Bennett http://poshcode.org/1592
                - Merged Oisin and Hal's code with my own implementation
                - ADDED calculation of dynamic paramters
    Version 2.0  - July 22, 2010 - By Joel Bennett http://poshcode.org/get/2005
                - CHANGED uses FormatData so the output is objects
                - ADDED calculation of shortest names to the aliases (idea from Shay Levy http://poshcode.org/1982,
                  but with a correct implementation)
    Version 2.1  - July 22, 2010 - By Joel Bennett http://poshcode.org/2007
                - FIXED Help for SCRIPT file (script help must be separated from #Requires by an emtpy line)
                - Fleshed out and added dates to this version history after Bergle's criticism ;)
    Version 2.2  - July 29, 2010 - By Joel Bennett http://poshcode.org/2030
                - FIXED a major bug which caused Get-Parameters to delete all the parameters from the CommandInfo
    Version 2.3  - July 29, 2010 - By Joel Bennett
                - ADDED a ToString ScriptMethod which allows queries like:
                  $parameters = Get-Parameter Get-Process; $parameters -match "Name"
    Version 2.4  - July 29, 2010 - By Joel Bennett http://poshcode.org/2032
                - CHANGED "Name" to CommandName
                - ADDED ParameterName parameter to allow filtering parameters
                - FIXED bug in 2.3 and 2.2 with dynamic parameters
    Version 2.5  - December 13, 2010 - By Jason Archer http://poshcode.org/2404
                - CHANGED format temp file to have static name, prevents bloat of random temporary files
    Version 2.6  - July 23, 2011 - By Jason Archer http://poshcode.org/2815
                - FIXED miscalculation of shortest unique name (aliases count as unique names),
                  this caused some parameter names to be thrown out (like "Object")
                - CHANGED code style cleanup
    Version 2.7  - November 28, 2012 - By Joel Bennett http://poshcode.org/3794
                - Added * indicator on default parameter set.
    Version 2.8  - August 27, 2013 - By Joel Bennett http://poshcode.org/4438
                - Added SetName filter
                - Add * on the short name in the aliases list (to distinguish it from real aliases)
                  FIXED PowerShell 4 Bugs:
                - Added PipelineVariable to CommonParameters
                  FIXED PowerShell 3 Bugs:
                - Don't add to the built-in Aliases anymore, it changes the command!
    Version 2.9  - July 13, 2015 - By Joel Bennett
                - FIXED (hid) exceptions when looking for dynamic parameters
                - CHANGE to only search for provider parameters on Microsoft.PowerShell.Management commands (BUG??)
                - ADDED SkipProviderParameters switch to manually disable looking for provider parameters (faster!)
                - ADDED "Name" alias for CommandName to fix piping Get-Command output