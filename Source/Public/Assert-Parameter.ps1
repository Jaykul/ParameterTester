function Assert-Parameter {
    [CmdletBinding(DefaultParameterSetName = "ParameterName")]
    param(
        # The parameter name
        [Parameter(Mandatory, ParameterSetName = "ParameterName", Position=0)]
        [string]$Name,

        [string[]]$ParameterSet,

        [Parameter()]
        [Type]$Type,

        [switch]$Mandatory
    )
    $script:SetTestedParameters += $Name
    $script:AllTestedParameters += $Name

    $Text = "Has a$(if($Mandatory){" mandatory"}elseif($PSBoundParameters.ContainsKey("Mandatory")){"n optional"}) parameter $Name"
    if ($Type) {
        $Text += " of type [$Type]"
    }
    if($ParameterSet) {
        $Text += " in the parameter set$(if($ParameterSet.Count -gt 1){"s"}): '$($ParameterSet -join "','")'"
    } elseif ($script:CurrentParameterSet -eq "__AllParameterSets") {
        $Text += " in all parameter sets"
    }

    It $Text {
        $script:Parameters.Name | Should -Contain $Name
        $Parameter = $script:Parameters | Where-Object { $_.Name -eq $Name }

        if ($Mandatory) {
            $Parameter.Mandatory | ForEach-Object { $_ | Should -Be $True }
        } elseif($PSBoundParameters.ContainsKey("Mandatory")) {
            $Parameter.Mandatory | ForEach-Object { $_ | Should -Be $False }
        }

        if ($Type) {
            $Parameter.Type | Should -BeOfType $Type
        }

        if ($script:CurrentParameterSet -eq "__AllParameterSets") {
            $Parameter.ParameterSets | ForEach-Object { $_ | Should -Be @("__AllParameterSets") }
        }
        if($ParameterSet) {
            $Parameter.ParameterSets | Sort-Object -Unique | Should -Be ($ParameterSet | Sort-Object -Unique)
        }
    }

}