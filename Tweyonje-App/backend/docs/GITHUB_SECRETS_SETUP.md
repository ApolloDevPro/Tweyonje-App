# GitHub Secrets Configuration Guide

This guide explains how to configure GitHub Secrets for the Tweyonje CI/CD pipelines.

## Required Secrets

### Docker Registry Secrets

These secrets are required for building and pushing Docker images.

#### DOCKER_USERNAME
- **Description**: Docker Hub username
- **How to get**: Sign up at https://hub.docker.com/ and use your username
- **Example**: `your-docker-username`

#### DOCKER_PASSWORD
- **Description**: Docker Hub password or access token
- **How to get**: 
  1. Go to Docker Hub Account Settings
  2. Navigate to Security → Access Tokens
  3. Create new access token with Read, Write, Delete permissions
  4. Copy the token (you won't see it again)
- **Example**: `dckr_pat_xxxxxxxxxxxx`

### Staging Environment Secrets

These secrets are required for deploying to the staging environment.

#### STAGING_HOST
- **Description**: Staging server hostname or IP address
- **How to get**: Your staging server's public IP or domain
- **Example**: `staging.tweyonje.ug` or `192.168.1.100`

#### STAGING_USER
- **Description**: SSH username for staging server
- **How to get**: The username you use to SSH into the staging server
- **Example**: `ubuntu` or `deploy`

#### STAGING_SSH_KEY
- **Description**: Private SSH key for staging server authentication
- **How to get**: 
  1. Generate SSH key pair: `ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions`
  2. Add public key to server: `ssh-copy-id -i ~/.ssh/github_actions.pub user@server`
  3. Copy private key contents: `cat ~/.ssh/github_actions`
  4. Paste the entire contents (including BEGIN/END markers) into GitHub Secret
- **Example**: 
  ```
  -----BEGIN OPENSSH PRIVATE KEY-----
  b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
  ...
  -----END OPENSSH PRIVATE KEY-----
  ```

### Production Environment Secrets

These secrets are required for deploying to the production environment.

#### PRODUCTION_HOST
- **Description**: Production server hostname or IP address
- **How to get**: Your production server's public IP or domain
- **Example**: `tweyonje.ug` or `192.168.1.200`

#### PRODUCTION_USER
- **Description**: SSH username for production server
- **How to get**: The username you use to SSH into the production server
- **Example**: `ubuntu` or `deploy`

#### PRODUCTION_SSH_KEY
- **Description**: Private SSH key for production server authentication
- **How to get**: Same process as STAGING_SSH_KEY, but for production server
- **Example**: (Same format as STAGING_SSH_KEY)

### Expo Secrets

These secrets are required for building mobile apps with Expo EAS Build.

#### EXPO_TOKEN
- **Description**: Expo account authentication token
- **How to get**:
  1. Install Expo CLI: `npm install -g expo-cli`
  2. Login to Expo: `expo login`
  3. Get token: `expo whoami` (or check `~/.expo-state.json`)
  4. Or generate token at https://expo.dev/accounts/[username]/tokens
- **Example**: `ExpoToken_xxxxxxxxxxxx`

## Adding Secrets to GitHub

### Step-by-Step Instructions

1. **Navigate to Repository Settings**
   - Go to your GitHub repository
   - Click on "Settings" tab
   - Click on "Secrets and variables" → "Actions"

2. **Add New Repository Secret**
   - Click "New repository secret"
   - Enter the secret name (e.g., `DOCKER_USERNAME`)
   - Enter the secret value
   - Click "Add secret"

3. **Repeat for All Secrets**
   - Add all required secrets one by one
   - Ensure names match exactly (case-sensitive)

## Environment-Specific Secrets

### Staging Environment
- Configure secrets for staging environment:
  - Go to Settings → Environments → Staging
  - Add environment-specific secrets if needed

### Production Environment
- Configure secrets for production environment:
  - Go to Settings → Environments → Production
  - Add environment-specific secrets if needed
  - Enable required reviewers for production deployments

## Security Best Practices

### SSH Key Management
- Use separate SSH keys for staging and production
- Never commit private keys to the repository
- Rotate SSH keys regularly
- Use key-based authentication instead of passwords
- Restrict SSH key access to specific IPs if possible

### Docker Registry
- Use access tokens instead of passwords
- Rotate tokens regularly
- Use separate Docker Hub accounts for staging/production if needed
- Enable two-factor authentication on Docker Hub

### Expo Tokens
- Use scoped tokens with minimal permissions
- Rotate tokens regularly
- Revoke unused tokens
- Don't share tokens across projects

### General Security
- Never log or print secrets in CI/CD logs
- Use GitHub's secret scanning to detect leaked secrets
- Review access to repository secrets regularly
- Use environment-specific secrets when possible

## Testing Secrets

### Test SSH Connection
```powershell
ssh -i ~/.ssh/github_actions user@server
```

### Test Docker Login
```powershell
docker login -u DOCKER_USERNAME -p DOCKER_PASSWORD
```

### Test Expo Token
```powershell
expo whoami
```

## Troubleshooting

### SSH Authentication Failed
**Problem**: `Permission denied (publickey)`

**Solutions**:
- Verify SSH key is correctly formatted in GitHub Secret
- Ensure public key is added to server's `~/.ssh/authorized_keys`
- Check SSH key permissions: `chmod 600 ~/.ssh/github_actions`
- Verify server allows key-based authentication

### Docker Push Failed
**Problem**: `unauthorized: authentication required`

**Solutions**:
- Verify Docker Hub credentials are correct
- Check if access token has write permissions
- Ensure Docker Hub username is correct
- Try logging in manually to verify credentials

### Expo Build Failed
**Problem**: `EXPO_TOKEN is invalid`

**Solutions**:
- Verify Expo token is valid and not expired
- Regenerate token if needed
- Ensure Expo account is active
- Check token permissions

### Secret Not Found
**Problem**: `Error: Input required and not supplied: SECRET_NAME`

**Solutions**:
- Verify secret name matches exactly (case-sensitive)
- Ensure secret is added to correct repository
- Check if secret is environment-specific
- Verify workflow file references correct secret name

## Updating Secrets

### When to Update
- SSH key compromised or expired
- Docker Hub password changed
- Expo token expired
- Server credentials changed
- Security audit recommends rotation

### How to Update
1. Generate new secret value
2. Update server/service with new value
3. Update GitHub Secret
4. Test with new secret
5. Remove old secret/value

## Monitoring

### Check Secret Usage
- GitHub Actions logs show which secrets are used
- Monitor for unauthorized access attempts
- Review secret access logs in GitHub

### Audit Trail
- GitHub provides audit logs for secret access
- Regularly review who has access to secrets
- Monitor for suspicious activity

## Additional Resources

- [GitHub Actions Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Docker Hub Access Tokens](https://docs.docker.com/security/for-developers/access-tokens/)
- [Expo Authentication](https://docs.expo.dev/build-reference/using-secrets/)
- [SSH Key Management](https://www.ssh.com/academy/ssh/key)

## Checklist

Before enabling CI/CD:

- [ ] Docker Hub account created
- [ ] Docker access token generated
- [ ] SSH key pairs generated for staging and production
- [ ] Public keys added to servers
- [ ] Expo account created (if building mobile apps)
- [ ] Expo token generated
- [ ] All secrets added to GitHub
- [ ] SSH connections tested
- [ ] Docker login tested
- [ ] Expo token tested
- [ ] Environment protection rules configured
- [ ] Required reviewers set for production
