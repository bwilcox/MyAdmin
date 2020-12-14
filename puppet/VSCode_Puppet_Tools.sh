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
