The PDK is required on the build machine.
I had to use Ruby 2.7 to get this to work.

https://github.com/puppetlabs/Puppet.Dsc#building-the-module

Install-Module -Name Puppet.Dsc

You should end up with PowerShellGet 2.2.5+ and PackageManagement 1.4.4+

list versions:  get-module -all
update: update-module -name powershellget -requiredversion 2.2.5
update: update-module -name packagemanagement -requiredversion 1.4.4

Open a new powershell window after updating the required modules.

New-PuppetDscModule -PowerShellModuleName 'securitypolicydsc' -PowerShellModuleVersion '3.0.0-preview0003' -AllowPrerelease


# How to make a local PS Repo to build a module 
`register-psrepository -name LocalPSRepo -SourceLocation '\\localhost\Users\Administrator\test\psrepo\' -scriptsourcelocation '\\localhost\Users\Administrator\test\psrepo\' -installationpolicy trusted`

The source location must be a file share.

Downlod the Git repo with the module code you want.
In the module run the build script. 'build.ps1'

Load the module to the local repo:
` publish-module -path 'C:\users\administrator\test\SecurityPolicyDsc\output\SecurityPolicyDSC' -repository LocalPSRepo -nugetapikey 'mykey'`

Build the module:
`New-PuppetDscModule -PowerShellModuleName 'securitypolicydsc' -Repository LocalPSRepo`