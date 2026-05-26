link26-frontend.vercel.app — APK 다운로드 수정

문제: /Link26-1.0.0.apk 가 HTML(SPA)로 내려와 설치 불가.

해결 (프론트 GitHub repo):

1) public/Link26-1.0.0.apk  (이 zip 의 public/Link26-1.0.0.apk)
2) public/link26-bff.json   (BFF HTTPS 주소를 nhisBffBases 에 넣기)
3) vercel.json              (이 zip 의 vercel.json — 기존 파일과 병합)

Next.js: public/ 폴더는 빌드 전에 그대로 배포됩니다.
vercel.json 의 rewrites 가 .apk 를 index.html 로 덮지 않도록 이 파일을 사용하세요.

배포 후 확인:
  https://link26-frontend.vercel.app/Link26-1.0.0.apk
  → 파일 다운로드만 시작 (HTML 페이지가 보이면 실패)

선택: public/download/index.html
