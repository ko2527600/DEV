# Email Verification Site for Medication Reminder App

This is a simple website for handling email verification redirects from Supabase authentication.

## Files Structure
```
verification-site/
├── index.html                 # Main landing page
├── auth/callback/index.html   # Email verification callback page
├── _redirects                 # Netlify redirects configuration
└── README.md                  # This file
```

## Deployment to Netlify

### Method 1: Drag & Drop (Easiest)
1. Go to [netlify.com](https://netlify.com)
2. Sign up for a free account
3. Drag the entire `verification-site` folder to the deploy area
4. Get your URL (e.g., `https://amazing-app-123.netlify.app`)

### Method 2: GitHub Integration
1. Push this folder to a GitHub repository
2. Connect Netlify to your GitHub account
3. Select the repository and deploy

## Supabase Configuration

After deployment, update your Supabase settings:

1. Go to Supabase Dashboard → Authentication → URL Configuration
2. Set **Site URL**: `https://your-netlify-url.netlify.app`
3. Set **Redirect URLs**: `https://your-netlify-url.netlify.app/auth/callback`

## Custom Domain (Optional)

1. Buy a domain (e.g., `medicationreminder.com`)
2. In Netlify: Site Settings → Domain Management
3. Add your custom domain
4. Update Supabase URLs to use your custom domain

## Testing

1. Deploy the site
2. Update Supabase URLs
3. Sign up a test user in your app
4. Check email and click verification link
5. Should see the verification success page

## Features

- ✅ Responsive design
- ✅ Professional appearance
- ✅ Clear user instructions
- ✅ Mobile-friendly
- ✅ Auto-redirect handling
- ✅ Deep link attempts (for future app versions)
