link26-frontend.vercel.app — APK 다운로드 수정

문제: /link26.apk 가 SPA index.html(text/html)로 내려와 100%에서 멈춤·설치 불가.

A) GitHub Pages (Link26-App, 권장)
  1) .\tool\enable_web_apk_download.ps1  (또는 git push — 커밋에 docs/link26.apk 포함)
  2) GitHub repo Settings → Pages → Source: GitHub Actions
  3) Actions "Deploy APK (GitHub Pages)" 성공 후:
     https://ahn12345.github.io/Link26-App/link26.apk  → 실제 APK

B) Vercel (link26-frontend) — 둘 중 하나
  · vercel.json: tool/web_download/vercel.json 복사 ( /link26.apk → Pages URL 리다이렉트 )
  · 또는 Vercel Dashboard → Redirects:
      /link26.apk → https://ahn12345.github.io/Link26-App/link26.apk

  (선택) public/link26.apk 로 동일 도메인 직접 호스팅 — vercel.json rewrites 가 .apk 제외 필수

배포 후 확인:
  curl -sI https://link26-frontend.vercel.app/link26.apk
  → Location: github.io... 또는 Content-Type: application/vnd.android.package-archive
  (text/html 이면 실패)
