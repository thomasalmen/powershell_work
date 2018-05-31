        cNtfsPermissionEntry localusers
        {
            Ensure = 'Present'
            DependsOn = "[file]Folder1"
            Path = "d:\Easit"
            Principal = 'BUILTIN\Users'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'ReadAndExecute'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }

        cNtfsPermissionEntry jka091 {
            Ensure = 'Present'
            DependsOn = "[file]Folder1"
            Principal = "$($env:userdomain)\jka091"
            Path = 'd:\Easit'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'FullControl'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                })
        }

        #Permissions for admins
        cNtfsPermissionEntry AdminPermissions
        {
            Ensure = 'Present'
            Path = "d:\Easit"
            DependsOn = '[File]folder1'
            Principal = 'BUILTIN\Administrators'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderOnly'
                    NoPropagateInherit = $false
                }
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'ReadAndExecute'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'AppendData', 'CreateFiles'
                    Inheritance = 'SubfoldersAndFilesOnly'
                    NoPropagateInherit = $false
                }
            )
        
        }
        #Grupp dl_cayenne_easit_l read and execute
        cNtfsPermissionEntry dl_cayenne_easit_l
        {
            Ensure = 'Present'
            Path = "d:\Easit"
            DependsOn = '[File]folder1'
            Principal = 'dl_cayenne_easit_l'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'ReadAndExecute'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        
        }

        #Servicekonto srvacc_easit
        cNtfsPermissionEntry srvacc_easit
        {
            Ensure = 'Present'
            Path = "d:\Easit"
            DependsOn = '[File]folder1'
            Principal = 'srvacc_easit'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }