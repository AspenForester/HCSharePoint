Get-module HCSharepoint | Remove-Module

Import-Module .\HCSharepoint

InModuleScope "HCSharepoint" {
    $URI = 'https://team.hennepin.us/VEX'
    $ListName = 'SolarWinds'
    Describe "Get-SPListItem" {
        Context 'Example 1: Get all records of list' {
            $list = hcsharepoint\Get-SPListItem -uri $URI -listname $ListName

            it 'Returns 91 items' {
                $list.count | should be 91
            }
        }
        Context 'Example 2: get only the first 27 records' {
            $list = hcsharepoint\Get-SPListItem -uri $URI -listname $ListName -SizeLimit 27

            it 'Returns 27 items' {
                $List.count | Should be 27
            }
        }
        Context 'Example 3: Get all records by specifying SizeLimit 0' {
            $list = hcsharepoint\Get-SPListItem -uri $URI -listname $ListName -SizeLimit 0

            it 'Returns all 91 items' {
                $List.count | Should be 91
            }
        }
        Context "Error 1: Can't reach SP site - behaves the same if the list is not available" {

            $URI = 'https://team.hennepin.us/VEZ'

            It 'Returns an error' {
                {hcsharepoint\Get-SPListItem -uri $URI -listname $ListName} | should Throw
            }
        }
    }
    Describe "Get-SPListField" {
        Context "Example 1: Get the user defined fields of the list" {
            $fields = Get-SPListField -uri $URI -list $ListName

            It 'returns 4 fields' {
                $fields.count | should be 4
            }
            it 'First field is "Title"' {
                $fields[0] | should be "Title"
            }
        }
    }
}