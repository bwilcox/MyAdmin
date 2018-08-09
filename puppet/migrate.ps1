#
# This script was written to facilitate migration of puppet
# agents from the 3.8 enviornment to the new Puppet 5 environment.
#
# 2017-04-23 bill.wilcox@puppet.com - Initial script
#


param (
  [Parameter(Mandatory=$true)][string]$environment,
  [Parameter(Mandatory=$true)][string]$role,
  [string]$csr_file='/etc/puppetlabs/puppet/csr_attributes.yaml',
  [string]$puppet_code_env='new_production',
  [string]$puppet_node_certname = (cmd /c puppet config print certname),
  [string]$puppet_autosign_secret='KaiserPuppet123',
  [string]$puppet_conf_dir='C:\ProgramData\PuppetLabs\puppet\etc',
  [string]$puppet_facts_dir='C:\ProgramData\PuppetLabs\facter\facts.d'
)

# Determine which puppet master to use

$master = switch -Regex( $environment )
{
  '^[Ii][Nn][Tt]2' { 'zqkpcloudxm9000.cloud-lab.kp.org' }
  '^[Qq][Aa]2' { 'pecompile-qa2.cloud-lab.kp.org' }
  '^[Pp][Rr][Oo][Dd]2' { 'pecompile.cloud.kp.org' }
  default {
    write-output 'ERROR:  You must specify a valid environment'
    exit 1
  }
}

# Validate that the required json fact file is there
$fact_path = $puppet_facts_dir + '\puppet_vra_facts.json'
if (! (Test-Path $fact_path)) {
  write-output 'ERROR puppet_vra_facts.json does not exist.  Assign the puppet_migration class and run puppet to create the fact json before migrating.'
  exit 2
}

# Move old configuration file
$conf_path = $puppet_conf_dir + "\puppet.conf"
$conf_path_new = $puppet_conf_dir + '\3.8_puppet.conf'
if (! (Test-Path $conf_path_new)) {
  write-output 'Preserving 3.8 configuration'
  Copy-Item $conf_path $conf_path_new
  write-output 'Removing puppet.conf'
  remove-item $conf_path
}

# Move old SSL directory
$ssl_path = $puppet_conf_dir + '\ssl'
$ssl_path_new = $puppet_conf_dir + '\3.8_ssl'
if (! (Test-Path $ssl_path_new)) {
  write-output 'Preserving 3.8 SSL directory'
  Copy-Item $ssl_path $ssl_path_new -Recurse
  write-output 'Removing ssl dir'
  remove-item $ssl_path -Recurse
}

# Initiate installation from new puppet master.
$install_args = 'extension_requests:pp_environment=' + $puppet_code_env + ' agent:certname=' + $puppet_node_certname + ' custom_attributes:challengePassword=' + $puppet_autosign_secret + ' extension_requests:pp_role=' + $role

write-output 'Install args:' + $install_args

[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile('https://' + $master + ':8140/packages/current/install.ps1', 'c:\install.ps1')
invoke-expression "c:\install.ps1 $install_args"
write-output 'Running Puppet for the first time.'
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet" config set server $master --section main
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet" config set noop true --section agent
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet" agent -t

# Remote the CSR attributes files
$csr_path = $puppet_conf_dir + '\csr_attributes.yaml'
if (Test-Path $csr_path) {
  write-output 'Removing local CSR file.'
  remove-item $csr_path
}

