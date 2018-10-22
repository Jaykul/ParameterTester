function JoinObject {
    <#
        .SYNOPSIS
            Copies properties from from multiple objects to a new metadata object
        .NOTES
            Doesn't actually return the original object, but instead calls Select-Object on it, so all methods are lost.
    #>
    param(
        # The object to update
        [Parameter(Position = 0)]
        $First,

        # Object(s) to update from
        [Parameter(ValueFromPipeline = $true, Position = 1)]
        $Second
    )
    begin {
        [string[]] $p1 = $First | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
    }
    process {
        $Output = $First | Select-Object $p1
        foreach ($p in $Second | Get-Member -MemberType Properties | Where-Object {$p1 -notcontains $_.Name} | Select-Object -ExpandProperty Name) {
            Add-Member -InputObject $Output -MemberType NoteProperty -Name $p -Value $Second.("$p")
        }
        $Output
    }
}
