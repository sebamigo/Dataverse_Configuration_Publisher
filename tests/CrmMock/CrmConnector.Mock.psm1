function Get-CrmConnection {
    [OutputType([CrmServiceClient])]
    param (
        [string]$ConnectionString = "",
        [switch]$InteractiveMode
    )

    # This is a mock function. In a real scenario, this would create and return a CrmServiceClient object.
    if ($InteractiveMode) {
        return [CrmServiceClient]::new("Mocked Connection", $true)
    } elseif ($ConnectionString -ne "") {
        return [CrmServiceClient]::new("Mocked Connection", $true)
    } else {
        throw "No connection string provided and interactive mode not set."
    }
}

function Get-CrmRecordsByFetchXml {
    param (
        [string]$FetchXml,
        [object]$CrmConnection
    )

    # This is a mock function. In a real scenario, this would execute the FetchXML query and return records.
    return @(
        [PSCustomObject]@{ EntityReference = @{ Id = [Guid]::NewGuid(); LogicalName = "mocked_entity" }; Name = "Mocked Record 1" },
        [PSCustomObject]@{ EntityReference = @{ Id = [Guid]::NewGuid(); LogicalName = "mocked_entity" }; Name = "Mocked Record 2" }
    )
}

function Set-CrmRecord {
    param (
        [object]$conn,
        [string]$EntityLogicalName,
        [string]$Id,
        [hashtable]$Fields,
        [switch]$Upsert
    )


    # This is a mock function. In a real scenario, this would create or update a record in CRM.
    if (-not $Fields) { $Fields = @{} }

    try {
        if ($Id -and $Id -ne '') {
            $guid = [Guid]::Parse($Id)
        } else {
            $guid = [Guid]::NewGuid()
        }
    } catch {
        $guid = [Guid]::NewGuid()
    }

    $eref = [EntityReference]::new($EntityLogicalName, $guid)

    $Global:CrmStore.AddOrUpdateRecord($eref, $Fields)

    Write-Host "Mocked setting record in entity '$EntityLogicalName' with Id '$($guid)' and fields: $($Fields | Out-String)"
    return $guid
}


function Get-CrmRecord {
    param (
        [object]$conn,
        [string]$EntityLogicalName,
        [string]$Id
    )

    if (-not $Id) { return $null }

    try {
        $guid = [Guid]::Parse($Id)
    } catch {
        return $null
    }

    $eref = [EntityReference]::new($EntityLogicalName, $guid)
    if (-not $Global:CrmStore) { return $null }
    return $Global:CrmStore.GetRecord($eref)
}

function Get-CrmRecordByFields {
    param (
        [string]$EntityLogicalName,
        [hashtable]$Fields
    )

    if (-not $Fields -or $Fields.Count -eq 0) { return $null }

    foreach ($record in $Global:CrmStore.GetAllRecords()) {
        if ($record.Entity.LogicalName -ieq $EntityLogicalName) {
            $match = $true
            foreach ($key in $Fields.Keys) {
                if (-not $record.Fields.ContainsKey($key) -or $record.Fields[$key] -ne $Fields[$key]) {
                    $match = $false
                    break
                }
            }
            if ($match) {
                return $record
            }
        }
    }
    return $null
}

function Add-CrmAssociation {
    param (
        [object]$conn,
        [string]$Entity1LogicalName,
        [string]$Entity1Id,
        [string]$Entity2LogicalName,
        [string]$Entity2Id,
        [string]$RelationshipName
    )

    if (-not $Entity1LogicalName) { throw [System.ArgumentNullException]::new('Entity1LogicalName') }
    if (-not $Entity1Id) { throw [System.ArgumentNullException]::new('Entity1Id') }
    if (-not $Entity2LogicalName) { throw [System.ArgumentNullException]::new('Entity2LogicalName') }
    if (-not $Entity2Id) { throw [System.ArgumentNullException]::new('Entity2Id') }
    if (-not $RelationshipName) { throw [System.ArgumentNullException]::new('RelationshipName') }

    try {
        $guid1 = [Guid]::Parse($Entity1Id)
    } catch {
        throw "Invalid GUID format for Entity1Id: '$Entity1Id'"
    }

    try {
        $guid2 = [Guid]::Parse($Entity2Id)
    } catch {
        throw "Invalid GUID format for Entity2Id: '$Entity2Id'"
    }

    $eref1 = [EntityReference]::new($Entity1LogicalName, $guid1)
    $eref2 = [EntityReference]::new($Entity2LogicalName, $guid2)

    if (-not $Global:CrmStore) { throw "Global CrmStore is not initialized." }
    $Global:CrmStore.AddRelation($eref1, $eref2, $RelationshipName)

    Write-Host "Mocked adding association between '$($eref1.ToString())' and '$($eref2.ToString())' with relationship '$RelationshipName'"
}

function Remove-CrmAssociation {
    param (
        [object]$conn,
        [string]$Entity1LogicalName,
        [string]$Entity1Id,
        [string]$Entity2LogicalName,
        [string]$Entity2Id,
        [string]$RelationshipName
    )

    if (-not $Entity1LogicalName) { throw [System.ArgumentNullException]::new('Entity1LogicalName') }
    if (-not $Entity1Id) { throw [System.ArgumentNullException]::new('Entity1Id') }
    if (-not $Entity2LogicalName) { throw [System.ArgumentNullException]::new('Entity2LogicalName') }
    if (-not $Entity2Id) { throw [System.ArgumentNullException]::new('Entity2Id') }
    if (-not $RelationshipName) { throw [System.ArgumentNullException]::new('RelationshipName') }

    try {
        $guid1 = [Guid]::Parse($Entity1Id)
    } catch {
        throw "Invalid GUID format for Entity1Id: '$Entity1Id'"
    }

    try {
        $guid2 = [Guid]::Parse($Entity2Id)
    } catch {
        throw "Invalid GUID format for Entity2Id: '$Entity2Id'"
    }

    $eref1 = [EntityReference]::new($Entity1LogicalName, $guid1)
    $eref2 = [EntityReference]::new($Entity2LogicalName, $guid2)

    if (-not $Global:CrmStore) { throw "Global CrmStore is not initialized." }

    $key = ("{0}|{1}|{2}" -f $eref1.ToString(), $eref2.ToString(), $RelationshipName)

    if ($Global:CrmStore.Relations.ContainsKey($key)) {
        $Global:CrmStore.Relations.Remove($key)
        Write-Host "Mocked removing association between '$($eref1.ToString())' and '$($eref2.ToString())' with relationship '$RelationshipName'"
    } else {
        Write-Host "No existing association found between '$($eref1.ToString())' and '$($eref2.ToString())' with relationship '$RelationshipName' to remove."
    }
}

class CrmServiceClient {
    [string]$ConnectionString
    [bool]$IsReady

    CrmServiceClient([string]$connStr, [bool]$isReady) {
        $this.ConnectionString = $connStr
        $this.IsReady = $isReady
    }
}

class EntityReference {
    [string]$LogicalName
    [Guid]$Id

    EntityReference([string]$logicalName, [Guid]$id) {
        $this.LogicalName = $logicalName
        $this.Id = $id
    }

    [string] ToString() {
        return "{0}:{1}" -f $this.LogicalName, $this.Id
    }

    [bool] Equals([object]$other) {
        if ($null -eq $other) { return $false }
        if (-not ($other -is [EntityReference])) { return $false }
        return ($this.LogicalName -ieq $other.LogicalName -and $this.Id -eq $other.Id)
    }

    [int] GetHashCode() {
        $key = ("{0}|{1}" -f $this.LogicalName.ToLowerInvariant(), $this.Id.ToString())
        return $key.GetHashCode()
    }
}


class CrmStore {
    [hashtable]$Records
    [hashtable]$Relations

    CrmStore() {
        $this.Records = @{}
        $this.Relations = @{}
    }

    [void] AddOrUpdateRecord([EntityReference]$entityRef, [hashtable]$fields) {
        if (-not $entityRef) { throw [System.ArgumentNullException]::new('entityRef') }
        if (-not $fields) { $fields = @{} }

        $storeValue = @{}
        foreach ($k in $fields.Keys) { $storeValue[$k] = $fields[$k] }

        $this.Records[$entityRef] = $storeValue
    }

    [hashtable] GetRecord([EntityReference]$entityRef) {
        if (-not $entityRef) { return $null }
        if ($this.Records.ContainsKey($entityRef)) { return $this.Records[$entityRef] }
        return $null
    }

    [void] AddRelation([EntityReference]$entity1Ref, [EntityReference]$entity2Ref, [string]$relationshipName) {
        if (-not $entity1Ref) { throw [System.ArgumentNullException]::new('entity1Ref') }
        if (-not $entity2Ref) { throw [System.ArgumentNullException]::new('entity2Ref') }
        if (-not $relationshipName) { throw [System.ArgumentNullException]::new('relationshipName') }

        if (-not $this.Records.ContainsKey($entity1Ref)) {
            throw "Entity1Ref with logical name '$($entity1Ref.LogicalName)' and Id '$($entity1Ref.Id)' does not exist in Records."
        }
        if (-not $this.Records.ContainsKey($entity2Ref)) {
            throw "Entity2Ref with logical name '$($entity2Ref.LogicalName)' and Id '$($entity2Ref.Id)' does not exist in Records."
        }
        
        $key = ("{0}|{1}|{2}" -f $entity1Ref.ToString(), $entity2Ref.ToString(), $relationshipName)

        if ($this.Relations.ContainsKey($key)) {
            throw "Relation between '$($entity1Ref.ToString())' and '$($entity2Ref.ToString())' with name '$relationshipName' already exists."
        }

        $this.Relations[$key] = @{ Entity1 = $entity1Ref; Entity2 = $entity2Ref; Relationship = $relationshipName }
    }

    [System.Collections.ArrayList] GetAllRecords() {
        $list = [System.Collections.ArrayList]::new()
        foreach ($k in $this.Records.Keys) {
            $list.Add(@{ Entity = $k; Fields = $this.Records[$k] }) | Out-Null
        }
        return $list
    }

    [void] Reset() {
        $this.Records.Clear()
        $this.Relations.Clear()
    }
}
$global:CrmStore = [CrmStore]::new()