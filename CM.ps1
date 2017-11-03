$ConfigData= 
@{ 
    AllNodes =
        @(
            @{ 
                NodeName= '*'
            },
            @{
                NodeName     = 'DSCServer02.do.local'
                Role         = 'SiteServer'                                       #Not yet used
                InstallPath  = 'C:\ConfigMgr'                                     #Where ConfigMgr will be installed
                CMAdmin      = 'do\SC_Admins'                                     #User or Group that will be added to the Full Administrators Group in ConfigMgr
                CMSiteCode   = 'DSC'                                              #ConfigMgr three digit Sitecode
                CMSiteName   = 'DSC Test Site'                                    #ConfigMgr Site Name / Description
                CMPrereqPath = "$env:windir\temp"                                 #Where ConfigMgr will download the Prereq files to or folder where you have already put them
                CMSourcePath = '\\dc01\Deployment\Source\SystemCenter\ConfigMgr'  #ConfigMgr installation sources (Computer account needs read permissions to that location)
            }
        );
}

configuration CM {
    param()

    #Import-DscResource -Module xSqlPs
    Import-DscResource -Module cConfigMgr

    Node $AllNodes.NodeName {
            WindowsFeature WebServer
                {
                    Ensure    = 'Present' # To uninstall the role, set Ensure to "Absent"
                    Name      = 'Web-Server'
                    #IncludeAllSubFeature = "true"  
                }
            WindowsFeature IISConsole
                {
                    Ensure    = 'Present' # To uninstall the role, set Ensure to "Absent"
                    Name      = 'Web-Mgmt-Console'
                    DependsOn = '[WindowsFeature]WebServer'  
                }
            WindowsFeature IISBasicAuth
                {
                    Ensure    = 'Present' # To uninstall the role, set Ensure to "Absent"
                    Name      = 'Web-Basic-Auth'
                    DependsOn = '[WindowsFeature]WebServer'
                }
            WindowsFeature IISWindowsAuth
                {
                    Ensure    = 'Present' # To uninstall the role, set Ensure to "Absent"
                    Name      = 'Web-Windows-Auth'
                    DependsOn = '[WindowsFeature]WebServer'
                }
            WindowsFeature IISURLAuth
                {
                    Ensure    = 'Present' # To uninstall the role, set Ensure to "Absent"
                    Name      = 'Web-Url-Auth'
                    DependsOn = '[WindowsFeature]WebServer'
                }
            WindowsFeature ASPNet45
                {
                    Ensure    = 'Present' # To uninstall the role, set Ensure to "Absent"
                    Name      = 'Web-Asp-Net45'
                    DependsOn = '[WindowsFeature]WebServer'
                }
            WindowsFeature RDC
                {
                    Ensure    = 'Present' # To uninstall the role, set Ensure to "Absent"
                    Name      = 'RDC'
                }
            WindowsFeature BITS
                {
                    Ensure    = 'Present' # To uninstall the role, set Ensure to "Absent"
                    Name      = 'BITS'
                }
            WindowsFeature DotNet35
                {
                    Ensure    = 'Present' # To uninstall the role, set Ensure to "Absent"
                    Name      = 'NET-Framework-Features'
                    Source    = '\\dc01\sources\OSD\OSSources\W16\sources\sxs'
                }
            WindowsFeature DotNet35Core
                {
                    Ensure    = 'Present' # To uninstall the role, set Ensure to "Absent"
                    Name      = 'NET-Framework-Core'
                    DependsOn = '[WindowsFeature]DotNet35'
                    Source    = '\\dc01\sources\OSD\OSSources\W16\sources\sxs'
                }
            WindowsFeature DotNet45Features
                {
                    Ensure    = 'Present' # To uninstall the role, set Ensure to "Absent"
                    Name      = 'NET-Framework-45-Features'
                }
            WindowsFeature DotNet45Core
                {
                    Ensure    = 'Present' # To uninstall the role, set Ensure to "Absent"
                    Name      = 'NET-Framework-45-Core'
                    DependsOn = '[WindowsFeature]DotNet45Features'
                }
            WindowsFeature NetWCFHTTPActivation
                {
                    Ensure    = 'Present' # To uninstall the role, set Ensure to "Absent"
                    Name      = 'NET-WCF-HTTP-Activation45'
                    DependsOn = '[WindowsFeature]DotNet45Features'
                }
            Package DeploymentTools
                {
                  Name       = "ADK Deployment Tools"
                  Path       = "\\dc01\deployment\Source\Prerequisites\ADK\adksetup.exe"
                  ProductId  = "FEA31583-30A7-0951-718C-AF75DCB003B1"
                  Arguments  = "/quiet /features OptionId.DeploymentTools /norestart "
                  Ensure     = "Present"
                  ReturnCode = 0
                }
            Package PreinstallationEnvironmentTools
                {
                  Name       = "ADK Preinstallation Environment"
                  Path       = "\\dc01\deployment\Source\Prerequisites\ADK\adksetup.exe"
                  ProductId  = "6FDE09DB-D711-593B-0823-D99D2A757227"
                  Arguments  = "/quiet /features OptionId.WindowsPreinstallationEnvironment /norestart "
                  Ensure     = "Present"
                  ReturnCode = 0
                } 
            Package UserStateMigrationTools
                {
                  Name       = "ADK Deployment Tools"
                  Path       = "\\dc01\deployment\Source\Prerequisites\ADK81\adksetup.exe"
                  ProductId  = "0C4384AC-02DB-B4E5-E537-EE6CF22392CF"
                  Arguments  = "/quiet /features OptionId.UserStateMigrationTool /norestart "
                  Ensure     = "Present"
                  ReturnCode = 0
                }
            Package MDT 
                {
                  Name       = "Microsoft Deployment Toolkit"
                  Path       = "\\dc01\deployment\Source\Prerequisites\MDT\MicrosoftDeploymentToolkit_x64.msi"
                  ProductId  = "9547DE37-4A70-4194-97EA-ACC3E747254B"
                  Arguments  = "/q /norestart"
                  Ensure     = "Present"
                  ReturnCode = 0
                }
            CMPrimarySite PrimarySite
                {
                    SiteCode   = "$($Node.CMSiteCode)"
                    SiteName   = "$($Node.CMSiteName)"
                    SQLServer  = "$($Node.NodeName)"
                    PrereqPath = "$($Node.CMPrereqPath)"
                    SourcePath = "$($Node.CMSourcePath)"
                    #SQLServerInstance = ''
                    DPServer  = "$($Node.NodeName)"
                    MPServer  = "$($Node.NodeName)"
                    SMSProviderServer = "$($Node.NodeName)"
                    InstallationDirectory = "$($Node.InstallPath)"
                    DependsOn =  @('[Package]DeploymentTools')
                }
            <#
            xSqlServerInstall installSqlServer
                {
                    InstanceName = ""
                    SourcePath = '\\dc01\Deployment\Source\SQL2016'
                    Features= "SQLEngine,SSMS"
                    SqlAdministratorCredential = $credential
                    SvcAccount = 'do\adobrien'
                    DependsOn = "[WindowsFeature]dotNet35"
                }
                # Disabled, because too many things missing, Collation, Static Port for Named Instance...
            #>
            Script AddCM12Admin # Original from http://asaconsultant.blogspot.no/2014/05/configmgr-scripting-with-powershell.html, had to change a few things around variables
                {
                    Getscript = {
                        Write-verbose "In Getscript AddCMAdmin" 
                        $CMModulePath = "$(Join-Path $($USING:Node.InstallPath) AdminConsole\bin\ConfigurationManager.psd1)"
                        $cert = Get-AuthenticodeSignature -FilePath "$CM12ModulePath" -ErrorAction SilentlyContinue
                        $store = new-object System.Security.Cryptography.X509Certificates.X509Store("TrustedPublisher","LocalMachine")
                        $store.Open("MaxAllowed")
                        $return = ""
                        $return = $store.Certificates | where {$_.thumbprint -eq $cert.SignerCertificate.Thumbprint}
                        $store.Close()
                        @{Result=$return.ToString()}
                        }
                    TestScript = {
                            Write-verbose "In TestScript AddCMAdmin"
                            $CMModulePath = "$(Join-Path $($USING:Node.InstallPath) AdminConsole\bin\ConfigurationManager.psd1)"
                            $cert = Get-AuthenticodeSignature -FilePath "$CMModulePath" -ErrorAction SilentlyContinue
                            $store = new-object System.Security.Cryptography.X509Certificates.X509Store("TrustedPublisher","LocalMachine")
                            $store.Open("MaxAllowed")
                            $return = $null
                            $return = $store.Certificates | where {$_.thumbprint -eq $cert.SignerCertificate.Thumbprint}
                            $store.Close()
                            if($return)
                            {
                                write-verbose "Return TRUE"
                                $true
                            }
                            else
                            {
                                write-verbose "Return FALSE"
                                $false
                            }
                        }
                    SetScript = {
                            Write-verbose "In SetScript AddCMAdmin"
                            $CMModulePath = "$(Join-Path $($USING:Node.InstallPath) AdminConsole\bin\ConfigurationManager.psd1)"
                            $cert = Get-AuthenticodeSignature -FilePath "$CM12ModulePath" -ErrorAction SilentlyContinue
                            $store = new-object System.Security.Cryptography.X509Certificates.X509Store("TrustedPublisher","LocalMachine")
                            $store.Open("MaxAllowed")
                            Write-Verbose "Adding cert to store"
                            $store.Add($cert.SignerCertificate)
                            $store.Close()
                            Import-Module $CMModulePath
                            new-psdrive -Name "$($USING:Node.CMSiteCode)" -PSProvider "AdminUI.PS.Provider\CMSite" -Root "$($USING:Node.NodeName)"
                            Set-Location "$($USING:Node.CMSiteCode):\"
                            New-CMAdministrativeUser -RoleName 'Full Administrator' -SecurityScopeName All -Name "$($USING:Node.CMAdmin)"
                        }            
                }
        }
}

CM -ConfigurationData $ConfigData -OutputPath C:\temp\CM

#Start-DscConfiguration -Wait -ComputerName DSCTestServer.do.local -Path \\dc01\sources\Tools\scripts\Powershell_DSC\CM -Verbose
