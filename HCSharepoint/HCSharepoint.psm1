# Module HCSharepoint

function Get-SPListItem
{
<#
.Synopsis
   Returns the items from the specified Sharepoint list.
.DESCRIPTION
   This function returns the contents of a specified sharepoint list.  
   The list items are returned as a collection of a custom object type, HC.Sharepoint.List.<name of list>
.EXAMPLE
   $mylist = Get-SPListItem -uri "https://team.hennepin.us/vex" -list "testlist"
   Returns the first 100 items in the list
.EXAMPLE
   $mylist = Get-SPListItem -uri "https://team.hennepin.us/vex" -list "testlist" -SizeLimit 27
   Returs the first 27 records as specified by the SizeLimit Parameter
.EXAMPLE
   $mylist = Get-SPListItem -uri "https://team.hennepin.us/vex" -list "testlist" -SizeLimit 0
   Returns all records in a list.
.PARAMETER uri
    URI of the the sharepoint site to access.  Example: https://my.sharepoint.local/mysite
.PARAMETER listname
    Name of the sharepoint list to access. In the uri "https://my.sharepoint.local/mysite/lists/mylist", "mylist" is the name of the list.
.PARAMETER SizeLimit
    The Number of records to return.  Default is "0" to return all records.
.LINK
    http://msdn.microsoft.com/en-us/library/office/fp179912(v=office.15).aspx#BasicOps_SPListItemTasks
#>
    [CmdletBinding()]  
    Param
    (
        # URI of the Sharepoint Site
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $uri,

        # Name of the list to access
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $listname,

        #Number of items to return
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [int]
        $SizeLimit = 0
    )

    Begin
    {
    }
    Process
    {
        # Connect to the Sharepoint Server
        $ClientContext = New-Object -TypeName Microsoft.SharePoint.Client.ClientContext($uri)

        # Get the List
        $List = $ClientContext.Web.Lists.GetByTitle($listname)
 
        If ($SizeLimit -ne 0) {
            Write-Verbose ('Only retrieving {0} records' -f $SizeLimit)
            $Query = [Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery($SizeLimit)
        } else {
            Write-Verbose "Retrieving all records"
            $Query = [Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery()
        }
		
        $Items = $List.GetItems($Query)

        $ClientContext.Load($Items)

        # Error handling!
        Try
            {
            $ErrorActionPreference = "Stop"
            $ClientContext.ExecuteQuery()
            }
        Catch
            {
            Write-Error $_.Exception.Message
            }
		Finally
			{
			$ErrorActionPreference = "Continue"
			}

        foreach ($Item in $Items) 
            { 
            $obj = New-Object -TypeName psobject 
            # Convert the hash table / dictionary object to a custom object
            foreach ($i in $Item.FieldValues) 
                { 
                foreach ($key in $i.keys) 
                    {
                    Add-Member -InputObject $obj -NotePropertyName $key -NotePropertyValue $i.Item($key)
                    }
                }
            $obj.psobject.TypeNames.Insert(0,"HC.Sharepoint.List.$listname")
            $obj
			}
		}
    End
    {
    }
}

function Update-SPListItem
{
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
.LINK
    http://msdn.microsoft.com/en-us/library/office/fp179912(v=office.15).aspx#BasicOps_SPListItemTasks
#>
    [CmdletBinding(SupportsShouldProcess=$true,
                   DefaultParameterSetName="Single")]
    
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   Position=0)]
        [string]
        $uri,

        # Param2 help description
        [Parameter(Mandatory=$true,
                   Position=1)]
        [string]
        $listname,

        #record ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName="Single",
                   Position=2)]
        [Parameter(ParameterSetName="Multi" )]
        [int]
        $id,

        #Name of Field to update
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName="Single")]
        [string]
        $field,

        # Value for the updated field
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName="Single")]
        $value,

        # Object representing a record to update
        [Parameter(Mandatory=$true,
				   ParameterSetName="Multi" )]
        [pscustomobject]
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
        $hash = @{}
        switch ($pscmdlet.ParameterSetName){
            "Multi" {
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

                foreach ($pair in $fields.psobject.properties) { 
                    # Only include the user Columns in the hash table
                    if ($Columns -contains $pair.Name)
                    { 
                        $hash[$pair.Name] = $pair.Value
                    }  
                }
            }
            "Single" {
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


function Remove-SPListItem
{
<#
.Synopsis
    Deletes the specified record from a sharepoint list
.DESCRIPTION
    Remove-SPListItem takes a sharepoint site and the name of a list and deletes the record specified by the ID parameter.
    The deletes are committed once all IDs are processed.
.EXAMPLE
    Remove-SPListItem -uri "https://team.hennepin.us/vex" -list "testlist" -id 14
.PARAMETER uri
    URI of the the sharepoint site to access.  Example: https://my.sharepoint.local/mysite
.PARAMETER listname
    Name of the sharepoint list to access. In the uri "https://my.sharepoint.local/mysite/lists/mylist", "mylist" is the name of the list.
.PARAMETER id
    Sharepoint record id to delete.
.LINK
    http://msdn.microsoft.com/en-us/library/office/fp179912(v=office.15).aspx#BasicOps_SPListItemTasks
#>
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="High")]
    
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   Position=0)]
        [string]
        $uri,
        # Param2 help description
        [Parameter(Mandatory=$true,
                   Position=1)]
        [string]
        $listname,
        #record ID
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=2)]
        [int]
        $id
    )
    Begin
    {
        # Load the required DLLs
        #Add-SPCSOM
        
        $ClientContext = New-Object -TypeName Microsoft.SharePoint.Client.ClientContext($uri)
        $list = $ClientContext.Web.Lists.GetByTitle($listname)
    }
    Process
    {
        $ListItem = $list.getItemById($id)
        Write-Verbose ("Removing record {0}" -f $id)
        if ($PSCmdlet.ShouldProcess($id,'Remove Item')){
            $ListItem.DeleteObject()
        }
    }
    End
    {
        $ClientContext.ExecuteQuery()
    }
}


function New-SPListItem
{
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
[CmdletBinding()]
    
    Param
    (
        # URI of the Sharepoint site.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $uri,
        # Name of the List we are adding a record to
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $listname,
        # object with properties correlating to the list's fields, each property's value will be the value of the corresponding field.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=2)]
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
        foreach ($record_item in $record){
            $fields = $record_item.psobject.Properties.name
            
            $ItemCreateInfo = New-Object -TypeName Microsoft.SharePoint.Client.ListItemCreationInformation
            $NewItem = $list.AddItem($ItemCreateInfo)
        
            foreach($field in $fields){
                If (!($Columns -ccontains $field)){
                    Write-Verbose ("Correcting field input: {0}" -f $field)
                    # Correct the field's capitalization
                    $field = $Columns | Where-Object {$_ -eq $field}
                    Write-Verbose ("Corrected: {0}" -f $field)
                }
                if ($record_item.$field -ne ""){
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


Function Get-SPListField
{
<#
.Synopsis
   Returns the names of the fields in the specified sharepoint list
.DESCRIPTION
   Takes a site URL and a list name and returns a collection of strings representing the fields in the list.
.EXAMPLE
   Get-SPListField -uri "https://team.hennepin.us/vex" -list "testlist"
.PARAMETER uri
    URI of the the sharepoint site to access.  Example: https://my.sharepoint.local/mysite
.PARAMETER listname
    Name of the sharepoint list to access. In the uri "https://my.sharepoint.local/mysite/lists/mylist", "mylist" is the name of the list.
.LINK
    http://msdn.microsoft.com/en-us/library/office/fp179912(v=office.15).aspx#BasicOps_SPListItemTasks
#>
[CmdletBinding()]
    
    Param
    (
        # URI of sharepoint site
        [Parameter(Mandatory=$true,
                   Position=0)]
        [string]
        $uri,
        # Name of the list to retrieve
        [Parameter(Mandatory=$true,
                   Position=1)]
        [string]
        $listname
    )

    # These are the Sharepoint common fields, someone adding a record would not want to attempt to write to one of these.
    $exclude = ("ContentTypeId","_ModerationComments","File_x0020_Type","LinkTitleNoMenu",
                "LinkTitle","LinkTitle2","Author","Editor","Modified","Created","ID","ContentType",
                "_HasCopyDestinations","_CopySource","owshiddenversion","WorkflowVersion",
                "_UIVersion","_UIVersionString","Attachments","_ModerationStatus","Edit",
                "SelectTitle","InstanceID","Order","GUID","WorkflowInstanceID","FileRef",
                "FileDirRef","Last_x0020_Modified","Created_x0020_Date","FSObjType",
                "SortBehavior","PermMask","FileLeafRef","UniqueId","SyncClientId","ProgId",
                "ScopeId","HTML_x0020_File_x0020_Type","_EditMenuTableStart",
                "_EditMenuTableStart2","_EditMenuTableEnd","LinkFilenameNoMenu","LinkFilename",
                "LinkFilename2","DocIcon","ServerUrl","EncodedAbsUrl","BaseName","MetaInfo",
                "_Level","_IsCurrentVersion","ItemChildCount","FolderChildCount","AppAuthor",
                "AppEditor")

    $ClientContext = New-Object -TypeName Microsoft.SharePoint.Client.ClientContext($uri)
       
    $List = $ClientContext.Web.Lists.GetByTitle($listname)

    Write-Verbose ("Retrieving the fields for list {0}" -f $listname)
    $ClientContext.Load($List.Fields)
    $ClientContext.ExecuteQuery()

    $List.Fields.InternalName | Where-Object {$exclude -NotContains $_}
}

#Export-ModuleMember -Function Get-SPListItem
#Export-ModuleMember -Function Update-SPListItem
#Export-ModuleMember -Function Remove-SPListItem
#Export-ModuleMember -Function New-SPListItem
#Export-ModuleMember -Function Get-SPListField
