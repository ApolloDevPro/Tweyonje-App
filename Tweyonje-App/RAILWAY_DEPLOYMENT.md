# Railway Deployment Guide

## Prerequisites

1. **Railway account**: Sign up at https://railway.app
2. **Railway CLI** (optional): `npm install -g @railway/cli`
3. **GitHub repo**: Push your code to GitHub

## Step 1: Push to GitHub

```bash
cd C:\Users\APOLLO TURYAHEBWA\Desktop\Tweyonje\Tweyonje-App

# Initialize git if not already done
git init
git add .
git commit -m "Initial commit for deployment"

# Create GitHub repo and push
git remote add origin https://github.com/yourusername/Tweyonje-App.git
git push -u origin master
```

## Step 2: Create Railway Project

1. Go to https://railway.app/dashboard
2. Click **"New Project"**
3. Select **"Deploy from GitHub repo"**
4. Select your `Tweyonje-App` repository
5. Railway will detect the `backend` folder

## Step 3: Configure Service

1. In Railway dashboard, click on your service
2. Go to **Settings**
3. Under **Build**, set:
   - **Root Directory**: `backend`
   - **Dockerfile Path**: `docker/Dockerfile`

## Step 4: Add PostgreSQL Database

1. In Railway dashboard, click **"+ New"**
2. Select **"Database"** > **"PostgreSQL"**
3. Railway will create a PostgreSQL instance
4. Note the connection details (Railway auto-sets `DATABASE_URL`)

## Step 5: Set Environment Variables

Go to **Variables** tab in your service and add:

```bash
# Django Settings
DEBUG=False
SECRET_KEY=your-production-secret-key-here
ALLOWED_HOSTS=your-app.up.railway.app

# Database (auto-set by Railway PostgreSQL plugin)
# DATABASE_URL is set automatically

# Supabase
SUPABASE_URL=https://knskyxabdwxutyriravt.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtuc2t5eGFiZHd4dXR5cmlyYXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkwNDE2MDAsImV4cCI6MjEwNDYxNzYwMH0.Tx5fuOnpC2z0PRu5jzEznko34nnbRyH-sk7Txq7f8jk
SUPABASE_SERVICE_KEY=your-supabase-service-role-key-here
SUPABASE_JWT_SECRET=your-supabase-jwt-secret-here

# JWT
JWT_ACCESS_TOKEN_MINUTES=60
JWT_REFRESH_TOKEN_DAYS=7

# Payments
PAYMENT_PROVIDER=dev

# Notifications
SMS_PROVIDER=dev

# Celery (optional - use Railway Redis or disable)
CELERY_TASK_ALWAYS_EAGER=True
```

## Step 6: Generate Django Secret Key

Run this to generate a secure secret key:

```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

Copy the output and set it as `SECRET_KEY` in Railway.

## Step 7: Deploy

1. Railway auto-deploys when you push to GitHub
2. Or click **"Deploy"** in Railway dashboard
3. Watch the build logs for errors

## Step 8: Run Migrations

After first deploy, run migrations:

### Option A: Railway CLI
```bash
railway run python manage.py migrate
railway run python manage.py createsuperuser
```

### Option B: Railway Shell
1. In Railway dashboard, go to your service
2. Click **"Shell"** tab
3. Run:
```bash
python manage.py migrate
python manage.py createsuperuser
```

## Step 9: Verify Deployment

1. Get your app URL from Railway dashboard (e.g., `https://your-app.up.railway.app`)
2. Test the API:
```bash
curl https://your-app.up.railway.app/api/schema/
```

## Troubleshooting

### Build fails
- Check build logs in Railway dashboard
- Ensure `requirements.txt` is in `backend/` folder
- Ensure `docker/Dockerfile` path is correct

### App crashes on start
- Check deploy logs in Railway dashboard
- Verify all environment variables are set
- Check `DATABASE_URL` is set (from PostgreSQL plugin)

### Database connection errors
- Railway PostgreSQL uses `DATABASE_URL` env var
- Update `settings.py` to use `DATABASE_URL`:

```python
import dj_database_url
DATABASES = {
    'default': dj_database_url.config(default='sqlite:///db.sqlite3')
}
```

### Static files not loading
- Run `python manage.py collectstatic` in Railway shell
- Or add to build command in `railway.json`

## Useful Commands

```bash
# Login to Railway CLI
railway login

# Link to your project
railway link

# Run commands
railway run python manage.py shell
railway run python manage.py migrate

# View logs
railway logs

# Open Railway dashboard
railway open
```

## Cost

- **Hobby Plan**: $5/month (includes 500 hours usage)
- **PostgreSQL**: ~$1-5/month depending on usage
- **Total**: ~$6-10/month for small app

## Next Steps

1. Set up custom domain
2. Configure SSL (automatic on Railway)
3. Set up CI/CD for automatic deployments
4. Monitor with Railway metrics
