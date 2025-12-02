# Environment Setup Guide

This guide explains how to configure environment variables for Signal Champ.

## Quick Start

### 1. Copy the Template

```bash
cp assets/.env.example assets/.env
```

### 2. Edit the File

Open `assets/.env` and fill in your credentials:

```bash
nano assets/.env
# or
code assets/.env
# or use your preferred editor
```

### 3. Verify Configuration

Run the app and check the console output:

```bash
flutter run
```

Look for:
```
✅ Environment loaded successfully
✓ SUPABASE_URL loaded: https://...
✓ OPENAI_API_KEY loaded: sk-proj-...
```

---

## Required Services

### Core App (No setup required)
The railway simulation works out of the box without any configuration.

### Optional Features

#### 🌩️ Supabase (Cloud Storage)
**Enables:** Save/load simulation states to cloud

1. Sign up at [supabase.com](https://supabase.com)
2. Create a new project
3. Navigate to: **Project Settings → API**
4. Copy these values:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** key → `SUPABASE_ANON_KEY`

**Example:**
```env
SUPABASE_URL=https://xyzabc123.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### 🤖 OpenAI (AI Features)
**Enables:** AI Agent Panel, intelligent suggestions

1. Sign up at [platform.openai.com](https://platform.openai.com)
2. Navigate to: **API Keys**
3. Click **Create new secret key**
4. Copy the key (starts with `sk-proj-` or `sk-`)

**Example:**
```env
OPENAI_API_KEY=sk-proj-abc123def456...
OPENAI_MODEL=gpt-3.5-turbo
```

**Available Models:**
- `gpt-3.5-turbo` - Fast and economical (default)
- `gpt-4` - More capable, slower
- `gpt-4-turbo-preview` - Balanced performance

#### 🐛 Sentry (Crash Reporting)
**Enables:** Automatic error tracking

1. Sign up at [sentry.io](https://sentry.io)
2. Create a new project (choose Flutter/Dart)
3. Navigate to: **Project Settings → Client Keys (DSN)**
4. Copy the DSN URL

**Example:**
```env
SENTRY_DSN=https://abc123@o456789.ingest.sentry.io/123456
```

---

## File Structure

```
signal_champ/
├── assets/
│   ├── .env              ← Your actual credentials (NOT committed)
│   └── .env.example      ← Template (committed to repo)
├── .gitignore            ← Ensures .env is never committed
└── ENVIRONMENT_SETUP.md  ← This file
```

---

## Testing Your Configuration

### Connection Debug Panel

1. Run the app: `flutter run`
2. Look for connection status in debug output
3. Check the UI for connection indicators

Expected output:
```
✓ .env file found
✓ SUPABASE_URL loaded: https://...
✓ SUPABASE_ANON_KEY loaded: eyJ...
✓ OPENAI_API_KEY loaded: sk-proj-...
✓ SENTRY_DSN loaded: https://...
```

### Test Individual Services

**Supabase:**
- Try saving a simulation state
- Check Supabase dashboard for data

**OpenAI:**
- Open AI Agent Panel (if available in UI)
- Try requesting AI suggestions

**Sentry:**
- Navigate to: **Settings → Crash Reports**
- Click **Test Crash** button
- Check Sentry dashboard for the event

---

## Troubleshooting

### ❌ ".env file NOT found"

**Cause:** File doesn't exist or wrong location

**Solution:**
```bash
# Check if file exists
ls -la assets/.env

# If not, copy from template
cp assets/.env.example assets/.env
```

---

### ❌ "SUPABASE_URL loaded:" (empty value)

**Cause:** Incorrect formatting in .env file

**Solution:** Ensure no spaces around `=` sign

✅ **Correct:**
```env
SUPABASE_URL=https://example.supabase.co
```

❌ **Incorrect:**
```env
SUPABASE_URL = https://example.supabase.co
SUPABASE_URL= https://example.supabase.co
SUPABASE_URL =https://example.supabase.co
```

---

### ❌ "Failed to initialize OpenAI service"

**Causes:**
1. Invalid API key
2. Expired API key
3. No billing set up on OpenAI account

**Solutions:**
1. Verify key at [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Check if key is active (not revoked)
3. Ensure billing is configured on your OpenAI account

---

### ❌ Changes not taking effect

**Cause:** Hot reload doesn't reload .env file

**Solution:** Full app restart required
```bash
# Stop the app
Ctrl+C

# Restart
flutter run
```

---

### ❌ "Invalid Supabase credentials"

**Causes:**
1. Wrong URL format
2. Wrong API key (used service_role instead of anon)
3. Project is paused/deleted

**Solutions:**
1. Ensure URL format: `https://[project-id].supabase.co`
2. Use **anon/public** key, NOT service_role key
3. Check project status in Supabase dashboard

---

## Security Best Practices

### ✅ DO:

- Keep `assets/.env` in `.gitignore` ✓ (Already configured)
- Use separate credentials for development and production
- Rotate API keys regularly (every 90 days recommended)
- Use environment-specific files for team members
- Share credentials via secure channels (password manager)

### ❌ DON'T:

- Never commit `assets/.env` to version control
- Never share credentials in pull requests or issues
- Never use production keys in development
- Never hardcode credentials in source code
- Never post credentials in screenshots or logs

---

## Sharing with Team

### For New Team Members:

1. Share the `.env.example` file (safe to commit)
2. Have them copy to `.env`:
   ```bash
   cp assets/.env.example assets/.env
   ```
3. Share credentials securely:
   - Use a password manager (1Password, LastPass, Bitwarden)
   - Or encrypted messaging (Signal, Wire)
   - Or secure company vault

### For Production Deployment:

- Set environment variables in your CI/CD platform
- Use secrets management (GitHub Secrets, GitLab CI/CD Variables)
- Never include `.env` in build artifacts

---

## Environment Variables Reference

| Variable | Required? | Default | Purpose |
|----------|-----------|---------|---------|
| `SUPABASE_URL` | No | - | Cloud storage endpoint |
| `SUPABASE_ANON_KEY` | No | - | Supabase authentication |
| `OPENAI_API_KEY` | No | - | AI features access |
| `OPENAI_MODEL` | No | `gpt-3.5-turbo` | AI model selection |
| `SENTRY_DSN` | No | - | Crash reporting endpoint |

---

## Getting Help

### Check Logs

```bash
# Run with verbose logging
flutter run -v

# Check for environment loading messages
grep "Loading environment" <log-output>
```

### Verify File Contents

```bash
# Show .env contents (be careful not to share output!)
cat assets/.env

# Check file permissions
ls -l assets/.env
```

### Common Issues Checklist

- [ ] File exists at `assets/.env` (not `.env.example`)
- [ ] File has correct format (KEY=value with no spaces)
- [ ] Credentials are valid and not expired
- [ ] App was fully restarted after editing .env
- [ ] pubspec.yaml includes `- assets/.env` in assets section
- [ ] flutter pub get was run after setup

---

## Additional Resources

- [Flutter dotenv package docs](https://pub.dev/packages/flutter_dotenv)
- [Supabase Flutter docs](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [OpenAI API docs](https://platform.openai.com/docs)
- [Sentry Flutter docs](https://docs.sentry.io/platforms/flutter/)

---

**Last Updated:** 2025-12-02
**Signal Champ Version:** Current
