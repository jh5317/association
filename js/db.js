// Supabase 연결과 여러 페이지가 함께 쓰는 도구 모음
(function () {
  const cfg = window.SUPABASE_CONFIG || {};
  const ready = Boolean(cfg.url && cfg.key && window.supabase);
  const client = ready ? window.supabase.createClient(cfg.url, cfg.key) : null;
  const root = location.pathname.includes("/pages/") ? "../" : "";
  const days = ["일", "월", "화", "수", "목", "금", "토"];

  function esc(value) {
    return String(value ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  }

  // '2026-12-03' → '2026. 12. 3.(목)'
  function kdate(iso, withDay = true) {
    if (!iso) return "";
    const [y, m, d] = iso.slice(0, 10).split("-").map(Number);
    const day = days[new Date(Date.UTC(y, m - 1, d)).getUTCDay()];
    return `${y}. ${m}. ${d}.` + (withDay ? `(${day})` : "");
  }

  function won(n) {
    return n == null ? "추후 공지" : Number(n).toLocaleString("ko-KR") + "원";
  }

  function message(el, text, type = "info") {
    if (!el) return;
    el.className = "msg msg-" + type;
    el.textContent = text;
    el.hidden = !text;
  }

  function notReadyText() {
    return "현재 온라인 서비스 준비 중입니다. 문의: luckiest@korea.ac.kr / 02-3290-4411";
  }

  async function getUser() {
    if (!client) return null;
    const { data } = await client.auth.getSession();
    return data.session ? data.session.user : null;
  }

  async function getProfile() {
    const user = await getUser();
    if (!user) return null;
    const { data } = await client.from("profiles").select("*").eq("id", user.id).maybeSingle();
    return data;
  }

  // 로그인이 필요한 페이지에서 호출: 로그인 안 되어 있으면 로그인 페이지로 이동
  async function requireLogin() {
    const user = await getUser();
    if (!user) location.href = root + "pages/login.html?next=" + encodeURIComponent(location.pathname);
    return user;
  }

  async function renderAuthBar() {
    const bar = document.getElementById("auth-links");
    if (!bar || !client) return;
    const profile = await getProfile();
    if (!profile) return;
    bar.innerHTML =
      `<span>${esc(profile.name || profile.email)}님</span>` +
      (profile.role === "admin" ? `<a href="${root}pages/admin.html">관리자</a>` : "") +
      `<a href="${root}pages/mypage.html">마이페이지</a>` +
      `<a href="#" id="logout-link">로그아웃</a>`;
    document.getElementById("logout-link").addEventListener("click", async (e) => {
      e.preventDefault();
      await client.auth.signOut();
      location.href = root + "index.html";
    });
  }

  window.DB = { client, ready, root, esc, kdate, won, message, notReadyText, getUser, getProfile, requireLogin };
  document.addEventListener("DOMContentLoaded", renderAuthBar);
})();
