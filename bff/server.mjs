/**
 * Link26 최소 BFF — 앱 심사·연동 검증용.
 * 가입/로그인 POST 는 200 JSON 만 반환, 복약 GET 은 앱 파서가 읽는 items 형식.
 * CODEF·공단 실연동은 이 서버 안에서 추후 확장.
 */
import express from 'express';

const app = express();
app.use(express.json({ limit: '256kb' }));

app.use((req, res, next) => {
  res.setHeader('X-Link26-Bff', '1');
  next();
});

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'link26-bff' });
});

app.post('/v1/signup', (req, res) => {
  res.status(200).json({
    ok: true,
    flow: 'signup',
    receivedAt: new Date().toISOString(),
  });
});

app.post('/v1/login', (req, res) => {
  res.status(200).json({
    ok: true,
    flow: 'login',
    receivedAt: new Date().toISOString(),
  });
});

app.get('/v1/medications', (req, res) => {
  const phone = typeof req.query.phone === 'string' ? req.query.phone : '';
  res.status(200).json({
    items: [
      {
        name: '심사·데모 복약 안내',
        dose: '-',
        frequency: '1일 1회',
        time: '09:00',
      },
      {
        name: '종합비타민(예시)',
        dose: '1정',
        frequency: '1일 1회',
        time: '12:00',
      },
    ],
    meta: { phone, source: 'link26-bff-stub' },
  });
});

const port = Number.parseInt(process.env.PORT ?? '8787', 10);
app.listen(port, '0.0.0.0', () => {
  console.log(`link26-bff listening on http://0.0.0.0:${port}`);
  console.log(`  POST /v1/signup  POST /v1/login  GET /v1/medications  GET /health`);
});
