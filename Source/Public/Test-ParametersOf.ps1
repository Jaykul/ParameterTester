function Test-ParametersOf {
<#
.EXAMPLE
    Test-ParametersOf -Command Import-QMTenant {
        Select-ParameterSet SingleArchive {
            Assert-Parameter ArchivePath -Type String -Mandatory
            Assert-Parameter TenantID -Type String -AllSets -Mandatory
            Assert-Parameter LogFilePrefix -Type String -AllSets -Mandatory:$False
        }
        Select-ParameterSet BackupWithRepoFiles {
            Assert-Parameter DatabaseBackup -Type String -Mandatory
            Assert-Parameter RepositoryFilesFolder -Type String -Mandatory
            Assert-Parameter TenantID -Type String -AllSets -Mandatory
            Assert-Parameter LogFilePrefix -Type String -AllSets -Mandatory:$False
        }
    }
#>
    [CmdletBinding()]
    param(
        [string]$CommandName,
        [ScriptBlock]$ScriptBlock,
        [switch]$AllowMissedSets
    )
    begin {
        $script:UsingCommand = $CommandName
        $script:Parameters = $script:AllParameters = Get-Parameter $script:UsingCommand
        $script:AllTestedParameters = @()
        $script:TestedParameterSets = @()

        # If they allow missed sets, we won't check parameters outside parameter set scope
        $script:AllowMissedSets = $AllowMissedSets
        if(!$AllowMissedSets) {
            $script:CurrentParameterSet = "__AllParameterSets"
        }
        Context "Parameter Requirements for $CommandName" {
            & $ScriptBlock

            # if there's a missing parameter here, it means not all the parameters were tested
            It "Tested all the parameters in the command" {
                if ($missedParameters = $($script:AllParameters | Where-Object { $_.Name -notin $script:AllTestedParameters }).Name  -join "', '") {
                    throw "Missed testing parameters: '$missedParameters'"
                }
            }
            if (!$AllowMissedSets) {
                It "Tested all the parameter sets in the command" {
                    if ($missedParameterSets = $($script:AllParameters | Where-Object { $_.ParameterSet -notin $script:TestedParameterSets }).ParameterSet -join "', '") {
                        throw "Missed testing parameter sets: '$missedParameterSets'"
                    }
                }
            }
        }

        $script:TestedParameterSets = @()
        $script:AllTestedParameters = @()
        $script:Parameters = $script:AllParameters = $null
        $script:UsingCommand = $null
    }
}
