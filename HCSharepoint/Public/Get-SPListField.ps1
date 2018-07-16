<#
  .Synopsis
    Returns the names of the fields in the specified sharepoint list
  .DESCRIPTION
    Takes a site URL and a list name and returns a collection of strings representing the fields in the list.
  .EXAMPLE
    Get-SPListField -uri "https://my.sharepoint.local/mysite" -list "testlist"
  .PARAMETER uri
    URI of the the sharepoint site to access.  Example: https://my.sharepoint.local/mysite
  .PARAMETER listname
    Name of the sharepoint list to access. In the uri "https://my.sharepoint.local/mysite/lists/mylist", "mylist" is the name of the list.
  .PARAMETER Credential
    Credential to authenticate to the SharePoint server.  
  .LINK
    http://msdn.microsoft.com/en-us/library/office/fp179912(v=office.15).aspx#BasicOps_SPListItemTasks
#>
Function Get-SPListField
{
    [CmdletBinding()]
    
    Param
    (
        # URI of sharepoint site
        [Parameter(Mandatory = $true,
            Position = 0)]
        [string]
        $uri,
        # Name of the list to retrieve
        [Parameter(Mandatory = $true,
            Position = 1)]
        [string]
        $listname,

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
                $ConnectParam = @{
                    URI = $uri
                }
                If ($PSBoundParameters['Credential'])
                {
                    $ConnectParam.Add('Credential',$Credential)

                }
                if ($PSBoundParameters['UseADFS']) 
                {
                    $ConnectParam.Add('UseADFS',$UseADFS)
                }
                Connect-SPWebApp @ConnectParam -ErrorAction Stop
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
        # These are the Sharepoint common fields, someone adding a record would not want to attempt to write to one of these.
        $exclude = ("ContentVersion", "ContentTypeId", "_ModerationComments", "File_x0020_Type", "LinkTitleNoMenu",
            "LinkTitle", "LinkTitle2", "Author", "Editor", "Modified", "Created", "ID", "ContentType",
            "_HasCopyDestinations", "_CopySource", "owshiddenversion", "WorkflowVersion",
            "_UIVersion", "_UIVersionString", "Attachments", "_ModerationStatus", "Edit",
            "SelectTitle", "InstanceID", "Order", "GUID", "WorkflowInstanceID", "FileRef",
            "FileDirRef", "Last_x0020_Modified", "Created_x0020_Date", "FSObjType",
            "SortBehavior", "PermMask", "FileLeafRef", "UniqueId", "SyncClientId", "ProgId",
            "ScopeId", "HTML_x0020_File_x0020_Type", "_EditMenuTableStart",
            "_EditMenuTableStart2", "_EditMenuTableEnd", "LinkFilenameNoMenu", "LinkFilename",
            "LinkFilename2", "DocIcon", "ServerUrl", "EncodedAbsUrl", "BaseName", "MetaInfo",
            "_Level", "_IsCurrentVersion", "ItemChildCount", "FolderChildCount", "AppAuthor",
            "AppEditor", "Restricted")

        # Connection information is held as a Script Scope variable!
        $Lists = Get-PnPList
        # Case Sensitive List Name
        $CSList = ($Lists | Where-Object Title -like $listname).Title
       
        $ListFields = Get-PnPField -Identity -List $CSList 

        $ListFields.InternalName | Where-Object {$exclude -NotContains $_}
    }
}