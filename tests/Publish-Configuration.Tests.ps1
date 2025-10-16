# Requires Pester

Describe 'Publish-Configuration' {
    BeforeAll {
        ".\lib" | Get-ChildItem -Include "*.psm1", "*.ps1", "*.psd1" -Recurse -File | Import-Module
        Import-Module -Name (Join-Path $PSScriptRoot '..\scripts\ConfigPublisher.psm1') -Force -ErrorAction Stop
        
        # Create mocks
        Import-Module -Name (Join-Path $PSScriptRoot '.\CrmMock\CrmConnector.Mock.psm1') -Force -ErrorAction Stop
        $global:MockCrmConnection = [PSCustomObject]@{ ConnectionName = 'Mock' }

        Mock -CommandName Write-Log -MockWith { param($ModuleName,$Message) } -Verifiable        
        Mock -CommandName Get-Reference -MockWith { param($EntityLogicalName,$Id) return [PSCustomObject]@{ Ref = "$(${EntityLogicalName}):$(${Id})" } } -Verifiable
        Mock -CommandName Get-ReferenceByField -MockWith {
            param($EntityLogicalName,$Field,$Operator,$Value,$Connection)
            return (Get-CrmRecordByFields -EntityLogicalName $EntityLogicalName -Fields @{$Field = $Value}).Entity
        } -Verifiable
        Mock -CommandName Get-SecRoleRef -MockWith {
            param($SecRoleName,$BusinessUnitName,$Connection)
            return (Get-CrmRecordByFields -EntityLogicalName "role" -Fields @{name = $SecRoleName}).Entity
        } -Verifiable

    }

    AfterAll {
        # Clean up the mock CRM store
        $global:CrmStore.Reset()
    }

    Context 'when processing records' {
        It 'should create records and relationships as defined in the YAML files' {

            Set-CrmRecord -conn $CrmConnection -EntityLogicalName "role" -Id "fcd20aa8-0f13-4476-9280-047c6eddd15f" -Fields @{name = "Accounts Read & Write" } -Upsert | Out-Null
            Set-CrmRecord -conn $CrmConnection -EntityLogicalName "role" -Id "b343ddce-9225-4b99-a120-6c7c53331c21" -Fields @{name = "Projects Read & Write" } -Upsert | Out-Null
            Set-CrmRecord -conn $CrmConnection -EntityLogicalName "role" -Id "1cc6c2f9-fdb4-49b8-9e16-b02b074422cc" -Fields @{name = "Accounts Read Only" } -Upsert | Out-Null
            Set-CrmRecord -conn $CrmConnection -EntityLogicalName "role" -Id "1b226c5f-0422-4a82-a4ee-e12c94d91e12" -Fields @{name = "Projects Read Only" } -Upsert | Out-Null

            $allFiles = Get-ChildItem -Path ".\tests\TestConfigurations" -Filter "*.yaml" -Recurse -ErrorAction SilentlyContinue | Sort-Object file

            Publish-Configuration -Files $allFiles -CrmConnection $global:MockCrmConnection

            
            $global:CrmStore.Records.Count | Should -Be 11
            $global:CrmStore.Relations.Count | Should -Be 4
            
            # Verify that the expected security roles were related to the expected teams. Little hard to read, but works for now :D
            $global:CrmStore.Relations["team:0c6d8aa1-2269-4cea-84dd-3d998c6dad56|role:fcd20aa8-0f13-4476-9280-047c6eddd15f|teamroles_association"] | Should -Not -Be $null
            $global:CrmStore.Relations["team:0c6d8aa1-2269-4cea-84dd-3d998c6dad56|role:b343ddce-9225-4b99-a120-6c7c53331c21|teamroles_association"] | Should -Not -Be $null
            $global:CrmStore.Relations["team:c71716e4-f5b4-4ac0-b96f-a7d57d34754b|role:1cc6c2f9-fdb4-49b8-9e16-b02b074422cc|teamroles_association"] | Should -Not -Be $null
            $global:CrmStore.Relations["team:c71716e4-f5b4-4ac0-b96f-a7d57d34754b|role:1b226c5f-0422-4a82-a4ee-e12c94d91e12|teamroles_association"] | Should -Not -Be $null

        }
    }
}
