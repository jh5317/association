# 사단법인 한국 오픈이노베이션 협회 홈페이지 (association)

사단법인 한국 오픈이노베이션 협회 공식 홈페이지 소스 코드 저장소입니다.
**홈페이지 주소: https://association-teal-eight.vercel.app** (Vercel, `main` 브랜치에 push하면 자동 배포)

별도 빌드 도구 없이 HTML/CSS/JS로 구성되어 있고, 회원·공지·교육 일정·자격증·문의 데이터는 Supabase에 저장합니다.
Supabase 접속 정보는 `api/config.js`(Vercel 함수)가 Vercel 환경 변수에서 읽어 브라우저에 전달하므로 저장소에는 키가 들어가지 않습니다.

## 폴더 구조

```
association/
├── index.html          # 메인 페이지
├── pages/
│   ├── about.html      # 법인 소개 (설립 목적, 연혁, 임원)
│   ├── certificate.html # 자격안내 (1급/2급, 취득 절차)
│   ├── education.html  # 교육안내 (과정, 일정, 신청)
│   ├── verify.html     # 자격증 진위 확인
│   ├── notice.html     # 공지사항 목록 (notice-view.html: 상세)
│   ├── donate.html     # 후원 안내
│   ├── contact.html    # 오시는 길 / 문의하기
│   ├── signup.html, login.html, reset.html  # 회원가입·로그인·비밀번호 재설정
│   ├── mypage.html     # 내 자격증·내 문의·회원 정보
│   ├── admin.html      # 관리자 (공지·교육 일정·자격증·문의·회원)
│   └── privacy.html    # 개인정보처리방침
├── api/config.js       # Vercel 함수: 환경 변수의 Supabase 접속 정보 전달
├── supabase/schema.sql # 데이터베이스 표·권한 (SQL Editor에서 실행)
├── scripts/dev-server.js # 로컬 미리보기 서버
├── css/style.css       # 공통 스타일
├── js/db.js            # Supabase 연결·로그인 상태 표시
├── js/main.js          # 공통 스크립트 (모바일 메뉴)
├── js/vendor/          # supabase-js 2.117.2
└── images/             # 로고, 사진 등
```

## Supabase 연결 방법

1. [supabase.com](https://supabase.com)에서 새 프로젝트를 만듭니다. (Region: Northeast Asia (Seoul) 권장)
2. **SQL Editor**에 `supabase/schema.sql` 전체를 붙여 넣고 **Run** 합니다. 표, 접근 권한, 처음 데이터가 만들어집니다.
3. **Authentication → URL Configuration**
   - Site URL: `https://association-teal-eight.vercel.app`
   - Redirect URLs: `https://association-teal-eight.vercel.app/**`
4. **Project Settings → API**(또는 API Keys)에서 Project URL과 publishable(anon) 키를 복사합니다.
5. **Vercel → 프로젝트 → Settings → Environment Variables**에 아래 두 값을 넣고 **Redeploy** 합니다.
   - `SUPABASE_URL`
   - `SUPABASE_PUBLISHABLE_KEY`
6. 홈페이지에서 관리자 이메일로 회원가입 → 메일 인증 후, SQL Editor에서 관리자로 지정합니다.
   ```sql
   update public.profiles set role = 'admin' where email = '관리자 이메일';
   ```

> `service_role`(secret) 키는 어디에도 넣지 마세요. 이 사이트는 publishable 키와 접근 권한(RLS)만으로 동작합니다.

## 데이터 구조

| 표 | 내용 | 누가 볼 수 있나 |
|---|---|---|
| `profiles` | 회원 정보 (이름, 연락처, 소속, 권한) | 본인, 관리자 |
| `notices` | 공지사항 | 누구나 (작성은 관리자) |
| `courses` | 교육 일정 | 누구나 (수정은 관리자) |
| `certificates` | 자격증 취득자 명부 | 관리자, 본인(가입 이메일 일치). 일반 방문자는 자격번호+이름 조회만 |
| `inquiries` | 문의 | 작성은 누구나, 열람은 본인·관리자 |

## 로컬에서 보기

```bash
cp .env.example .env      # .env 에 Supabase URL·키 입력 (깃허브에 올라가지 않음)
node scripts/dev-server.js
# 브라우저에서 http://localhost:3000 접속
```

## 수정할 곳

- 법인명: 사단법인 한국 오픈이노베이션 협회 (반영 완료)
- 대표자·고유번호·주소·연락처·후원 계좌: 반영 완료
