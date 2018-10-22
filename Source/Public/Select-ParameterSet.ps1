function Select-ParameterSet {
    [CmdletBinding()]
    param($ParameterSetName, $ScriptBlock)
    begin {
        $script:Parameters = $script:Parameters | Where-Object { $_.ParameterSet -eq $ParameterSetName }

        if($Script:Parameters.Count -eq 0) {
            Write-Warning "There are no parameters in the $ParameterSetName parameter set"
        }

        $script:SetTestedParameters = @()
        $script:TestedParameterSets += $ParameterSetName
        $script:CurrentParameterSet = $ParameterSetName
        Context "In the '$ParameterSetName' parameter set" {
            & $ScriptBlock
        }
        It "Tested all the parameters in the $ParameterSetName parameter set" {
            # if there's a missing parameter here, it means not all the parameters were tested
            if ($missedParameters = $($script:Parameters | Where-Object { $_.Name -notin $script:SetTestedParameters -and $_.ParameterSets -notcontains "__AllparameterSets" }).Name  -join "', '") {
                throw "Missed testing '$missedParameters' in parameter set '$ParameterSetName'"
            }
        }
        if (!$script:AllowMissedSets) {
            $script:CurrentParameterSet = "__AllParameterSets"
        } else {
            $script:CurrentParameterSet = ""
        }
        $script:SetTestedParameters = @()
        $script:Parameters = $Script:AllParameters
    }
}
