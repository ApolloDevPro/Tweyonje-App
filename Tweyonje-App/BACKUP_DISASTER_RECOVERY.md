# Backup and Disaster Recovery Documentation

## Overview

This document outlines the backup and disaster recovery procedures for the Tweyonje application.

## Database Backup Strategy

### Automated Backups

#### PostgreSQL/PostGIS Database
- **Frequency**: Daily at 2:00 AM UTC
- **Retention**: 
  - Daily backups: 7 days
  - Weekly backups: 4 weeks
  - Monthly backups: 12 months
- **Method**: `pg_dump` with compression
- **Storage**: Encrypted S3 bucket with versioning

#### SQLite Database (Development)
- **Frequency**: On every schema change
- **Method**: File copy to backup directory
- **Storage**: Local backup directory

### Manual Backup Commands

#### PostgreSQL Backup
```bash
# Backup entire database
pg_dump -h localhost -U tweyonje -d tweyonje -F c -f backup_$(date +%Y%m%d).dump

# Backup with compression
pg_dump -h localhost -U tweyonje -d tweyonje | gzip > backup_$(date +%Y%m%d).sql.gz

# Backup specific tables
pg_dump -h localhost -U tweyonje -d tweyonje -t waste_requests -t users -f partial_backup.sql
```

#### SQLite Backup
```bash
# Copy database file
cp db.sqlite3 backups/db.sqlite3_$(date +%Y%m%d)

# Using Python management command
python manage.py backup_data --output backups/
```

### Restore Procedures

#### PostgreSQL Restore
```bash
# Restore from compressed backup
gunzip < backup_20240101.sql.gz | psql -h localhost -U tweyonje -d tweyonje

# Restore from custom format
pg_restore -h localhost -U tweyonje -d tweyonje -d tweyonje backup_20240101.dump

# Restore to new database
createdb tweyonje_restore
pg_restore -h localhost -U tweyonje -d tweyonje_restore backup_20240101.dump
```

#### SQLite Restore
```bash
# Restore from backup
cp backups/db.sqlite3_20240101 db.sqlite3
```

## File Storage Backup

### Media Files
- **Frequency**: Real-time sync
- **Method**: Rsync to backup server
- **Storage**: Separate backup server with RAID configuration

### Static Files
- **Frequency**: On deployment
- **Method**: Included in deployment artifacts
- **Storage**: CDN with origin server backup

## Configuration Backup

### Environment Variables
- **Frequency**: On change
- **Method**: Encrypted storage in secrets manager
- **Access**: Role-based access control

### SSL Certificates
- **Frequency**: As part of certificate renewal
- **Method**: Encrypted backup with key rotation
- **Storage**: Separate secure storage

## Disaster Recovery Procedures

### Scenario 1: Database Corruption

#### Detection
- Monitoring alerts for database errors
- Health check failures
- Application error spikes

#### Recovery Steps
1. **Immediate Actions**
   - Stop application to prevent further corruption
   - Notify stakeholders
   - Initiate incident response

2. **Assessment**
   - Identify extent of corruption
   - Determine point of failure
   - Select appropriate backup

3. **Recovery**
   - Restore from most recent clean backup
   - Verify data integrity
   - Test application functionality

4. **Validation**
   - Run data consistency checks
   - Verify critical user data
   - Test key application flows

5. **Post-Recovery**
   - Monitor for anomalies
   - Update documentation
   - Conduct post-mortem

### Scenario 2: Server Failure

#### Detection
- Server unresponsive
- Health check failures
- Network connectivity issues

#### Recovery Steps
1. **Immediate Actions**
   - Activate failover server
   - Redirect traffic to backup
   - Notify stakeholders

2. **Assessment**
   - Determine failure cause
   - Assess hardware damage
   - Estimate recovery time

3. **Recovery**
   - Replace failed hardware
   - Restore from backups
   - Verify system integrity

4. **Validation**
   - Test all services
   - Verify data consistency
   - Monitor performance

### Scenario 3: Data Loss Incident

#### Detection
- User reports of missing data
- Audit log anomalies
- Data integrity check failures

#### Recovery Steps
1. **Immediate Actions**
   - Identify affected data
   - Preserve evidence
   - Notify security team

2. **Investigation**
   - Determine cause of loss
   - Identify compromised accounts
   - Assess security impact

3. **Recovery**
   - Restore lost data from backups
   - Implement security fixes
   - Communicate with affected users

4. **Prevention**
   - Update security measures
   - Implement additional monitoring
   - Review access controls

## Backup Testing

### Regular Testing Schedule
- **Weekly**: Verify backup integrity
- **Monthly**: Test restore procedures
- **Quarterly**: Full disaster recovery drill

### Testing Procedures
1. **Backup Integrity**
   - Verify backup completion
   - Check file sizes and checksums
   - Test backup encryption

2. **Restore Testing**
   - Restore to test environment
   - Verify data consistency
   - Test application functionality

3. **Disaster Recovery Drill**
   - Simulate major failure scenario
   - Execute full recovery procedure
   - Measure recovery time objective (RTO)
   - Document lessons learned

## Monitoring and Alerting

### Backup Monitoring
- Backup completion status
- Backup file integrity
- Storage capacity
- Backup age monitoring

### Alert Thresholds
- Backup failure: Immediate alert
- Backup delayed > 1 hour: Warning
- Storage capacity > 80%: Warning
- Storage capacity > 90%: Critical

## Retention Policy

### Database Backups
- Daily: 7 days
- Weekly: 4 weeks
- Monthly: 12 months
- Yearly: 7 years

### Application Logs
- Application logs: 30 days
- Access logs: 90 days
- Security logs: 1 year

### Media Files
- User uploads: 90 days after account deletion
- System files: Per deployment cycle

## Security Considerations

### Backup Encryption
- All backups encrypted at rest
- Encryption keys rotated quarterly
- Keys stored in secure key management system

### Access Control
- Backup access restricted to authorized personnel
- Audit logging for all backup operations
- Role-based access control enforced

### Compliance
- GDPR compliance for user data
- Data retention policy adherence
- Regular security audits

## Contact Information

### Primary Contacts
- **Database Administrator**: dbadmin@tweyonje.ug
- **System Administrator**: sysadmin@tweyonje.ug
- **DevOps Engineer**: devops@tweyonje.ug

### Emergency Contacts
- **On-Call Engineer**: +256-700-000-000
- **Management**: management@tweyonje.ug

## Documentation Maintenance

- **Review Frequency**: Quarterly
- **Last Updated**: 2024-09-04
- **Next Review**: 2024-12-04
- **Maintainer**: DevOps Team

## Appendix

### Backup Scripts Location
- Production: `/opt/tweyonje/scripts/backups/`
- Staging: `/opt/tweyonje-staging/scripts/backups/`
- Development: `backend/scripts/backups/`

### Backup Storage Locations
- Primary: S3 bucket `tweyonje-backups-primary`
- Secondary: S3 bucket `tweyonje-backups-secondary`
- Offsite: Physical backup storage (quarterly)

### Related Documentation
- [Deployment Guide](backend/docs/DEPLOYMENT.md)
- [Security Policy](backend/docs/SECURITY.md)
- [Incident Response Plan](backend/docs/INCIDENT_RESPONSE.md)