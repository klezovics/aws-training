# Auth service overview

# Key facts
- You mostly attach policies to identities and configure account organisational tree
- Two identity types: user&role. Group is used to group users.
- Two credential types: API Keys & STS tokens
- Two auth paradigms: AWS endpoints is AIM, for a hosted app, it handles its own auth in an app specific way
- Each compute service has each own unique abstraction which binds a role to this specific workload type i.e `InstanceProfile`

- SCP (Service control policies for orgs)
- SCP = limit admin perms -> prevent disabling security stuff, run costly stuff, compliance (limit regions)

Resource policy main use cases:
- Anon and cross-account access
- Service principals. Allow certain services to do stuff on resource like AWS Lambda
- Same-account guardrails. Deny non-TLS, restrict to a VPC endpoint

# Service overview
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
- IAM = only two credential types: API keys + STS tokens. Both used to generate the signature

- User/Group/Role -> slim objects
- The heavy stuff are all the permissions objects. But they are just lists of statements

Policy types:
- Permission policy -> give permissions -> identity/resource policies
- Limit policies -> limit which permissions can be given
- Trust policies -> determine who can assume role
