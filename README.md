# 사단법인 홈페이지 (association)

사단법인 공식 홈페이지 소스 코드 저장소입니다.
별도 빌드 도구 없이 HTML/CSS/JS만으로 구성되어 있어 GitHub Pages, Netlify 등 정적 호스팅에 바로 배포할 수 있습니다.

## 폴더 구조

```
association/
├── index.html          # 메인 페이지
├── pages/
│   ├── about.html      # 법인 소개 (설립 목적, 연혁, 임원)
│   ├── notice.html     # 공지사항
│   ├── donate.html     # 후원 안내
│   └── contact.html    # 오시는 길 / 문의
├── css/style.css       # 공통 스타일
├── js/main.js          # 공통 스크립트 (모바일 메뉴)
└── images/             # 로고, 사진 등
```

## 로컬에서 보기

```bash
python3 -m http.server 8000
# 브라우저에서 http://localhost:8000 접속
```

## 수정할 곳

- 법인명: 각 HTML 파일의 `(사)법인명` 을 실제 이름으로 바꿔 주세요.
- 연락처·주소·고유번호·후원 계좌: `pages/contact.html`, `pages/donate.html`, 각 페이지 하단(footer).
