-- 사단법인 한국 오픈이노베이션 협회 홈페이지 데이터베이스
-- Supabase 대시보드 > SQL Editor 에 전체를 붙여 넣고 Run 하세요.
-- 여러 번 실행해도 안전하도록 작성되어 있습니다.

-- ─────────────────────────────────────────────
-- 1. 회원 정보 (profiles)
--    Supabase 로그인 계정(auth.users) 1개당 1줄
-- ─────────────────────────────────────────────
create table if not exists public.profiles (
  id               uuid primary key references auth.users (id) on delete cascade,
  email            text not null,
  name             text not null default '',
  phone            text not null default '',
  organization     text not null default '',
  role             text not null default 'member' check (role in ('member', 'admin')),
  marketing_agree  boolean not null default false,
  created_at       timestamptz not null default now()
);

-- 관리자 여부 확인 (정책 안에서 사용)
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

-- 회원가입 시 profiles 자동 생성
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name, phone, organization, marketing_agree)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'name', ''),
    coalesce(new.raw_user_meta_data ->> 'phone', ''),
    coalesce(new.raw_user_meta_data ->> 'organization', ''),
    coalesce((new.raw_user_meta_data ->> 'marketing_agree')::boolean, false)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ─────────────────────────────────────────────
-- 2. 교육 일정 (courses)
-- ─────────────────────────────────────────────
create table if not exists public.courses (
  id          bigint generated always as identity primary key,
  title       text not null,
  grade       text not null check (grade in ('1급', '2급', '기타')),
  cohort      int,
  edu_start   date,
  edu_end     date,
  exam_date   date,
  result_date date,
  schedule_note text not null default '',
  location    text not null default '',
  capacity    int,
  fee         int,
  exam_fee    int,
  status      text not null default '모집예정' check (status in ('모집예정', '모집중', '마감', '종료', '준비중')),
  apply_url   text not null default '',
  sort_order  int not null default 0,
  created_at  timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- 3. 공지사항 (notices)
-- ─────────────────────────────────────────────
create table if not exists public.notices (
  id            bigint generated always as identity primary key,
  category      text not null default '공지' check (category in ('공지', '교육', '자격', '보도자료')),
  title         text not null,
  body          text not null default '',
  is_pinned     boolean not null default false,
  published_at  date not null default current_date,
  created_at    timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- 4. 자격증 취득자 명부 (certificates)
--    일반 공개 조회는 verify_certificate() 함수로만 가능
-- ─────────────────────────────────────────────
create table if not exists public.certificates (
  id          bigint generated always as identity primary key,
  cert_number text not null unique,
  name        text not null,
  email       text not null default '',
  grade       text not null check (grade in ('1급', '2급')),
  issued_at   date not null,
  course_id   bigint references public.courses (id) on delete set null,
  status      text not null default '유효' check (status in ('유효', '취소')),
  created_at  timestamptz not null default now()
);

-- 자격번호 + 이름이 모두 맞을 때만 결과를 돌려줌 (명부 전체는 노출하지 않음)
create or replace function public.verify_certificate(p_cert_number text, p_name text)
returns table (cert_number text, name text, grade text, issued_at date, status text)
language sql
stable
security definer
set search_path = public
as $$
  select c.cert_number, c.name, c.grade, c.issued_at, c.status
  from public.certificates c
  where c.cert_number = trim(p_cert_number)
    and c.name = trim(p_name);
$$;

-- ─────────────────────────────────────────────
-- 5. 문의 (inquiries)
-- ─────────────────────────────────────────────
create table if not exists public.inquiries (
  id          bigint generated always as identity primary key,
  user_id     uuid references auth.users (id) on delete set null,
  name        text not null,
  email       text not null,
  phone       text not null default '',
  category    text not null default '일반' check (category in ('일반', '교육', '자격', '후원', '제휴')),
  message     text not null,
  status      text not null default '접수' check (status in ('접수', '답변완료')),
  answer      text not null default '',
  created_at  timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- 접근 권한 (Row Level Security)
-- ─────────────────────────────────────────────
alter table public.profiles     enable row level security;
alter table public.courses      enable row level security;
alter table public.notices      enable row level security;
alter table public.certificates enable row level security;
alter table public.inquiries    enable row level security;

-- profiles: 본인 정보 보기·수정, 관리자는 전체 보기
drop policy if exists "본인 프로필 조회" on public.profiles;
create policy "본인 프로필 조회" on public.profiles
  for select to authenticated using (id = auth.uid() or public.is_admin());
drop policy if exists "본인 프로필 수정" on public.profiles;
create policy "본인 프로필 수정" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
-- 회원은 이름·연락처·소속·수신동의만 바꿀 수 있음 (role·email 은 변경 불가)
revoke update on public.profiles from authenticated, anon;
grant update (name, phone, organization, marketing_agree) on public.profiles to authenticated;

-- courses / notices: 누구나 보기, 관리자만 쓰기
drop policy if exists "교육 일정 공개" on public.courses;
create policy "교육 일정 공개" on public.courses for select using (true);
drop policy if exists "교육 일정 관리" on public.courses;
create policy "교육 일정 관리" on public.courses
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "공지 공개" on public.notices;
create policy "공지 공개" on public.notices for select using (true);
drop policy if exists "공지 관리" on public.notices;
create policy "공지 관리" on public.notices
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- certificates: 관리자 전체 관리, 회원은 가입 이메일과 같은 자격증만 보기
drop policy if exists "내 자격증 조회" on public.certificates;
create policy "내 자격증 조회" on public.certificates
  for select to authenticated
  using (public.is_admin() or (email <> '' and lower(email) = lower(auth.jwt() ->> 'email')));
drop policy if exists "자격증 관리" on public.certificates;
create policy "자격증 관리" on public.certificates
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- inquiries: 누구나 남기기, 본인 문의 보기, 관리자 전체 관리
drop policy if exists "문의 작성" on public.inquiries;
create policy "문의 작성" on public.inquiries
  for insert to anon, authenticated
  with check (status = '접수' and answer = '' and (user_id is null or user_id = auth.uid()));
drop policy if exists "내 문의 조회" on public.inquiries;
create policy "내 문의 조회" on public.inquiries
  for select to authenticated using (user_id = auth.uid() or public.is_admin());
drop policy if exists "문의 관리" on public.inquiries;
create policy "문의 관리" on public.inquiries
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "문의 삭제" on public.inquiries;
create policy "문의 삭제" on public.inquiries
  for delete to authenticated using (public.is_admin());

grant execute on function public.verify_certificate(text, text) to anon, authenticated;

-- ─────────────────────────────────────────────
-- 처음 데이터 (표가 비어 있을 때만 넣음)
-- ─────────────────────────────────────────────
insert into public.courses (title, grade, cohort, edu_start, edu_end, exam_date, result_date, location, capacity, fee, exam_fee, status, sort_order)
select '오픈이노베이션 전문가 2급', '2급', 1, '2026-12-03', '2026-12-04', '2026-12-11', '2026-12-18', '서울창조경제혁신센터 (서울 용산구)', 30, 660000, 100000, '모집예정', 1
where not exists (select 1 from public.courses);

insert into public.courses (title, grade, schedule_note, location, status, sort_order)
select '오픈이노베이션 전문가 1급 심화과정', '1급', '2급 1기 자격 취득 1년 후 개설 예정', '추후 공지', '준비중', 2
where not exists (select 1 from public.courses where grade = '1급');

insert into public.notices (category, title, body, is_pinned, published_at)
select * from (values
  ('교육', '오픈이노베이션 전문가 2급 1기 교육 안내 (12/3~4, 서울창조경제혁신센터)',
   E'오픈이노베이션 전문가 2급 1기 교육을 아래와 같이 진행합니다.\n\n- 교육: 2026. 12. 3.(목) ~ 12. 4.(금) 09:00 ~ 18:00, 2일간 (총 16시간)\n- 장소: 서울창조경제혁신센터 (서울 용산구)\n- 정원: 30명\n- 수강료: 660,000원 (교재·강의료 포함)\n- 시험 응시료 및 자격증 발급비: 100,000원 (별도)\n- 시험: 2026. 12. 11.(금), 2시간, 100점 만점 60점 이상 합격\n- 합격 발표: 2026. 12. 18.(금)\n\n신청과 납부는 한국생산성본부 신청 페이지에서 진행합니다.', true, date '2026-10-24'),
  ('공지', '2026년 정기총회 개최 안내', '정기총회 일정은 추후 안내드리겠습니다.', false, date '2026-10-24'),
  ('공지', '홈페이지 오픈 안내', '사단법인 한국 오픈이노베이션 협회 홈페이지를 오픈했습니다.', false, date '2026-10-24')
) as v(category, title, body, is_pinned, published_at)
where not exists (select 1 from public.notices);

-- ─────────────────────────────────────────────
-- 관리자 지정 (회원가입을 마친 뒤, 이메일을 바꿔서 따로 실행)
-- update public.profiles set role = 'admin' where email = 'luckiest@korea.ac.kr';
-- ─────────────────────────────────────────────
