# Link26 BFF (최소 스텁)

앱이 호출하는 NHIS(BFF) 경로와 맞춘 **심사·연동용** 서버입니다. CODEF/공단 실연동은 여기서 확장하면 됩니다.

## 로컬 실행

```bash
cd bff
npm install
npm start
```

기본 포트: **8787** (`PORT` 환경변수로 변경 가능)

## Flutter 앱 `.env`

```env
NHIS_USE_MOCK=false
NHIS_BASE_URL=http://10.0.2.2:8787
```

- **Android 에뮬레이터**에서 PC의 서버: `10.0.2.2` (localhost 아님)
- **실기기·심사용 공개 URL**: Railway / Render / Fly.io 등에 배포 후 `https://...` 로 설정
- **임시 공개**: `npx ngrok http 8787` → 나온 https URL을 `NHIS_BASE_URL`에 넣기

## 엔드포인트

| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/health` | 헬스체크 |
| POST | `/v1/signup` | 앱 회원가입 연동 |
| POST | `/v1/login` | 앱 로그인 연동 |
| GET | `/v1/medications?phone=` | 복약 목록(JSON `items`) |

쿼리 `serviceKey`는 앱이 붙여도 이 스텁은 무시합니다.
