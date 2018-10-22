    $ParameterPropertySet = @(
        "Name",
        @{Name = "Position";                        Expr = {if ($_.Position -lt 0) { "Named" } else { $_.Position } }},
        "Aliases",
        @{Name = "Type";                            Expr = {$_.ParameterType.Name}},
        @{Name = "ParameterSet";                    Expr = {$paramset}},
        @{Name = "Command";                         Expr = {$command}},
        @{Name = "Mandatory";                       Expr = {$_.IsMandatory}},
        @{Name = "Dynamic";                         Expr = {$_.IsDynamic}},
        @{Name = "Provider";                        Expr = {$_.DynamicProvider}},
        "ValueFromPipeline",
        "ValueFromPipelineByPropertyName",
        "ValueFromRemainingArguments",
        "ParameterSets"
    )

function Get-Parameter {
    <#
        .SYNOPSIS
            Enumerates the parameters of one or more commands
        .DESCRIPTION
            Returns the parameters of a command by ParameterSet. Note that this means duplicates for parameters which exist in multiple parameter sets.

            When used with -Force, includes the common parameters.

        .EXAMPLE
            Get-Command Select-Xml | Get-Parameter

        .EXAMPLE
            Get-Parameter Select-Xml
    #>
    [CmdletBinding(DefaultParameterSetName = "ParameterName")]
    param(
        # The name of the command to get parameters for
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Name")]
        [string[]]$CommandName,

        # The parameter name to filter by (Supports Wildcards)
        [Parameter(Position = 2, ValueFromPipelineByPropertyName = $true, ParameterSetName = "FilterNames")]
        [string[]]$ParameterName = "*",

        # The ParameterSet name to filter by (Supports Wildcards)
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "FilterSets")]
        [string[]]$SetName = "*",

        # Optionally, the name of a specific module which contains the command (this is for scoping)
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        $ModuleName,

        # Skip testing for dynamic provider parameters (will be much faster, and equally accurate for most commands)
        [Switch]$SkipProviderParameters,

        # Forces including the CommonParameters in the output
        [switch]$Force
    )

    process {
        foreach ($cmd in $CommandName) {
            if ($ModuleName) {
                $cmd = "$ModuleName\$cmd"
            }
            Write-Verbose "Searching for $cmd"
            $commands = @(Get-Command $cmd)

            foreach ($command in $commands) {
                Write-Verbose "Searching for $command"
                # resolve aliases (an alias can point to another alias)
                while ($command.CommandType -eq "Alias") {
                    $command = @(Get-Command ($command.definition))[0]
                }
                if (-not $command) {
                    continue
                }

                Write-Verbose "Get-Parameters for $($Command.Source)\$($Command.Name)"

                $Parameters = @{}

                ## We need to detect provider parameters ...
                $NoProviderParameters = !$SkipProviderParameters
                ## Shortcut: assume only the core commands get Provider dynamic parameters
                if (!$SkipProviderParameters -and $Command.Source -eq "Microsoft.PowerShell.Management") {
                    ## The best I can do is to validate that the command has a parameter which could accept a string path
                    foreach ($param in $Command.Parameters.Values) {
                        if (([String[]], [String] -contains $param.ParameterType) -and ($param.ParameterSets.Values | Where { $_.Position -ge 0 })) {
                            $NoProviderParameters = $false
                            break
                        }
                    }
                }

                if ($NoProviderParameters) {
                    if ($Command.Parameters) {
                        AddParameter $Parameters $Command.Parameters.Values
                    }
                } else {
                    foreach ($provider in Get-PSProvider) {
                        if ($provider.Drives.Length -gt 0) {
                            $drive = Get-Location -PSProvider $Provider.Name
                        } else {
                            $drive = "{0}\{1}::\" -f $provider.ModuleName, $provider.Name
                        }
                        Write-Verbose ("Get-Command $command -Args $drive | Select -Expand Parameters")

                        try {
                            $MoreParameters = (Get-Command $command -Args $drive).Parameters.Values
                        } catch {
                        }

                        if ($MoreParameters.Length -gt 0) {
                            AddParameter $Parameters $MoreParameters
                        }
                    }
                    # If for some reason none of the drive paths worked, just use the default parameters
                    if ($Parameters.Length -eq 0) {
                        if ($Command.Parameters) {
                            AddParameter $Parameters $Command.Parameters.Values
                        }
                    }
                }

                ## Calculate the shortest distinct parameter name -- do this BEFORE removing the common parameters or else.
                $Aliases = $Parameters.Values | Select-Object -ExpandProperty Aliases  ## Get defined aliases
                $ParameterNames = $Parameters.Keys + $Aliases
                foreach ($p in $($Parameters.Keys)) {
                    $short = "^"
                    $aliases = @($p) + @($Parameters.$p.Aliases) | sort { $_.Length }
                    $shortest = "^" + @($aliases)[0]

                    foreach ($name in $aliases) {
                        $short = "^"
                        foreach ($char in [char[]]$name) {
                            $short += $char
                            $mCount = ($ParameterNames -match $short).Count
                            if ($mCount -eq 1 ) {
                                if ($short.Length -lt $shortest.Length) {
                                    $shortest = $short
                                }
                                break
                            }
                        }
                    }
                    if ($shortest.Length -lt @($aliases)[0].Length + 1) {
                        # Overwrite the Aliases with this new value
                        $Parameters.$p = $Parameters.$p | Add-Member NoteProperty Aliases ($Parameters.$p.Aliases + @("$($shortest.SubString(1))*")) -Force -Passthru
                    }
                }

                # Write-Verbose "Parameters: $($Parameters.Count)`n $($Parameters | ft | out-string)"
                $CommonParameters = [string[]][System.Management.Automation.Cmdlet]::CommonParameters

                foreach ($paramset in @($command.ParameterSets | Select-Object -ExpandProperty "Name")) {
                    $paramset = $paramset | Add-Member -Name IsDefault -MemberType NoteProperty -Value ($paramset -eq $command.DefaultParameterSet) -PassThru
                    foreach ($parameter in $Parameters.Keys | Sort-Object) {
                        # Write-Verbose "Parameter: $Parameter"
                        if (!$Force -and ($CommonParameters -contains $Parameter)) {
                            continue
                        }
                        if ($Parameters.$Parameter.ParameterSets.ContainsKey($paramset) -or $Parameters.$Parameter.ParameterSets.ContainsKey("__AllParameterSets")) {
                            $Update = if ($Parameters.$Parameter.ParameterSets.ContainsKey($paramset)) {
                                $Parameters.$Parameter.ParameterSets.$paramSet
                            } else {
                                $Parameters.$Parameter.ParameterSets.__AllParameterSets
                            }

                            JoinObject $Parameters.$Parameter $Update |
                                Add-Member NoteProperty -Name ParameterSets -Value $Parameters.$Parameter.ParameterSets.Keys -PassThru -Force |
                                Select-Object $ParameterPropertySet |
                                ForEach-Object {
                                    $null = $_.PSTypeNames.Insert(0, "System.Management.Automation.ParameterMetadata")
                                    $null = $_.PSTypeNames.Insert(0, "System.Management.Automation.ParameterMetadataEx")
                                    $_
                                } |
                                Add-Member ScriptMethod ToString { $this.Name } -Force -Passthru |
                                Where-Object {
                                    $(foreach ($pn in $ParameterName) {
                                        $_ -like $Pn
                                    }) -contains $true
                                } |
                                Where-Object {
                                    $(foreach ($sn in $SetName) {
                                        $_.ParameterSet -like $sn
                                    }) -contains $true
                                }

                        }
                    }
                }
            }
        }
    }
}
