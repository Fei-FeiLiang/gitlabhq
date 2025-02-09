---
type: reference
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# OpenID Connect OmniAuth provider **(FREE SELF)**

GitLab can use [OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html)
as an OmniAuth provider.

To enable the OpenID Connect OmniAuth provider, you must register your application
with an OpenID Connect provider.
The OpenID Connect provides you with a client's details and secret for you to use.

1. On your GitLab server, open the configuration file.

   For Omnibus GitLab:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For installations from source:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. [Configure initial settings](../../integration/omniauth.md#configure-initial-settings).

1. Add the provider configuration.

   For Omnibus GitLab:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Provider name", # optional label for login button, defaults to "Openid Connect"
       icon: "<custom_provider_icon>",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         send_scope_to_token_endpoint: "false",
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback"
         }
       }
     }
   ]
   ```

   For installation from source:

   ```yaml
     - { name: 'openid_connect',
         label: 'Provider name', # optional label for login button, defaults to "Openid Connect"
         icon: '<custom_provider_icon>',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           send_scope_to_token_endpoint: false,
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback'
           }
         }
       }
   ```

   NOTE:
   For more information on each configuration option, refer to the:

   - [OmniAuth OpenID Connect usage documentation](https://github.com/m0n9oose/omniauth_openid_connect#usage).
   - [OpenID Connect Core 1.0 specification](https://openid.net/specs/openid-connect-core-1_0.html).

1. For the provider configuration, change the values for the provider to match your
   OpenID Connect client setup. Use the following as a guide:

   - `<your_oidc_label>` is the label that appears on the login page.
   - `<custom_provider_icon>` (optional) is the icon that appears on the login page.
     Icons for the major social login platforms are built into GitLab,
     but you can override these icons by specifying this parameter. GitLab accepts both
     local paths and absolute URLs.
   - `<your_oidc_url>` (optional) is the URL that points to the OpenID Connect
     provider (for example, `https://example.com/auth/realms/your-realm`).
     If this value is not provided, the URL is constructed from `client_options`
     in the following format: `<client_options.scheme>://<client_options.host>:<client_options.port>`.
   - If `discovery` is set to `true`, the OpenID Connect provider attempts to automatically
     discover the client options using `<your_oidc_url>/.well-known/openid-configuration`.
     Defaults to `false`.
   - `client_auth_method` (optional) specifies the method used for authenticating
     the client with the OpenID Connect provider.
     - Supported values are:
       - `basic` - HTTP Basic Authentication.
       - `jwt_bearer` - JWT-based authentication (private key and client secret signing).
       - `mtls` - Mutual TLS or X.509 certificate validation.
       - Any other value posts the client ID and secret in the request body.
     - If not specified, this value defaults to `basic`.
   - `<uid_field>` (optional) is the field name from `user_info.raw_attributes`
     that defines the value for `uid` (for example, `preferred_username`).
     If you do not provide this value, or the field with the configured value is missing
     from the `user_info.raw_attributes` details, `uid` uses the `sub` field.
   - `send_scope_to_token_endpoint` is `true` by default, so the `scope` parameter
     is normally included in requests to the token endpoint.
     However, if your OpenID Connect provider does not accept the `scope` parameter
     in such requests, set this to `false`.
   - `client_options` are the OpenID Connect client-specific options. Specifically:
     - `identifier` is the client identifier as configured in the OpenID Connect service provider.
     - `secret` is the client secret as configured in the OpenID Connect service provider.
     - `redirect_uri` is the GitLab URL to redirect the user to after successful login
       (for example, `http://example.com/users/auth/openid_connect/callback`).
     - `end_session_endpoint` (optional) is the URL to the endpoint that ends the
       session. You can provide this URL if auto-discovery is disabled or unsuccessful.
     - The following `client_options` are optional unless auto-discovery is disabled or unsuccessful:
       - `authorization_endpoint` is the URL to the endpoint that authorizes the end user.
       - `token_endpoint` is the URL to the endpoint that provides Access Token.
       - `userinfo_endpoint` is the URL to the endpoint that provides the user information.
       - `jwks_uri` is the URL to the endpoint where the Token signer publishes its keys.

1. Save the configuration file.
1. For changes to take effect, if you installed GitLab:

   - With Omnibus, [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
   - From source, [restart GitLab](../restart_gitlab.md#installations-from-source).

On the sign in page, you have an OpenID Connect option below the regular sign in form.
Select this option to begin the authentication process. The OpenID Connect provider
asks you to sign in and authorize the GitLab application if confirmation is required
by the client. You are redirected to GitLab and signed in.

## Example configurations

The following configurations illustrate how to set up OpenID with
different providers with Omnibus GitLab.

### Configure Google

See the [Google documentation](https://developers.google.com/identity/protocols/oauth2/openid-connect)
for more details:

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect",
    label: "Google OpenID", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer: "https://accounts.google.com",
      client_auth_method: "query",
      discovery: true,
      uid_field: "preferred_username",
      client_options: {
        identifier: "<YOUR PROJECT CLIENT ID>",
        secret: "<YOUR PROJECT CLIENT SECRET>",
        redirect_uri: "https://example.com/users/auth/openid_connect/callback",
       }
     }
  }
]
```

### Configure Microsoft Azure

The OpenID Connect (OIDC) protocol for Microsoft Azure uses the [Microsoft identity platform (v2) endpoints](https://learn.microsoft.com/en-us/azure/active-directory/azuread-dev/azure-ad-endpoint-comparison).
To get started, sign in to the [Azure Portal](https://portal.azure.com). For your app,
you need the following information:

- A tenant ID. You may already have one. For more information, see the
  [Microsoft Azure Tenant](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-create-new-tenant) documentation.
- A client ID and a client secret. Follow the instructions in the
  [Microsoft Quickstart Register an Application](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app) documentation
  to obtain the tenant ID, client ID, and client secret for your app.

Example Omnibus configuration block:

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect",
    label: "Azure OIDC", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
      client_auth_method: "query",
      discovery: true,
      uid_field: "preferred_username",
      client_options: {
        identifier: "<YOUR APP CLIENT ID>",
        secret: "<YOUR APP CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
      }
    }
  }
]
```

Microsoft has documented how its platform works with [the OIDC protocol](https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-protocols-oidc).

### Configure Microsoft Azure Active Directory B2C

GitLab requires special
configuration to work with [Azure Active Directory B2C](https://learn.microsoft.com/en-us/azure/active-directory-b2c/overview). To get started, sign in to the [Azure Portal](https://portal.azure.com).
For your app, you need the following information from Azure:

- A tenant ID. You may already have one. For more information, review the
  [Microsoft Azure Tenant](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-create-new-tenant) documentation.
- A client ID and a client secret. Follow the instructions in the
  [Microsoft tutorial](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-register-applications?tabs=app-reg-ga) documentation to obtain the
  client ID and client secret for your app.
- The user flow or policy name. Follow the instructions in the [Microsoft tutorial](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-user-flow).

Configure the app:

1. Set the app `Redirect URI`. For example, If your GitLab domain is `gitlab.example.com`,
   set the app `Redirect URI` to `https://gitlab.example.com/users/auth/openid_connect/callback`.

1. [Enable the ID tokens](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-register-applications?tabs=app-reg-ga#enable-id-token-implicit-grant).

1. Add the following API permissions to the app:

   - `openid`
   - `offline_access`

#### Configure custom policies

Azure B2C [offers two ways of defining the business logic for logging in a user](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview):

- [User flows](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview#user-flows)
- [Custom policies](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview#custom-policies)

Custom policies are required because standard Azure B2C user flows
[do not send the OpenID `email` claim](https://github.com/MicrosoftDocs/azure-docs/issues/16566).
Therefore, the standard user flows do not work with the
[`allow_single_sign_on` or `auto_link_user` parameters](../../integration/omniauth.md#configure-initial-settings).
With a standard Azure B2C policy, GitLab cannot create a new account or
link to an existing account with an email address.

First, [create a custom policy](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy).

The Microsoft instructions use `SocialAndLocalAccounts` in the [custom policy starter pack](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#custom-policy-starter-pack),
but `LocalAccounts` authenticates against local Active Directory accounts. Before you [upload the polices](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#upload-the-policies), do the following:

1. To export the `email` claim, modify the `SignUpOrSignin.xml`. Replace the following line:

   ```xml
   <OutputClaim ClaimTypeReferenceId="email" />
   ```

   with:

   ```xml
   <OutputClaim ClaimTypeReferenceId="signInNames.emailAddress" PartnerClaimType="email" />
   ```

1. For OIDC discovery to work with B2C, configure the policy with an issuer compatible with the
  [OIDC specification](https://openid.net/specs/openid-connect-discovery-1_0.html#rfc.section.4.3).
   See the [token compatibility settings](https://learn.microsoft.com/en-us/azure/active-directory-b2c/configure-tokens?pivots=b2c-custom-policy#token-compatibility-settings).
   In `TrustFrameworkBase.xml` under `JwtIssuer`, set `IssuanceClaimPattern` to `AuthorityWithTfp`:

   ```xml
   <ClaimsProvider>
     <DisplayName>Token Issuer</DisplayName>
     <TechnicalProfiles>
       <TechnicalProfile Id="JwtIssuer">
         <DisplayName>JWT Issuer</DisplayName>
         <Protocol Name="None" />
         <OutputTokenFormat>JWT</OutputTokenFormat>
         <Metadata>
           <Item Key="IssuanceClaimPattern">AuthorityWithTfp</Item>
           ...
   ```

1. [Upload the policy](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#upload-the-policies). Overwrite
   the existing files if you are updating an existing policy.

1. To determine the issuer URL, use the sign-in policy. The issuer URL is in the form:

   ```markdown
   https://<YOUR-DOMAIN>/tfp/<YOUR-TENANT-ID>/<YOUR-SIGN-IN-POLICY-NAME>/v2.0/
   ```

   The policy name is lowercase in the URL. For example, `B2C_1A_signup_signin`
   policy appears as `b2c_1a_signup_sigin`.

   Ensure you include the trailing forward slash.

1. Verify the operation of the OIDC discovery URL and issuer URL and append
   `.well-known/openid-configuration` to the issuer URL:

   ```markdown
   https://<YOUR-DOMAIN>/tfp/<YOUR-TENANT-ID>/<YOUR-SIGN-IN-POLICY-NAME>/v2.0/.well-known/openid-configuration
   ```

   For example, if `domain` is `example.b2clogin.com` and tenant ID is
   `fc40c736-476c-4da1-b489-ee48cee84386`, you can use `curl` and `jq` to extract the issuer:

   ```shell
   $ curl --silent "https://example.b2clogin.com/tfp/fc40c736-476c-4da1-b489-ee48cee84386/b2c_1a_signup_signin/v2.0/.well-known/openid-configuration" | jq .issuer
   "https://example.b2clogin.com/tfp/fc40c736-476c-4da1-b489-ee48cee84386/b2c_1a_signup_signin/v2.0/"
   ```

1. Configure the issuer URL with the custom policy used for `signup_signin`. For example, this is
   the Omnibus configuration with a custom policy for `b2c_1a_signup_signin`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
   {
     name: "openid_connect",
     label: "Azure B2C OIDC", # optional label for login button, defaults to "Openid Connect"
     args: {
       name: "openid_connect",
       scope: ["openid"],
       response_mode: "query",
       response_type: "id_token",
       issuer:  "https://<YOUR-DOMAIN>/tfp/<YOUR-TENANT-ID>/b2c_1a_signup_signin/v2.0/",
       client_auth_method: "query",
       discovery: true,
       send_scope_to_token_endpoint: true,
       client_options: {
         identifier: "<YOUR APP CLIENT ID>",
         secret: "<YOUR APP CLIENT SECRET>",
         redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
       }
     }
   }]
   ```

#### Troubleshooting Azure B2C

- Ensure all occurrences of `yourtenant.onmicrosoft.com`, `ProxyIdentityExperienceFrameworkAppId`, and `IdentityExperienceFrameworkAppId` match your B2C tenant hostname and
  the respective client IDs in the XML policy files.
- Add `https://jwt.ms` as a redirect URI to the app, and use the [custom policy tester](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#test-the-custom-policy).
  Ensure the payload includes `email` that matches the user's email access.
- After you enable the custom policy, users might see `Invalid username or password`
  after they try to sign in. This might be a configuration issue with the `IdentityExperienceFramework`
  app. See [this Microsoft comment](https://learn.microsoft.com/en-us/answers/questions/50355/unable-to-sign-on-using-custom-policy.html?childToView=122370#comment-122370) that suggests you check that the app manifest
  contains these settings:

  - `"accessTokenAcceptedVersion": null`
  - `"signInAudience": "AzureADMyOrg"`

This configuration corresponds with the `Supported account types` setting used when
creating the `IdentityExperienceFramework` app.

### Configure Keycloak

GitLab works with OpenID providers that use HTTPS. Although you can set up a
Keycloak server that uses HTTP, GitLab can only communicate with a Keycloak server
that uses HTTPS.

Configure Keycloak to use public key encryption algorithms (for example,
RSA256 or RSA512) instead of symmetric key encryption algorithms (for example,
HS256 or HS358) to sign tokens. Public key encryption algorithms are:

- Easier to configure.
- More secure because leaking the private key has severe security consequences.

1. Open the Keycloak administration console.
1. Select **Realm Settings > Tokens > Default Signature Algorithm**.
1. Configure the signature algorithm.

Example Omnibus configuration block:

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect",
    label: "Keycloak", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://keycloak.example.com/auth/realms/myrealm",
      client_auth_method: "query",
      discovery: true,
      uid_field: "preferred_username",
      client_options: {
        identifier: "<YOUR CLIENT ID>",
        secret: "<YOUR CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
      }
    }
  }
]
```

#### Configure Keycloak with a symmetric key algorithm

> Introduced in GitLab 14.2.

WARNING:
The following instructions are included for completeness, but only use symmetric key
encryption if absolutely necessary.

To use symmetric key encryption:

1. Extract the secret key from the Keycloak database. Keycloak does not expose this
   value in the web interface. The client secret seen in the web interface is the
   OAuth 2.0 client secret, which is different from the secret used to sign JSON Web Tokens.

   For example, if you use PostgreSQL as the backend database for Keycloak:

   - Sign into the database console.
   - Run the following SQL query to extract the key:

     ```sql
     $ psql -U keycloak
     psql (13.3 (Debian 13.3-1.pgdg100+1))
     Type "help" for help.

     keycloak=# SELECT c.name, value FROM component_config CC INNER JOIN component C ON(CC.component_id = C.id) WHERE C.realm_id = 'master' and provider_id = 'hmac-generated' AND CC.name = 'secret';
     -[ RECORD 1 ]---------------------------------------------------------------------------------
     name  | hmac-generated
     value | lo6cqjD6Ika8pk7qc3fpFx9ysrhf7E62-sqGc8drp3XW-wr93zru8PFsQokHZZuJJbaUXvmiOftCZM3C4KW3-g
     -[ RECORD 2 ]---------------------------------------------------------------------------------
     name  | fallback-HS384
     value | UfVqmIs--U61UYsRH-NYBH3_mlluLONpg_zN7CXEwkJcO9xdRNlzZfmfDLPtf2xSTMvqu08R2VhLr-8G-oZ47A
     ```

     In this example, there are two private keys: one for HS256 (`hmac-generated`)
     and another for HS384 (`fallback-HS384`). We use the first `value` to configure GitLab.

1. Convert `value` to standard base64. As discussed in the [**Invalid signature with HS256 token** post](https://keycloak.discourse.group/t/invalid-signature-with-hs256-token/3228/9),
   `value` is encoded in the [**Base 64 Encoding with URL and Filename Safe Alphabet** section](https://datatracker.ietf.org/doc/html/rfc4648#section-5) of RFC 4648.
   This must be converted to [standard base64 as defined in RFC 2045](https://datatracker.ietf.org/doc/html/rfc2045).
   The following Ruby script does this:

   ```ruby
   require 'base64'

   value = "lo6cqjD6Ika8pk7qc3fpFx9ysrhf7E62-sqGc8drp3XW-wr93zru8PFsQokHZZuJJbaUXvmiOftCZM3C4KW3-g"
   Base64.encode64(Base64.urlsafe_decode64(value))
   ```

   This results in the following value:

   ```markdown
   lo6cqjD6Ika8pk7qc3fpFx9ysrhf7E62+sqGc8drp3XW+wr93zru8PFsQokH\nZZuJJbaUXvmiOftCZM3C4KW3+g==\n
   ```

1. Specify this base64-encoded secret in `jwt_secret_base64`. For example:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Keycloak", # optional label for login button, defaults to "Openid Connect"
       args: {
         name: "openid_connect",
         scope: ["openid", "profile", "email"],
         response_type: "code",
         issuer:  "https://keycloak.example.com/auth/realms/myrealm",
         client_auth_method: "query",
         discovery: true,
         uid_field: "preferred_username",
         jwt_secret_base64: "<YOUR BASE64-ENCODED SECRET>",
         client_options: {
           identifier: "<YOUR CLIENT ID>",
           secret: "<YOUR CLIENT SECRET>",
           redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
         }
       }
     }
   ]
   ```

If you see a `JSON::JWS::VerificationFailed` error,
you have specified the wrong secret.

### Casdoor

GitLab works with OpenID providers that use HTTPS. Use HTTPS to connect to GitLab
through OpenID with Casdoor.

For your app, complete the following steps on Casdoor:

1. Get a client ID and a client secret.
1. Add your GitLab redirect URL. For example, if your GitLab domain is `gitlab.example.com`,
   ensure the Casdoor app has the following
   `Redirect URI`: `https://gitlab.example.com/users/auth/openid_connect/callback`.

See the [Casdoor documentation](https://casdoor.org/docs/integration/gitlab) for more details.

Example Omnibus GitLab configuration (file path: `/etc/gitlab/gitlab.rb`):

```ruby
gitlab_rails['omniauth_providers'] = [
    {
        name: "openid_connect",
        label: "Casdoor", # optional label for login button, defaults to "Openid Connect"
        args: {
            name: "openid_connect",
            scope: ["openid", "profile", "email"],
            response_type: "code",
            issuer:  "https://<CASDOOR_HOSTNAME>",
            client_auth_method: "query",
            discovery: true,
            uid_field: "sub",
            client_options: {
                identifier: "<YOUR CLIENT ID>",
                secret: "<YOUR CLIENT SECRET>",
                redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
            }
        }
    }
]
```

Example installations from source configuration (file path: `config/gitlab.yml`):

```yaml
  - { name: 'openid_connect',
      label: 'Casdoor', # optional label for login button, defaults to "Openid Connect"
      args: {
        name: 'openid_connect',
        scope: ['openid','profile','email'],
        response_type: 'code',
        issuer: 'https://<CASDOOR_HOSTNAME>',
        discovery: true,
        client_auth_method: 'query',
        uid_field: 'sub',
        client_options: {
          identifier: '<YOUR CLIENT ID>',
          secret: '<YOUR CLIENT SECRET>',
          redirect_uri: 'https://gitlab.example.com/users/auth/openid_connect/callback'
        }
      }
    }
```

## Troubleshooting

1. Ensure `discovery` is set to `true`. If you set it to `false`, you must
   specify all the URLs and keys required to make OpenID work.

1. Check your system clock to ensure the time is synchronized properly.

1. As mentioned in [the OmniAuth OpenID Connect documentation](https://github.com/m0n9oose/omniauth_openid_connect),
   make sure `issuer` corresponds to the base URL of the Discovery URL. For
   example, `https://accounts.google.com` is used for the URL
   `https://accounts.google.com/.well-known/openid-configuration`.

1. The OpenID Connect client uses HTTP Basic Authentication to send the
   OAuth 2.0 access token if `client_auth_method` is not defined or if set to `basic`.
   If you see 401 errors when retrieving the `userinfo` endpoint, check
   your OpenID web server configuration. For example, for
   [`oauth2-server-php`](https://github.com/bshaffer/oauth2-server-php), you may have to
   [add a configuration parameter to Apache](https://github.com/bshaffer/oauth2-server-php/issues/926#issuecomment-387502778).
