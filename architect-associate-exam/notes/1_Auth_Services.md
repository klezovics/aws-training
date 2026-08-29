# Auth service overview

- IAM = supreme king of AN/AZ
- STS = just issues short lived tokens
- IAM Identity Center -> SSO accross accounts (nice login panel)

# Org related stuff
- Organisation -> Orgs and SCPs provide orgs wide permission ceilings
- Control Tower -> Orgs on steroids

# Other
- Cognito -> my app end users -> like Keycloak Cognito user pool = KC realm.
- Directory Service -> managed Active Directory -> for corp/Windows workloads

# Marginal
- Verified Permissions-> fine grained app auth
- Verified Access -> zero trust thingy


# Auth service details

# IAM
- IAM = AN + AZ
- IAM = Who can do what ?
- IAM = identities (user/group/role) + policies (permission/limit/trust)
- IAM = within account + cross account

- User/Group/Role -> slim objects
- The heavy stuff are all the permissions objects. But they are just lists of statements

Policy types:
- Permission policy -> give permissions -> identity/resource policies
- Limit policies -> limit which permissions can be given
- Trust policies -> determine who can assume role