const { OAuth2Client } = require('google-auth-library');

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const GOOGLE_WEB_CLIENT_ID =
  process.env.GOOGLE_WEB_CLIENT_ID ||
  '669192163812-1c4eglr4tpdpj0ovh2ff3i0fppucmjui.apps.googleusercontent.com';

const oauthClient = new OAuth2Client(GOOGLE_WEB_CLIENT_ID);

/** Simple per-user rate limit (best-effort on serverless). */
const RATE_WINDOW_MS = 60_000;
const RATE_MAX = 30;
const rateBuckets = new Map();

function allowRequest(subject) {
  const now = Date.now();
  let bucket = rateBuckets.get(subject);
  if (!bucket || now - bucket.windowStart > RATE_WINDOW_MS) {
    bucket = { windowStart: now, count: 0 };
    rateBuckets.set(subject, bucket);
  }
  bucket.count += 1;
  return bucket.count <= RATE_MAX;
}

async function verifyGoogleIdToken(idToken) {
  const ticket = await oauthClient.verifyIdToken({
    idToken,
    audience: GOOGLE_WEB_CLIENT_ID,
  });
  const payload = ticket.getPayload();
  if (!payload || !payload.sub) {
    throw new Error('Invalid token payload');
  }
  return payload;
}

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const authHeader = req.headers.authorization || '';
  if (!authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing Google ID token' });
    return;
  }

  const idToken = authHeader.slice('Bearer '.length).trim();
  if (!idToken) {
    res.status(401).json({ error: 'Missing Google ID token' });
    return;
  }

  let subject;
  try {
    const payload = await verifyGoogleIdToken(idToken);
    subject = payload.sub;
  } catch (error) {
    res.status(401).json({ error: 'Invalid Google ID token' });
    return;
  }

  if (!allowRequest(subject)) {
    res.status(429).json({ error: 'Too many AI requests. Try again in a minute.' });
    return;
  }

  const groqKey = process.env.GROQ_API_KEY;
  if (!groqKey) {
    res.status(500).json({ error: 'GROQ_API_KEY not configured on server' });
    return;
  }

  const {
    system,
    user,
    messages,
    model = 'llama-3.3-70b-versatile',
    max_tokens = 900,
    temperature = 0.4,
  } = req.body || {};

  let chatMessages;
  if (Array.isArray(messages) && messages.length > 0 && system) {
    chatMessages = [{ role: 'system', content: system }, ...messages];
  } else if (system && user) {
    chatMessages = [
      { role: 'system', content: system },
      { role: 'user', content: user },
    ];
  } else {
    res.status(400).json({ error: 'system prompt and user or messages are required' });
    return;
  }

  try {
    const groqResponse = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${groqKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        temperature,
        max_tokens,
        messages: chatMessages,
      }),
    });

    const data = await groqResponse.json();
    if (!groqResponse.ok) {
      res.status(groqResponse.status).json(data);
      return;
    }

    const content = data?.choices?.[0]?.message?.content?.trim() || '';
    res.status(200).json({ content });
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
};
