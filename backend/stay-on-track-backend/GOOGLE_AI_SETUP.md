# Google AI (Gemini) Setup Guide

The planner can use **Google Gemini AI** to generate smarter, personalized study plans. Follow these steps to enable it.

## 1. Get Your API Key

1. Go to [Google AI Studio](https://aistudio.google.com/apikey)
2. Sign in with your Google account
3. Click **Create API Key**
4. Copy the key (it looks like `AIzaSy...`)

## 2. Add the Key to Your Backend

**Option A: application.properties** (for local development)

Edit `src/main/resources/application.properties` and add:

```properties
google.ai.api-key=YOUR_API_KEY_HERE
```

**Option B: Environment variable** (for production)

```bash
export GOOGLE_AI_API_KEY=YOUR_API_KEY_HERE
```

Or in Windows PowerShell:
```powershell
$env:GOOGLE_AI_API_KEY="YOUR_API_KEY_HERE"
```

Then add to `application.properties`:
```properties
google.ai.api-key=${GOOGLE_AI_API_KEY:}
```

## 3. Restart the Backend

After adding the key, restart the Spring Boot application. When you use **Regenerate Next Week Plan** or **Generate Plan**, the AI will create task suggestions based on your deadlines and feedback.

## 4. Without API Key

If no key is configured, the planner uses **rule-based** logic: it creates tasks from your deadlines (e.g., "Prepare for Midterm", "Work on Lab 1"). The app works fully without Gemini.

## Security

- **Never commit your API key** to git. Add `application.properties` with secrets to `.gitignore` if needed.
- Google AI Studio has a free tier with rate limits. For production, consider Vertex AI.
