<#
  .Synopsis
    Updates a property of a single list item in a sharepoint list.
  .DESCRIPTION
    updates the record identified by the ID, with the provided VALUE for the provided FIELD.  
    You can pipe a collection of changes to be made to the same list, the object needs to contain the ID, Field, and Value properties.  
    The changes are committed at the end of the Cmdlet.
  .EXAMPLE
    Update-SPListItem -uri "https://my.sharepoint.local" -listname 'mylist' -id 27 -field 'ipaddress' -value '127.0.0.1'
  .EXAMPLE
    $collection = import-csv my-list-changes.csv
    Update-SPListItem -uri "https://my.sharepoint.local" -listname 'mylist' -fields $collection
  .PARAMETER uri
    URI of the the sharepoint site to access.  Example: https://my.sharepoint.local/mysite
  .PARAMETER listname
    Name of the sharepoint list to access. In the uri "https://my.sharepoint.local/mysite/lists/mylist", "mylist" is the name of the list.
  .PARAMETER id
    Sharepoint record id to Update
  .PARAMETER field
    The column or field to update
  .PARAMETER value
    The new value for the field the cmdlet is updating.
  .PARAMETER fields
    A PSCustomObject representing one complete item from the list, which has had it's properties updated to reflect the desired change.
  .LINK
    http://msdn.microsoft.com/en-us/library/office/fp179912(v=office.15).aspx#BasicOps_SPListItemTasks
#>
function Update-SPListItem
{

    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = "Multi")]
    
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            Position = 0)]
        [string]
        $uri,

        # Param2 help description
        [Parameter(Mandatory = $true,
            Position = 1)]
        [string]
        $listname,

        # Record ID
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Single",
            Position = 2)]
        [int]
        $id,

        # Name of Field to update
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Single")]
        [string]
        $field,

        # Value for the updated field
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Single")]
        $value,

        # Object representing a record to update
        [Parameter(Mandatory = $true,
        ValueFromPipeline = $true,
            ParameterSetName = "Multi" )]
        [PSCustomObject]
        $fields
    )

    Begin
    {
        # Get the _Case Sensitive_ fields for this list
        $Columns = Get-SPListField -uri $uri -listname $listname        
        
        $clientContext = New-Object -TypeName Microsoft.SharePoint.Client.ClientContext($uri)
        $list = $ClientContext.Web.Lists.GetByTitle($listname)

    }
    Process
    {
        Write-Verbose "Parameter Set $($pscmdlet.ParameterSetName)" -Verbose
        $hash = @{}
        switch ($pscmdlet.ParameterSetName)
        {
            "Multi"
            {
                #Make sure we have the record ID
                if (!($id)) # We didn't get the ID as a stand alone parameter
                {
                    # Test for the existence of an id property in the input object
                    if (-not $fields.psobject.properties -contains "id")
                    {
                        throw "No ID value was provided, unable to determine which record to update!"
                    }
                    else
                    {
                        $id = $fields.id 
                    }
                } 

                foreach ($pair in $fields.psobject.properties)
                { 
                    # Only include the user Columns in the hash table
                    if ($Columns -contains $pair.Name)
                    { 
                        $hash[$pair.Name] = $pair.Value
                    }  
                }
            }
            "Single"
            {
                $hash[$field] = $value
            }
        }

        # Get the List Item
        $listitem = $list.GetItemById($id)

        # Loop through the items in the hash table and update the hashtable that is $listitem
        foreach ($key in $hash.Keys)
        {
            # Sharepoint is case sensitive - correct the case mismatch
            If (!($Columns -ccontains $key))
            {
                Write-Verbose ("Correcting field input: {0}" -f $key)
                # Correct the field's (key's) capitalization
                $key = $Columns | Where-Object {$_ -eq $key}
                Write-Verbose ("Corrected: {0}" -f $key)
            }
             
            Write-Verbose ("Updating Record {0}, Field {1} with {2}" -f $id, $key, $value)   
            $listitem[$key] = $hash[$key]
        }

        # Update the sharepoint object in memory
        $listitem.Update()
    }
    End
    {
        # Commit the changes back to the Sharepoint server
        if ($pscmdlet.ShouldProcess("Item $id", "Update"))
        {
            Write-Verbose ("Committing update to Record {0}" -f $id)
            $ClientContext.ExecuteQuery()
        }
    }
}
