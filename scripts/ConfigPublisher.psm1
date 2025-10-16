# Module-level type converters - created only once when the module is loaded
$script:TypeConverters = @{
    '$string'      = { param($propertyValue, $CrmConnection) [string] $propertyValue }
    '$decimal'     = { param($propertyValue, $CrmConnection) [decimal] $propertyValue }
    '$boolean'     = { param($propertyValue, $CrmConnection) [System.Convert]::ToBoolean($propertyValue) }
    '$optionset'   = { param($propertyValue, $CrmConnection) [Microsoft.Xrm.Sdk.OptionSetValue]::new([int]$propertyValue.Value) }
    '$ref'         = { param($propertyValue, $CrmConnection) Get-Reference -EntityLogicalName $propertyValue.LogicalName -Id $propertyValue.Id }
    '$refByField'  = { param($propertyValue, $CrmConnection) Get-ReferenceByField -EntityLogicalName $propertyValue.entity -Field $propertyValue.Field -Operator $propertyValue.Operator -Value $propertyValue.Value -Connection $CrmConnection }
    '$refBySecRole'= { param($propertyValue, $CrmConnection) Get-SecRoleRef -SecRoleName $propertyValue.SecRoleName -BusinessUnitName $propertyValue.BusinessUnitName -Connection $CrmConnection }
    '$file'        = { param($propertyValue, $CrmConnection) Get-File -FilePath $propertyValue.filePath -Encoding $propertyValue.Encoding }
}

function Publish-Configuration {
    param (
        [object[]]$Files,
        [object]$CrmConnection
    )

    foreach ($file in $Files)
    {
        Write-Log -ModuleName $MyInvocation.MyCommand.Name -Message "Processing file: $file"
        
        $jsonContent = Get-Content -Path $file -Raw | ConvertFrom-Yaml
        
        foreach ($record in $jsonContent.records)
        {
            $fields = FlatFieldsDatatypes $record.fields $CrmConnection
            Set-CrmRecord -conn $CrmConnection -EntityLogicalName $record.meta.logicalName -Id $record.meta.guid -Fields $fields -Upsert | Out-Null
        }
        
        foreach ($record in $jsonContent.relations)
        {
            $fields = FlatFieldsDatatypes $record $CrmConnection
            
            switch ($fields.func) {
                "Associate" {
                    Add-CrmAssociation -conn $CrmConnection -Entity1LogicalName $fields.recordRef1.logicalName -Entity1Id $fields.recordRef1.Id -Entity2LogicalName $fields.recordRef2.logicalName -Entity2Id $fields.recordRef2.Id -RelationshipName $fields.logicalName
                }
                "Disassociate" {
                    Remove-CrmAssociation -conn $CrmConnection -Entity1LogicalName $fields.recordRef1.logicalName -Entity1Id $fields.recordRef1.Id -Entity2LogicalName $fields.recordRef2.logicalName -Entity2Id $fields.recordRef2.Id -RelationshipName $fields.logicalName
                }
                default {
                    Write-Log -ModuleName $MyInvocation.MyCommand.Name -Message "Unknown function in relation file: $($file.FullName)"
                }
            }
        }
        
        Write-Log -ModuleName $MyInvocation.MyCommand.Name -Message "Successfully processed file: $($file.FullName)"
    }
}

function FlatFieldsDatatypes {
    param (
        [object]$jsonContent,
        [object]$CrmConnection
    )
    $processedProperties = @{}

    foreach ($key in $jsonContent.Keys) {

        $property = $jsonContent[$key]

        if($property -is [Hashtable]) {
            $typeDefinition = $property.Keys
            $propertyValue = $property.Values
            if ($typeDefinition.StartsWith("$")) {

                if ($script:TypeConverters.ContainsKey([string] $typeDefinition)) {
                    $flattedValue = ($script:TypeConverters[$typeDefinition]).Invoke($propertyValue, $CrmConnection)
                } else {
                    Write-Log -ModuleName $MyInvocation.MyCommand.Name -Message "Unknown extended datatype: $typeDefinition"
                    $flattedValue = $null
                }
                $processedProperties.Add($key, $flattedValue) | Out-Null
                continue
            }
        }
        $processedProperties.Add($key, $property) | Out-Null
    }
    return $processedProperties
}