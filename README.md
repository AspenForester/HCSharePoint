# Introduction
The module provides PowerShell commands to access Sharepoint lists.

# Is this a good idea?
The text here is a little dry.  JB is trying his best.

# Getting Started
TODO: Guide users through getting your code up and running on their own system. In this section you can talk about:
1.	Installation process
2.	Software dependencies
3.	Latest releases
4.	API references

# Build and Test
TODO: Describe and show how to build your code and run the tests. 

# Contribute
TODO: Explain how other users and developers can contribute to make your code better. 

# References
https://social.technet.microsoft.com/wiki/contents/articles/29518.csom-sharepoint-powershell-reference-and-example-codes.aspx
https://github.com/SharePoint/PnP-PowerShell
https://joshmccarty.com/a-caml-query-quick-reference/

# Versions
1.1.2.0 - This is the version the Pester Tests were originated with.  Updates can be done with a pscustom object or with id, column, value trio.  
1.1.3.0 - Revised the processing of the Dictionary objects we get back from Sharepoint into pscustomobjects to greatly improve efficiency.  
1.1.4.0 - Addition of credential parameter.  
1.1.5.0 - Sanitized the code for public consumption.  

# ToDo
- Add a query option.  We now have the syntax for querying figured out in order to be able to document it
- If we allow queries, then I think we need to change the way we manage the number of returned items.
- Query syntax:

```
$Query = New-Object Microsoft.SharePoint.Client.CamlQuery
$Query.ViewXml = "<View><Query><Where><Eq><FieldRef Name='ID' /><Value Type='Integer'>1</Value></Eq></Where></Query></View>"
```

If you want to learn more about creating good readme files then refer the following [guidelines](https://www.visualstudio.com/en-us/docs/git/create-a-readme). You can also seek inspiration from the below readme files:
- [ASP.NET Core](https://github.com/aspnet/Home)
- [Visual Studio Code](https://github.com/Microsoft/vscode)
- [Chakra Core](https://github.com/Microsoft/ChakraCore)
