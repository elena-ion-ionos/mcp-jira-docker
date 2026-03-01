Check the TLS certificate for the endpoint `$ARGUMENTS`.

## Step 1: Resolve the endpoint

**If `$ARGUMENTS` matches the pattern `[s3] cloudian [on] <environment>`** (e.g., `cloudian staging`, `s3 cloudian on prod`, `cloudian on dev`):
- Extract the environment name (the last word, e.g., `staging`, `prod`, `dev`, `dev-cris`, `iaas`)
- Read the values file: `/workspace/platform-s3-deployment/environments/<environment>/s3-mgmt/values.yaml`
- Extract the value at `s3.credentials.cloudian.url` (e.g., `https://s3-admin.profit-bricks.me:19443`)
- Strip the `https://` prefix to get `host:port` format (e.g., `s3-admin.profit-bricks.me:19443`)
- Use this as the `ENDPOINT` for the checks below
- Tell the user which endpoint was resolved from which environment

**Otherwise**, use `$ARGUMENTS` directly as the `ENDPOINT`.

## Step 2: Check certificate dates

Run this command:
```
openssl s_client -connect ENDPOINT </dev/null 2>/dev/null | openssl x509 -noout -dates
```

Compare `notAfter` against today's date. A certificate is expired if `notAfter` is **before or equal to** today's date — even if it expired only yesterday. Do not say it is valid unless `notAfter` is strictly in the future.

## Step 3: Report result

If the certificate **is expired**:
- Report it as expired
- Show the `notAfter` date
- Tell the user the cert has not been renewed yet and they need to contact the team managing the endpoint

If the certificate **is valid**:
- Report it as valid with the expiry date
- Run this command to get the SHA-256 fingerprint:
  ```
  openssl s_client -connect ENDPOINT </dev/null 2>/dev/null | openssl x509 -noout -fingerprint -sha256
  ```
- Show the fingerprint clearly so the user can copy it and update it in Vault under key `CLOUDIAN_CERT_FINGERPRINT`
