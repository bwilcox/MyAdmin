###
# These are commands to use with the rest client VSCode Extension
#
# Setup Environment Variables:
# 1. In VSCode use the menu: File -> Preferences -> Settings
# 2. Got to the Rest Client extension.
# 3. For environment variables, select 'edit in settings.json'.
# 4. Set the shared section to look like this:
#
#  "$shared": {
#      "puppet_login": "<YOUR_LOGIN>",
#      "puppet_password": "<YOUR_PASSWORD>",
#      "puppet_server": "puppet.server.net"
#  }

###
# Local variables
@puppet_server = ec2-18-188-69-156.us-east-2.compute.amazonaws.com
@puppet_login = admin
@puppet_password = puppetlabs

###
# @name GetToken
# Get an access token
POST https://{{puppet_server}}:4433/rbac-api/v1/auth/token
Content-Type: application/json

{
  "login": "{{puppet_login}}",
  "password": "{{puppet_password}}"
}

###
# Deploy an environment
POST https://{{puppet_server}}:8170/code-manager/v1/deploys
X-Authentication: {{GetToken.response.body.$.token}}
Content-Type: application/json

{
  "environments": [""],
  "wait": true
}

###
# Request classes update from the classifier
POST https://{{puppet_server}}:4433/classifier-api/v1/update-classes
X-Authentication: {{GetToken.response.body.$.token}}
Content-Type: application/json

{
  "environment": "",
}

###
# Get the ldap configuration
Get https://{{puppet_server}}:4433/rbac-api/v2/ds
X-Authentication: {{GetToken.response.body.$.token}}
Content-Type: application/json

###
# Set the ldap configuration
PUT https://{{puppet_server}}:4433/rbac-api/v1/ds
X-Authentication: {{GetToken.response.body.$.token}}
Content-Type: application/json

{
  "help_link": "https://help.example.com",
  "ssl": true,
  "group_name_attr": "name",
  "password": "skippy",
  "group_rdn": null,
  "connect_timeout": 15,
  "user_display_name_attr": "cn",
  "disable_ldap_matching_rule_in_chain": false,
  "ssl_hostname_validation": true,
  "hostname": "ldap.example.com",
  "base_dn": "dc=example,dc=com",
  "user_lookup_attr": "uid",
  "port": 636,
  "login": "cn=ldapuser,ou=service,ou=users,dc=example,dc=com",
  "group_lookup_attr": "cn",
  "group_member_attr": "uniqueMember",
  "ssl_wildcard_validation": false,
  "user_email_attr": "mail",
  "user_rdn": "ou=users",
  "group_object_class": "groupOfUniqueNames",
  "display_name": "Acme Corp Ldap server",
  "search_nested_groups": true,
  "start_tls": false
}