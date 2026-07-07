const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const authHeader = req.headers.authorization || '';
  if (!authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing Google ID token' });
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
