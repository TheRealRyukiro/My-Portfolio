
<#
Script Description:
    This script is made to make user creation a lot less work. (In my particular situation this also creates TS profiles)
    in order to create said user in my situation you must:
        - Create a user folder for them
        - Create a ts user folder
        - Create their normal AD
        - Create their ts AD
        - Give their accounts permissions to both their folders(Which are located in two different areas)
        - Remove Inheritance & Remove allusers from the ts.V2 folder
        - RDP into their account to test

        That can be a lot of work just to simply create a user. a lot of time wasted.
        With this script it does all of those steps besides the last one. All you have to do
        is RDP to make sure their stuff works

        *DISCLOSURE FOR GITHUB SCRIPT*
        I have Replaced any confidential values with a placeholder for the security of my work's network



TODO
    - Enclose the beginning inputs in a loop in case the user needs to fix what they typed
    - Prettify the script
#>




# Importing active directory
Import-Module ActiveDirectory
Import-Module NTFSSecurity

# Creating all the required variables to make the magic happen.
$usersPath = "PATH_TO_USER_FOLDER"
$tsPath = "PATH_TO_TS_PROFILE_FOLDER"
$date = Get-Date -Format "MM/dd/yyyy"

if(!($requestedBy = Read-Host -Prompt "Who is requesting this user's creation(Press Enter to use 'DEFAULT_VALUE')?")) {$requestedBy = "DEFAULT_VALUE"}
$firstName = Read-Host -Prompt "Enter the user's first name"
$lastName = Read-Host -Prompt "Enter the user's last name"
$userName = Read-Host -Prompt "Enter their username"
$userNamets = $userName + "ts"
$copyFrom = Read-Host -Prompt "What user do you want to copy from"
$copyFromts = $copyFrom + "ts"
$newUsersFolderFull = $usersPath + $userName
$newUsersFolderFullts = $tsPath + $userNamets + ".V2"
# Clearing the screen then asking the user to confirm if all entered settings look correct
Clear-Host

# Asking the user to confirm the details they entered.
Write-Output "New User will be:`n`n`nName:`t$firstName $lastName`nUser modeled after: `n`t`t$copyFrom`n`t`t`t&`n`t`t$copyFromts`n`nNew Folder will be:`n`t$newUsersFolderFull`n`t`t&`n`t$newUsersFolderFullts"
$confirm = Read-Host "`nConfirm? y/n"
 If(($confirm) -ne "y"){
     # End if the user doesn't type y
 }
 Else{
    # AD Creation
    # Getting the user to copy from & their ts equivalent
    Write-Output "Getting $copyFrom's information..."
    $userInstance = Get-ADUser -Identity $copyFrom
    Write-Output "$copyFrom's information retrieved!`nGetting $copyFromts's information..."
    $usertsInstance = Get-ADUser -Identity $copyFromts
    Write-Output "$copyFromts's information retrieved!`nCreating the default passwords..."


    # Setting the default passwords for the accounts
    $newUserPassword = "DEFAULT_USER_PASSWORD" | ConvertTo-SecureString -AsPlainText -Force
    $newUserPasswordts = "DEFAULT_PASSWORD_FOR_TS_PROFILE" | ConvertTo-SecureString -AsPlainText -Force
    Write-Output "Default passwords created!`nCreating $userName's user..."


    # Getting Logon Script Path
    $scriptPath = Get-ADUser -Identity $copyFrom -Properties ScriptPath | Select-Object -ExpandProperty ScriptPath
    $scriptPathts = Get-ADUser -Identity $copyFromts -Properties ScriptPath | Select-Object -ExpandProperty ScriptPath
    
    
    # Cleaning up the long unreadable command by splatting in a codeblock to be passed through the New-ADUser cmdlet

    $params = @{
        # All of the naming of the AD User & Basics
        Name = $userName;
        SAMAccountName = $userName;
        DisplayName = $userName;
        GivenName = $firstName;
        Surname = $lastName;
        UserPrincipalName = "$userName@DOMAIN";
        Description = "Created per $requestedBy $date";
        AccountPassword = $newUserPassword;


        # The instance to copy the main properties from
        Instance = $userInstance;
        
        
        # Directory & Path Properties
        HomeDirectory = $newUsersFolderFull;
        HomeDrive = "K:";
        ScriptPath = $scriptPath;


        # Boolean Properties
        CannotChangePassword = $true;
        PasswordNeverExpires = $true;
        Enabled = $true;
    }


    $paramsts = @{
        Name = $userNamets;
        SAMAccountName = $userNamets;
        DisplayName = $userNamets;
        GivenName = $firstName;
        Surname = $lastName;
        UserPrincipalName = "$userNamets@DOMAIN";
        Description = "Created per $requestedBy $date";
        AccountPassword = $newUserPasswordts;


        Instance = $usertsInstance;


        HomeDirectory = $newUsersFolderFull;
        HomeDrive = "K:";
        ScriptPath = $scriptPathts;

        # Boolean Properties
        Enabled = $true;
    }
    # Creating the new user
    New-ADUser @params
    Write-Output "$userName's user created!`nCreating $userNamets's user..."
    New-ADUser @paramsts
    Write-Output "$userNamets's user created!`nAdding $userName Terminal Service Profile Path Location..."
    # Get New User Details
    $ouPath = Get-ADUser $userName
    $ouPathts = Get-ADUser $userNamets
    $userLocation = $ouPath.DistinguishedName
    $userLocationts = $ouPathts.DistinguishedName
    # Add the remote desktop services profile path then move the new users to the correct folder
    $directoryEntry = [adsi]("LDAP://" + $userLocation)
    $directoryEntry.psbase.invokeSet("TerminalServicesProfilePath", "PATH_TO_TS_PROFILE\$userNamets")
    $directoryEntry.setInfo()
    Write-Output "Terminal Service Profile Path Location added!`nMoving users to their correct OU..."
    Move-ADObject -Identity $userLocation -TargetPath "OU=TARGET_OU,DC=DOMAIN"
    Move-ADObject -Identity $userLocationts -TargetPath "OU=TARGET_OU,DC=DOMAIN"
    Write-Output "Copying 'Member Of' of $copyFrom to $userName"
    Get-ADUser -Identity $copyFrom -Properties memberof | Select-Object -ExpandProperty memberof |  Add-ADGroupMember -Members $userName
    Get-ADUser -Identity $copyFromts -Properties memberof | Select-Object -ExpandProperty memberof |  Add-ADGroupMember -Members $userNamets
    Write-Output "'Member Of' Category copied!`nUsers are fully created and moved!`nCreating their folders"
    
    
    #Folder Creation
    #Rights
    $fullControl = [System.Security.AccessControl.FileSystemRights]"FullControl"
    $inheritanceFlag = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
    $propagationFlag = [System.Security.AccessControl.PropagationFlags]::None
    $type = [System.Security.AccessControl.AccessControlType]::Allow
    #Creating the normal user folder
    Write-Output "Creating user folder: "
    Write-Output "`tCreating folder..."
    New-Item $newUsersFolderFull -ItemType Directory | Out-Null
    Write-Output "`tFolder created at $newUsersFolderFull `n`tRemoving user folder inheritance..."
    icacls $newUsersFolderFull /inheritance:d | Out-Null
    Write-Output "`tFolder inheritance removed.`n`tGiving user folder permissions..."
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule @($userName, $fullControl, $inheritanceFlag, $propagationFlag, $type)
    $objACL = Get-ACL $newUsersfolderFull
    $objACL.AddAccessRule($AccessRule)
    Set-ACL $newUsersFolderFull $objACL
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule @($userNamets, $fullControl, $inheritanceFlag, $propagationFlag, $type)
    $objACL.AddAccessRule($AccessRule)
    Set-ACL $newUsersFolderFull $objACL
    Write-Output "`tPermissions given."
    Write-Output "`tUser folder created!"
    #Creating the ts user folder
    Write-Output "Creating TS user folder: "
    New-Item $newUsersFolderFullts -ItemType Directory | Out-Null
    Write-Output "`tFolder created at $newUsersFolderFullts `n`tRemoving user folder inheritance..."
    icacls $newUsersFolderFullts /inheritance:d | Out-Null
    Write-Output "`tFolder inheritance removed.`n`tGiving ts user folder permissions..."
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule @($userNamets, $fullControl, $inheritanceFlag, $propagationFlag, $type)
    $objACL = Get-ACL $newUsersfolderFullts
    $objACL.AddAccessRule($AccessRule)
    Set-ACL $newUsersFolderFullts $objACL
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule @($userName, $fullControl, $inheritanceFlag, $propagationFlag, $type)
    $objACL.AddAccessRule($AccessRule)
    Set-ACL $newUsersFolderFullts $objACL
    Remove-NTFSAccess -AccessRights FullControl -Account OHCCNO\CCNOUSERS -Path $newUsersFolderFullts -AccessType Deny -AppliesTo ThisFolderSubfoldersAndFiles
    Remove-NTFSAccess -AccessRights FullControl -Account OHCCNO\CCNOUSERS -Path $newUsersFolderFullts -AccessType Allow -AppliesTo ThisFolderSubfoldersAndFiles

    Write-Output "`tPermissions given."
    Write-Output "`tUser folder created!"
    
    Write-Output "`n`n`nUser successfully created!`n`tUser Folder:`n`t`t$newUsersFolderFull`n`tTS Folder:`n`t`t$newUsersFolderFullts"
 }

Read-Host -Prompt "User Creation Complete!`nPress enter to close the script..."
exit