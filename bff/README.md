# Link26 BFF (최소 스텁)

앱이 호출하는 NHIS(BFF) 경로와 맞춘 **심사·연동용** 서버입니다. CODEF/공단 실연동은 여기서 확장하면 됩니다.

## Node 없이 실행 (Flutter SDK만 있을 때) — 권장

프로젝트 **루트**에서:

```bash
dart run tool/link26_bff.dart
```

Windows PowerShell 예:

```powershell
cd C:\Users\byeon\OneDrive\문서\GitHub\Link26-App
dart run tool/link26_bff.dart
```

`flutter doctor` 가 되는 PC면 보통 `dart` 명령도 됩니다. 안 되면 `flutter pub global` 대신 **전체 경로**:  
`C:\path\to\flutter\bin\dart run tool/link26_bff.dart`

## Node 로 실행 (선택)

```bash
cd bff
npm install
npm start
```

포트 **8787 우선**, 이미 쓰이면 **8788 … 자동 시도**, 그래도 안 되면 **OS가 빈 포트 자동 할당**.  
콘솔에 `>>> 실제 포트: 숫자 <<<` 가 나오면 `.env` 의 `NHIS_BASE_URL` 포트를 **그 숫자와 동일**하게 맞추세요.

고정으로 쓰려면 (8788 예시):

```powershell
$env:PORT="8788"; dart run tool/link26_bff.dart
```

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
