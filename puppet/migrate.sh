#!/bin/bash
# 
# This script was written to facilitate migration of puppet
# agents from the 3.8 enviornment to the new Puppet 5 environment.
#
# 2017-04-16 bill.wilcox@puppet.com - Initial script
# 2017-04-23 bill.wilcox@puppet.com - Added check to ensure the facts json exists.
# 2018-07-10 bill.wilcox@puppet.com - Anonymized the script for an example.
#
#set -x

ENVIRONMENT=$1
ROLE=$2
CSR_FILE="/etc/puppetlabs/puppet/csr_attributes.yaml"
PUPPET_CODE_ENV="<git_branch>"
PUPPET_NODE_CERTNAME=`/bin/hostname -f`
PUPPET_AUTOSIGN_SECRET="<autosign_secret>"

# Determine which puppet master to use
case $ENVIRONMENT in
  'production')
    MASTER="<master_fqdn>"
    ;;
  *)
    echo "ERROR:  You must specify a valid environment"
    exit 1
    ;;
esac

# Validate the role
if [[ -z $ROLE ]]; then
  echo "ERROR:  You must specify the role"
  exit 1
fi

# Move old configuration file
if [ ! -f /etc/puppetlabs/puppet/old_puppet.conf ]; then
  echo "Preserving old configuration"
  sudo mv /etc/puppetlabs/puppet/puppet.conf /etc/puppetlabs/puppet/old_puppet.conf
fi
echo "Removing old configuration"
sudo rm /etc/puppetlabs/puppet/puppet.conf

# Move old SSL directory
if [ ! -d /etc/puppetlabs/puppet/old_ssl ]; then
  echo "Preserving old SSL directory"
  sudo mv /etc/puppetlabs/puppet/ssl /etc/puppetlabs/puppet/old_ssl
fi
echo "Removing old SSL directory"
sudo rm -rf /etc/puppetlabs/puppet/ssl

# Move old cache directory
if [ ! -d /var/opt/lib/pe-puppet ]; then
  echo "Removing old cache directory"
  sudo rm -rf /var/opt/lib/pe-puppet
fi

# Initiate installation from new puppet master.
echo "Installing new puppet agent."

#  The following commented code is an example of setting up a CSR file for 
#  custom, trusted facts.
#INSTALL_ARGS="extension_requests:pp_environment=${PUPPET_CODE_ENV} agent:certname=${PUPPET_NODE_CERTNAME} custom_attributes:challengePassword=${PUPPET_AUTOSIGN_SECRET} extension_requests:pp_role=${ROLE}"
#
#echo "Install Args:  ${INSTALL_ARGS}"
#
#echo '---' > $CSR_FILE
#echo 'custom_attributes:' >> $CSR_FILE
#echo "  1.2.840.113549.1.9.7: ${PUPPET_AUTOSIGN_SECRET}" >> $CSR_FILE
#echo 'extension_requests:' >> $CSR_FILE
#echo "  pp_environment: ${PUPPET_CODE_ENV}" >> $CSR_FILE
#echo "  pp_role: ${ROLE}" >> $CSR_FILE

curl -k https://${MASTER}:8140/packages/current/install.bash | bash

echo 'Configuring new puppet'
sudo /opt/puppetlabs/puppet/bin/puppet config set server $MASTER --section main
sudo /opt/puppetlabs/puppet/bin/puppet config set noop true --section agent
echo 'Running puppet for the first time'
sudo /opt/puppetlabs/puppet/bin/puppet agent -t


# Remove the CSR attributes files
if [ -f $CSR_FILE ]; then
  echo "Removing local CSR file."
  #rm -rf $CSR_FILE
fi
