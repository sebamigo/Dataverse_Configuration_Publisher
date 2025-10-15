function Get-Reference {
    param (
        [string]$EntityLogicalName,
        [string]$Id
    )
    $guid = [System.Guid]::Parse($Id)
    return [EntityReference]::new($EntityLogicalName, $guid)
}

function Get-ReferenceByField {
    param (
        [string]$EntityLogicalName,
        [string]$Field,
        [string]$Operator,
        [string]$value,
        [object]$Connection
    )
    
    $fetchXml = "<fetch><entity name=""$EntityLogicalName""><attribute name=""$Field"" /><filter><condition attribute=""$Field"" operator=""$Operator"" value=""$value"" /></filter></entity></fetch>"
    $fetched = Get-CrmRecordsByFetchXml -conn $Connection -Fetch $fetchXml


    if ($fetched.Count -gt 0) {
        return $fetched.EntityReference
    } else {
        throw "No record found for $EntityLogicalName where $Field $Operator $value"
    }
}

function Get-SecRoleRef {
    param (
        [string]$SecRoleName,
        [string]$BusinessUnitName,
        [object]$Connection
    )
    $fetchXml = "<fetch><entity name=""role""><attribute name=""roleid"" /><filter><condition attribute=""name"" operator=""eq"" value=""$SecRoleName"" /></filter><link-entity name=""businessunit"" from=""businessunitid"" to=""businessunitid"" alias=""bu""><filter><condition attribute=""name"" operator=""eq"" value=""$BusinessUnitName"" /></filter></link-entity></entity></fetch>"
    $fetched = Get-CrmRecordsByFetchXml -conn $Connection -Fetch $fetchXml

    if ($fetched.Count -gt 0) {
        return $fetched.EntityReference
    } else {
        throw "No record found for role where name eq $SecRoleName and businessunitname eq $BusinessUnitName"
    }
}

function Get-File {
    param (
        [string]$Path,
        [string]$Encoding = "utf8"
    )
    return Get-Content -Path $Path -Encoding byte

    switch ($Encoding) {
        "utf8" { return [System.Text.Encoding]::UTF8.GetBytes($content) }
        "base64" { return [System.Convert]::FromBase64String($content) }
        default { throw "Unsupported encoding: $Encoding" }
    }
}