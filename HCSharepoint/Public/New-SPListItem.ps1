<#
  .Synopsis
    Creates a new record in a Sharepoint list
  .DESCRIPTION
    New-SPListItem takes a sharepoint site and the name of a list, plus an object mapping the field names and values, and creates a new 
    list record in the specified list.
  .EXAMPLE
	$RecordObject = [pscustomobject]@{
		PatchSchedule = "3rdTues2000"
		Environment   = "Development (Sandbox)"
		IsPhysical    = $true
		RAM           = 2
		Storage       = 26
		CPUs          = 2
		Cluster       = "DEVCluster"
		Title         = "hsdiamondvm001"
		}
    New-SPListItem -uri "https://my.sharepoint.local" -listname 'mylist' -record $RecordObject
  .EXAMPLE
    $RecordObject | New-SPListItem -uri "https://my.sharepoint.local" -listname 'mylist'
  .PARAMETER uri
    URI of the the sharepoint site to access.  Example: https://my.sharepoint.local/mysite
  .PARAMETER listname
    Name of the sharepoint list to access. In the uri "https://my.sharepoint.local/mysite/lists/mylist", "mylist" is the name of the list.
  .PARAMETER record
    A psobject with properties matching the fields of the list you are adding to.
  .LINK
    http://msdn.microsoft.com/en-us/library/office/fp179912(v=office.15).aspx#BasicOps_SPListItemTasks
#>
function New-SPListItem
{
    [CmdletBinding()]
    Param
    (
        # URI of the Sharepoint site.
        [Parameter(Mandatory = $true,
            Position = 0)]
        [string]
        $uri,
        # Name of the List we are adding a record to
        [Parameter(Mandatory = $true,
            Position = 1)]
        [string]
        $listname,
        # object with properties correlating to the list's fields, each property's value will be the value of the corresponding field.
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 2)]
        [pscustomobject]
        $record
    )
    Begin
    {
        # Get the _Case Sensitive_ fields for this list
        $Columns = Get-SPListField -uri $uri -listname $listname 
        
        $ClientContext = New-Object -TypeName Microsoft.SharePoint.Client.ClientContext($uri)
        $list = $ClientContext.Web.Lists.GetByTitle($listname)
    }
    Process
    {
        foreach ($record_item in $record)
        {
            $fields = $record_item.psobject.Properties.name
            
            $ItemCreateInfo = New-Object -TypeName Microsoft.SharePoint.Client.ListItemCreationInformation
            $NewItem = $list.AddItem($ItemCreateInfo)
        
            foreach ($field in $fields)
            {
                If (!($Columns -ccontains $field))
                {
                    Write-Verbose ("Correcting field input: {0}" -f $field)
                    # Correct the field's capitalization
                    $field = $Columns | Where-Object {$_ -eq $field}
                    Write-Verbose ("Corrected: {0}" -f $field)
                }
                if ($record_item.$field -ne "")
                {
                    $NewItem[$field] = $record_item.$field
                }
            }
            Write-Verbose ("Adding new record to list {0}" -f $listname)
            $NewItem.Update()
        }
    }
    End
    {
        $ClientContext.ExecuteQuery()
    }
}