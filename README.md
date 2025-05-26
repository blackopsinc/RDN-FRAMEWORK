# RDN Framework v7.0 - Enhanced Command & Control

## Overview

The RDN Framework is a powerful web-based command and control system for managing multiple hosts and executing remote commands. This enhanced version includes modern security features, improved UI, and comprehensive audit logging.

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Git

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd RDN-FRAMEWORK
```

2. Start the services:
```bash
docker-compose up -d
```

3. Wait for all services to be healthy:
```bash
docker-compose ps
```

### Access the Application

#### Local Development
- **Web Interface**: http://localhost:8080/server/
- **Health Check**: http://localhost:8080/server/health

#### GitHub Codespaces
- **Web Interface**: https://[codespace-name]-8080.app.github.dev/server/
- **Health Check**: https://[codespace-name]-8080.app.github.dev/server/health

## Login Instructions

### Default Credentials
- **Username**: `admin`
- **Password**: `admin123`

### First Login
1. Navigate to the web interface URL
2. You'll see the RDN Framework dashboard
3. If prompted for login, use the credentials above
4. **Important**: Change the default password immediately after first login

### Security Notes
- The default password should be changed in production
- Enable 2FA for enhanced security
- Review and update the allowed IP ranges in the configuration

## Features

### Dashboard
- Real-time system metrics
- Active host monitoring
- Command execution statistics
- Recent activity logs

### Host Management
- Add/remove hosts
- Support for multiple connection types (Web, SSH, RDP, API, Database)
- Health monitoring
- Grouping and tagging

### Web Console
- Interactive terminal interface
- Multi-host command execution
- Command history
- Real-time output

### Security Features
- Session management
- Audit logging
- IP-based access control
- Rate limiting
- Encrypted communications

## Configuration

### Database Configuration
The system uses MySQL for data storage:
- **Host**: rdn-data container (172.20.0.200)
- **Database**: rdn
- **User**: root
- **Password**: changeme (change in production)

### Redis Configuration
Redis is used for session management and caching:
- **Host**: rdn-redis container (172.20.0.150)
- **Port**: 6379

### Environment Variables
Key environment variables in `docker-compose.yml`:
- `RDN_ENV`: Set to "production" for production deployments
- `RDN_LOG_LEVEL`: Logging level (debug, info, warn, error)

## Host Management

### Adding Hosts

1. Navigate to the "Hosts" section
2. Click "Add Host"
3. Fill in the required information:
   - **Name**: Unique identifier for the host
   - **Type**: Connection type (web, ssh, rdp, api, database, custom)
   - **OS**: Operating system
   - **FQDN**: Fully qualified domain name
   - **Connection String**: How to connect to the host

### Host Types

#### Web Hosts
- For web-based command execution
- Connection string format: `http://hostname:port/path`

#### SSH Hosts
- For SSH-based connections
- Requires username/password or SSH keys
- Connection string format: `ssh://username@hostname:port`

#### API Hosts
- For REST API interactions
- Connection string format: `https://api.hostname.com/v1`

### Host Status
- **Active**: Host is responding and available
- **Inactive**: Host is not responding
- **Maintenance**: Host is in maintenance mode
- **Error**: Host has encountered an error

## API Documentation

### Console API
The console API allows remote command execution on managed hosts.

### Endpoints

#### Execute Command
```bash
GET /server/api/console/execute?host_id=<id>&command=<command>
POST /server/api/console/execute
Content-Type: application/json
{
  "host_id": "1",
  "command": "id"
}
```

#### List Hosts
```bash
GET /server/api/hosts
```

#### Health Check
```bash
GET /server/health
```
Returns system health status in JSON format.

### Authentication
Most API endpoints require authentication. Include session key in requests:
```bash
GET /server/api?key=<session_key>
```

### Host Management API
```bash
# List all hosts
GET /server/api/hosts

# Get specific host
GET /server/api/hosts/<host_id>

# Add new host
POST /server/api/hosts
Content-Type: application/json
{
  "name": "example-host",
  "type": "web",
  "os": "linux",
  "fqdn": "example.com",
  "connection_string": "http://example.com:8080"
}
```

## Validation Tests

### Verify Host Loading
The application has been validated to successfully load and manage hosts:

1. **Database Connection**: ✅ Verified working
2. **Host Retrieval**: ✅ Successfully loads 3 demo hosts
3. **Console API**: ✅ Command execution working
4. **Web Interface**: ✅ Main page loads correctly

### Test Commands
You can test the console functionality with these commands:
```bash
# Test basic command execution
curl "http://localhost:8080/server/api/console/execute?host_id=1&command=id"

# Test directory listing
curl "http://localhost:8080/server/api/console/execute?host_id=1&command=ls%20-la"

# Test current directory
curl "http://localhost:8080/server/api/console/execute?host_id=1&command=pwd"
```

## Troubleshooting

### Common Issues

#### "Forbidden" Error
- Check that the Apache configuration is properly loaded
- Verify the site is enabled: `docker exec rdn-server a2ensite rdn-server`
- Restart Apache: `docker exec rdn-server service apache2 reload`

#### Database Connection Issues
- Ensure the rdn-data container is healthy
- Check database credentials in config.conf
- Verify network connectivity between containers

#### Login Issues
- Verify the _login table exists in the database
- Check that the password matches the stored value
- Review Apache error logs: `docker exec rdn-server tail -f /var/log/apache2/error.log`

#### Missing Perl Modules
If you encounter "Can't locate [Module].pm" errors:
```bash
docker exec rdn-server apt-get update && apt-get install -y libjson-perl libdbi-perl libdbd-mysql-perl
```

### Log Files
- **Apache Error Log**: `/var/log/apache2/error.log`
- **Apache Access Log**: `/var/log/apache2/access.log`
- **RDN Application Log**: `/var/log/rdn/rdn.log`
- **Audit Log**: `/var/log/rdn/audit.log`

### Container Status
Check the status of all containers:
```bash
docker-compose ps
```

View logs for specific services:
```bash
docker-compose logs rdn-server
docker-compose logs rdn-data
docker-compose logs rdn-redis
```

## Security Considerations

### Production Deployment
1. Change all default passwords
2. Update the allowed IP ranges in config.conf
3. Enable SSL/TLS encryption
4. Configure proper firewall rules
5. Enable audit logging
6. Set up regular backups

### Network Security
- The application runs on a private Docker network (172.20.0.0/24)
- Only necessary ports are exposed to the host
- Consider using a reverse proxy (nginx) for SSL termination

### Data Protection
- Database contains sensitive host credentials
- Encrypt sensitive data at rest
- Use secure communication channels
- Implement proper access controls

## Backup and Recovery

### Database Backup
```bash
docker exec rdn-data mysqldump -u root -pchangeme rdn > backup.sql
```

### Full System Backup
```bash
docker-compose down
tar -czf rdn-backup-$(date +%Y%m%d).tar.gz rdn_server/ rdn_data/ logs/ nginx/
docker-compose up -d
```

### Recovery
```bash
docker-compose down
tar -xzf rdn-backup-YYYYMMDD.tar.gz
docker-compose up -d
```

## Development

### Local Development Setup
1. Clone the repository
2. Make changes to the source files
3. Restart the containers to apply changes:
```bash
docker-compose restart rdn-server
```

### Adding New Features
- CGI scripts go in `rdn_server/cgi-bin/rdn_server/`
- HTML/CSS/JS files go in `rdn_server/html/`
- Database schema changes go in `rdn_data/db/`

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review the application logs
3. Check the GitHub issues page
4. Contact the development team

## License

Copyright 2004-2025 RDN Networks. All rights reserved.

---

**Version**: 7.0.0 (RedDevil Enhanced)  
**Last Updated**: May 2025
