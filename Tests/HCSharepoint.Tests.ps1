Get-module HCSharepoint | Remove-Module

Import-Module .\HCSharepoint

InModuleScope "HCSharepoint" {
    # Known info about the Sharepoint list we are testing against
    $URI = 'https://team.hennepin.us/VEX'
    $ListName = 'PrintFaxServices'
    $knownRecords = 78

    Describe "Get-SPListItem" {
        Context 'Example 1: Get all records of list' {
            $list = hcsharepoint\Get-SPListItem -uri $URI -listname $ListName

            it "Returns $knownRecords items" {
                $list.count | should be $knownRecords
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

            it "Returns all $knownRecords items" {
                $List.count | Should be $knownRecords
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
                $fields.count | should be 5
            }
            it 'First field is "Title"' {
                $fields[0] | should be "Title"
            }
        }
    }
    Describe "New-SPListItem" {
        $RecordObject = [pscustomobject]@{
            Title = "Monad"
            MachineName = "Monad"
            ServiceName = "Automator"
            Status = "hibernating"
        }
        Context "Example 1: Create a new record by paramter" {
            New-SPListItem -uri $URI -listname $ListName -record $RecordObject

            $ListItems = Get-SPListItem -uri $URI -listname $ListName 

            it "Now returns $($knownRecords + 1) Records" {
                $ListItems.count | should be ($knownRecords + 1)
            }
            it "Title of the last record is 'Monad'" {
                $ListItems | Select -Last 1 -ExpandProperty Title | Should be $RecordObject.Title
            }
        }
        Context "Example 2: New Record by piping the object in" {
            $RecordObject.Title = "Monad2"
            $RecordObject | New-SPListItem -uri $URI -listname $ListName

            it "Now returns $($knownRecords + 2) Records" {
                $ListItems.count | should be ($knownRecords + 2)
            }
            it "Title of the last record is 'Monad2'" {
                $ListItems | Select -Last 1 -ExpandProperty Title | Should be $RecordObject.Title
            }
        }
    }
}