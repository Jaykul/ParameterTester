function AddParameter {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Hashtable]$Parameters,

        [Parameter(Position = 1)]
        [System.Management.Automation.ParameterMetadata[]]$MoreParameters
    )

    foreach ($p in $MoreParameters | Where-Object { !$Parameters.ContainsKey($_.Name) } ) {
        Write-Debug ("INITIALLY: " + $p.Name)
        $Parameters.($p.Name) = $p | Select *
    }

    [Array]$Dynamic = $MoreParameters | Where-Object { $_.IsDynamic }
    if ($dynamic) {
        foreach ($d in $dynamic) {
            if (Get-Member -InputObject $Parameters.($d.Name) -Name DynamicProvider) {
                Write-Debug ("ADD:" + $d.Name + " " + $provider.Name)
                $Parameters.($d.Name).DynamicProvider += $provider.Name
            } else {
                Write-Debug ("CREATE:" + $d.Name + " " + $provider.Name)
                $Parameters.($d.Name) = $Parameters.($d.Name) | Select *, @{ n = "DynamicProvider"; e = { @($provider.Name) } }
            }
        }
    }
}
