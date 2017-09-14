Get-module HCSharepoint | Remove-Module

Import-Module .\HCSharepoint

InModuleScope "HCSharepoint" {
    # Known info about the Sharepoint list we are testing against
    # https://team.hennepin.us/VEX/lists/PrintFaxServices
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
            Title       = "Monad"
            MachineName = "Monad"
            ServiceName = "Automator"
            Status      = "hibernating"
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

            $ListItems = Get-SPListItem -uri $URI -listname $ListName 
            it "Now returns $($knownRecords + 2) Records" {
                $ListItems.count | should be ($knownRecords + 2)
            }
            it "Title of the last record is 'Monad2'" {
                $ListItems | Select -Last 1 -ExpandProperty Title | Should be $RecordObject.Title
            }
        }
    }
    # These next tests assume that the previous ones passed
    Describe "Update-SPListItem" {
        $id = Get-SPListItem -uri $URI -listname $ListName | Select -Last 1 -ExpandProperty ID
        Context "Example 1: Update one Field of one record" {
            Update-SPListItem -uri $URI -listname $ListName -id $id -field MachineName -value "PowerShell"

            $listItem = Get-SPListItem -uri $URI -listname $ListName | Select -Last 1

            it "Changes the MachineName Property to 'PowerShell'" {
                $listItem.MachineName | Should be 'PowerShell'
            }
        }
        Context "Example 2: Update an item from a PSCustomObject" {
            $update = [PSCustomObject]@{
                ID     = $id
                Status = "Awake"
            }
            Update-SPListItem -uri $uri -listname $ListName -fields $update

            $listItem = Get-SPListItem -uri $URI -listname $ListName | Select -Last 1

            it "Status is now 'Awake'" {
                $listItem.Status | should be 'Awake'
            }
        }
        Context "Example 3: Piping a PSCustomObject" {
            $update = [PSCustomObject]@{
                ID     = $id
                Status = "Drowsy"
            }
            $update | Update-SPListItem -uri $uri -listname $ListName

            $listItem = Get-SPListItem -uri $URI -listname $ListName | Select -Last 1

            it "Status is now $($update.Status)" {
                $listItem.Status | should be $update.Status
            }
        }
        Context "Handling 1: Make an update with a wrong case column name" {
            Update-SPListItem -uri $URI -listname $ListName -id $id -field status -value "Sleepy"

            $listItem = Get-SPListItem -uri $URI -listname $ListName | Select -Last 1
            
            it "Status field correctly cased, and is now 'Sleepy'" {
                $listItem.Status | should be 'Sleepy'
            }
        }
        Context "Error 1: No ID property in the input object" {
            $update = [PSCustomObject]@{
                Title  = "Monad2"
                Status = "Awake"
            }

            it "throws when it doesn't know what record to update" {
                {Update-SPListItem -uri $uri -listname $ListName -fields $update } | Should Throw
            }
        }
    }
    Describe "Remove-SPListItem" {
        
        Context "Example 1: Remove item by ID" {
            $id = Get-SPListItem -uri $URI -listname $ListName | Select -Last 1 -ExpandProperty ID
            Remove-SPListItem -uri $URI -listname $ListName -id $id -Confirm:$false

            It "reduced the count to $($knownRecords + 1)" {
                (Get-SPListItem -uri $URI -listname $ListName).count | Should be ($knownRecords + 1)
            }
            $id = Get-SPListItem -uri $URI -listname $ListName | Select -Last 1 -ExpandProperty ID
            Remove-SPListItem -uri $URI -listname $ListName -id $id -Confirm:$false

            It "reduced the count to $knownRecords" {
                (Get-SPListItem -uri $URI -listname $ListName).count | Should be $knownRecords
            }

        }
    }
}
