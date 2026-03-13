export GENESYSCLOUD_OAUTHCLIENT_ID='your-oauth-client-id'
export GENESYSCLOUD_OAUTHCLIENT_SECRET='your-oauth-client-secret'
export GENESYSCLOUD_REGION='your-genesyscloud-region' # eg.us-east-1, eu-west-1, ap-southeast-2, etc.

# Provide your AWS Account in at least one of the following

# AWS Profile (should be configured in your ~/.aws/credentials file and login with aws sso login if using SSO)
export AWS_PROFILE='your-aws-profile'

# AWS Access Keys
# export AWS_ACCESS_KEY_ID='your_access_key_id'
# export AWS_SECRET_ACCESS_KEY='your_secret_access_key'
# export AWS_SESSION_TOKEN='your_session_token' (if using temporary credentials)

# The region where you want your AWS resources to be created
export AWS_REGION='your-aws-region' 
