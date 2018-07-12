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
  .EXAMPLE
    $collection = import-csv my-list-changes.csv
    $collection | Update-SPListItem -uri "https://my.sharepoint.local" -listname 'mylist'  
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
  .PARAMETER Credential
    Credential to authenticate to the SharePoint server.  
  .LINK
    http://msdn.microsoft.com/en-us/library/office/fp179912(v=office.15).aspx#BasicOps_SPListItemTasks
  .NOTES
    TODO: Pull the commit out of the End Block
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
            ParameterSetName = "Single")]
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
        $fields,

        # Credentials
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        # Use ADFS Authentication
        [Switch]
        $UseADFS   
    )

    Begin
    {
        # First we need to connect
        try 
        {
            # There's a chance I might have to deal with mulitple connections...
            # Ensure we are connected to the WebApp specified by $URI
            $Connection = Get-PnPConnection
            if ($Connection.url -ne $uri)
            {
                if ($PSBoundParameters['Credential'])
                {
                    $ConnectParam = @{
                        Credentials = $Credential
                    }
                }
                else
                {
                    $ConnectParam = @{
                        CurrentCredentials = $true
                    }
                }
                
                $Connection = Connect-PnPOnline -ReturnConnection -Url $uri -UseAdfs:$UseADFS -ErrorAction Stop
            }
        }
        catch 
        {
            # I might want to handle this differently in the future
            
            Throw $_
        }
    }
    Process
    {
        $Lists = Get-PnPList
        # Case Sensitive List Name
        $CSList = ($Lists | Where Title -like $listname).Title
        
        $Columns = Get-SPListField -uri $uri -listname $CSList
        
        Write-Verbose "Parameter Set $($pscmdlet.ParameterSetName)"
        
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
                $hash = @{}
                $FieldsExceptID = $fields.psobject.properties | where Name -ne 'ID'
                foreach ($pair in $FieldsExceptID)
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
                $hash = @{$field = $value}
            }
        }

        # Loop through the items in the hash table and update the hashtable that is $listitem
        foreach ($Pair in $hash)
        {
            # Sharepoint is case sensitive - correct the case mismatch
            if ($Pair.Key -cnotin $Columns)
            {
                Write-Verbose ("Correcting field input: {0}" -f $Pair.key)
                # Correct the field's (key's) capitalization
                $key = $Columns | Where-Object {$_ -eq $Pair.key}
                # Get the value of the pair
                $value = $hash[$key]
                # Delete the pair
                $hash.remove($key)
                # Recreate the pair with Case-correct key
                $hash[$Key] = $value
                Write-Verbose ("Corrected: {0}" -f $key)
            }
            # Need to end up with a hashtable with Case-corrected keys

            # Write-Verbose ("Updating Record {0}, Field {1} with {2}" -f $id, $key, $value)   
        }

        # Update the sharepoint object in memory
        if ($pscmdlet.ShouldProcess("List $CSList", "Update Record $id"))
        {
            Set-PnPListItem -List $CSList -Identity $id -Values $hash
        }
    }
    End
    {
    }
}
