# PostgreSQL Setup Guide

This guide explains how to set up PostgreSQL with PostGIS for the Tweyonje application locally.

## Prerequisites

- Windows 10/11
- Python 3.11+
- PostgreSQL 16 with PostGIS 3.4

## Installation

### Option 1: Using PostgreSQL Installer (Recommended)

1. **Download PostgreSQL**
   - Visit https://www.postgresql.org/download/windows/
   - Download PostgreSQL 16 installer
   - During installation, select the following components:
     - PostgreSQL Server
     - pgAdmin 4 (optional, for GUI management)
     - Command Line Tools
   - Set a password for the postgres user (remember this!)
   - Set port to 5432 (default)

2. **Install PostGIS Extension**
   - Download PostGIS for PostgreSQL 16 from https://postgis.net/windows_downloads/
   - Run the installer and select your PostgreSQL installation directory
   - The installer will automatically enable PostGIS in the template database

### Option 2: Using Docker (Alternative)

1. **Install Docker Desktop**
   - Download from https://www.docker.com/products/docker-desktop/
   - Install and start Docker Desktop

2. **Run PostgreSQL with PostGIS**
   ```powershell
   docker run --name tweyonje-postgres -e POSTGRES_PASSWORD=change-me -e POSTGRES_DB=tweyonje -e POSTGRES_USER=tweyonje -p 5433:5432 -d postgis/postgis:16-3.4
   ```
   > Note: port `5433` is used instead of the default `5432` on this machine because another local PostgreSQL instance already occupies `5432`. Adjust `DB_PORT` in `.env` if you use a different host port.

## Database Setup

### Create Database

1. **Open pgAdmin or Command Line**
   - Using pgAdmin: Connect to your PostgreSQL server
   - Using command line: Open PowerShell and run:
     ```powershell
     psql -U postgres
     ```

2. **Create Database and User**
   ```sql
   CREATE DATABASE tweyonje;
   CREATE USER tweyonje WITH PASSWORD 'change-me';
   GRANT ALL PRIVILEGES ON DATABASE tweyonje TO tweyonje;
   ```

3. **Enable PostGIS Extension**
   ```sql
   \c tweyonje
   CREATE EXTENSION postgis;
   CREATE EXTENSION postgis_topology;
   ```

4. **Verify Installation**
   ```sql
   SELECT PostGIS_Version();
   ```
   You should see PostGIS version information.

## Configure Backend

### Update .env File

Create or update `backend/.env` with:

```bash
DEBUG=True
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=localhost,127.0.0.1

# Database (PostgreSQL with PostGIS)
DB_NAME=tweyonje
DB_USER=tweyonje
DB_PASSWORD=change-me
DB_HOST=localhost
DB_PORT=5433
USE_POSTGIS=true
DB_CONN_MAX_AGE=60

# JWT
JWT_ACCESS_TOKEN_MINUTES=15
JWT_REFRESH_TOKEN_DAYS=30
```

### Install Python Dependencies

```powershell
cd Tweyonje-App\backend
.venv\Scripts\activate
pip install -r requirements.txt
```

### Run Migrations

```powershell
python manage.py migrate
```

### Seed Data

```powershell
python manage.py seed_data
```

### Create Superuser

```powershell
python manage.py createsuperuser
```

### Run Server

```powershell
python manage.py runserver
```

## Testing

### Test Database Connection

```powershell
python manage.py dbshell
```

You should be connected to the PostgreSQL database.

### Test PostGIS

```powershell
python manage.py shell
```

Then run:
```python
from django.contrib.gis.geos import Point
p = Point(0, 0)
print(p)
```

## Troubleshooting

### Connection Issues

**Problem**: "connection to server at "localhost" (::1), port 5432 failed"

**Solution**: PostgreSQL might be listening on IPv4 only. Try:
- Change `DB_HOST` to `127.0.0.1` instead of `localhost`
- Or enable IPv6 in PostgreSQL configuration

**Problem**: "FATAL: password authentication failed"

**Solution**:
- Verify password in `.env` matches PostgreSQL user password
- Check pg_hba.conf authentication settings

### PostGIS Issues

**Problem**: "extension 'postgis' does not exist"

**Solution**:
- Ensure PostGIS is installed
- Run `CREATE EXTENSION postgis;` in the database
- Verify with `SELECT * FROM pg_extension WHERE extname = 'postgis';`

### Port Issues

**Problem**: "port 5432 is already in use"

**Solution**:
- Check if PostgreSQL is already running
- Change port in PostgreSQL configuration
- Update `DB_PORT` in `.env`

## Backup and Restore

### Backup Database

```powershell
pg_dump -U tweyonje -d tweyonje > backup.sql
```

### Restore Database

```powershell
psql -U tweyonje -d tweyonje < backup.sql
```

### Using Django Command

```powershell
python manage.py backup_data --output backups
```

## Performance Tuning

### PostgreSQL Configuration

Edit `postgresql.conf` (location varies by installation):

```ini
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 2621kB
min_wal_size = 1GB
max_wal_size = 4GB
```

Restart PostgreSQL after changes.

## Security

### Change Default Passwords

- Change postgres user password
- Change tweyonje user password
- Use strong passwords in production

### Firewall

- Restrict PostgreSQL port (5432) to local connections only
- Use SSL for production connections

### User Permissions

- Grant only necessary permissions
- Use separate users for different applications

## Monitoring

### View Active Connections

```sql
SELECT * FROM pg_stat_activity;
```

### View Database Size

```sql
SELECT pg_size_pretty(pg_database_size('tweyonje'));
```

### View Table Sizes

```sql
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Next Steps

After PostgreSQL is set up:

1. Run migrations: `python manage.py migrate`
2. Seed data: `python manage.py seed_data`
3. Create superuser: `python manage.py createsuperuser`
4. Start server: `python manage.py runserver`
5. Test API at http://localhost:8000/api/docs/

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostGIS Documentation](https://postgis.net/documentation/)
- [Django GIS Documentation](https://docs.djangoproject.com/en/stable/ref/contrib/gis/)
