# RDN Framework Authentication Setup

## Overview
The RDN Framework has been configured with proper authentication to prevent unauthorized access to the dashboard.

## Authentication Flow
1. **Entry Point**: When accessing `/server/`, users are redirected to authentication check
2. **Session Validation**: The system checks for valid session cookies
3. **Login Required**: Users without valid sessions are redirected to the login page
4. **Dashboard Access**: Authenticated users can access the main dashboard

## Default Credentials
- **Username**: `admin`
- **Password**: `admin123`

⚠️ **IMPORTANT**: Change the default password in production!

## Files Modified/Created

### New Authentication Files:
- `rdn_server/cgi-bin/rdn_server/rdn_auth_check` - Main authentication check script
- `rdn_server/cgi-bin/rdn_server/rdn_logout` - Logout handler
- `rdn_server/html/index.html` - Redirect page to authentication

### Modified Files:
- `rdn_server/cgi-bin/rdn_server/rdn_login` - Enhanced login script with proper session handling
- `rdn_server/html/js/rdn_enhanced.js` - Updated logout endpoint
- `rdn_server/html/index.html` → `rdn_server/html/dashboard.html` - Renamed to prevent direct access

## How It Works

1. **Initial Access**: `/server/` → `index.html` → redirects to `rdn_auth_check`
2. **Authentication Check**: `rdn_auth_check` validates session cookies
3. **No Session**: Redirects to `login.html`
4. **Valid Session**: Serves the main dashboard (`dashboard.html`)
5. **Login Process**: `rdn_login` validates credentials and sets session cookies
6. **Logout Process**: `rdn_logout` expires session cookies and redirects to login

## Security Features

- Session-based authentication using secure cookies
- Automatic redirect for unauthenticated users
- Proper session expiration (5 minutes by default)
- Protection against direct access to dashboard files

## Customization

To change the default credentials, edit the `rdn_login` script:
```perl
my $valid_username = "admin";
my $valid_password = "your_new_password";
```

For production use, consider implementing database-based authentication by modifying the authentication logic in `rdn_login`.

## Testing

1. Access the RDN Framework URL
2. You should be redirected to the login page
3. Enter credentials: `admin` / `admin123`
4. You should be redirected to the main dashboard
5. Click logout to test session termination
