// 오른쪽 퀵메뉴 (넓은 화면은 오른쪽 세로, 좁은 화면은 아래쪽 가로 막대)
const QUICK_MENU = [
  { label: "교육안내", href: "pages/education.html", icon: '<path d="M5 4h11a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3z"/><path d="M5 17a3 3 0 0 1 3-3h11"/><circle cx="12" cy="7.5" r=".6" fill="currentColor"/><path d="M12 10v2"/>' },
  { label: "자격증<wbr>교육신청", href: "pages/education.html#apply", icon: '<rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4.5h6v2.5H9z"/><path d="M8.5 12h7M8.5 15.5h4.5"/>' },
  { label: "자격증 조회", href: "pages/verify.html", icon: '<circle cx="12" cy="9.5" r="5.5"/><path d="m9.7 9.6 1.6 1.6 3-3.2"/><path d="m8.6 14.3-1.6 6 5-2.3 5 2.3-1.6-6"/>' },
  { label: "1:1 문의하기", href: "pages/contact.html#inquiry", icon: '<path d="M4 13v-1a8 8 0 0 1 16 0v1"/><rect x="3" y="13" width="4" height="6" rx="1.5"/><rect x="17" y="13" width="4" height="6" rx="1.5"/><path d="M19 19c0 1.5-2 2.5-5 2.5"/>' },
];

function renderQuickMenu() {
  if (location.pathname.endsWith("/admin.html")) return;
  const root = location.pathname.includes("/pages/") ? "../" : "";
  const current = location.pathname.split("/").pop();
  const nav = document.createElement("nav");
  nav.className = "quick-menu";
  nav.setAttribute("aria-label", "퀵메뉴");
  // 같은 페이지를 가리키는 항목이 여럿이면 첫 항목만 선택 표시
  const activeItem = QUICK_MENU.find((item) => item.href.split("#")[0].endsWith("/" + current));
  nav.innerHTML = QUICK_MENU.map((item) => {
    const active = item === activeItem ? ' class="active"' : "";
    return `<a href="${root}${item.href}"${active}><svg viewBox="0 0 24 24" aria-hidden="true">${item.icon}</svg><span>${item.label}</span></a>`;
  }).join("") + '<button type="button" class="quick-top" aria-label="맨 위로">TOP</button>';
  nav.querySelector(".quick-top").addEventListener("click", () => window.scrollTo({ top: 0, behavior: "smooth" }));
  document.body.appendChild(nav);
  document.body.classList.add("has-quick-menu");
}

document.addEventListener("DOMContentLoaded", () => {
  const toggle = document.querySelector(".menu-toggle");
  const nav = document.querySelector(".nav");
  if (toggle && nav) {
    toggle.addEventListener("click", () => nav.classList.toggle("open"));
  }
  renderQuickMenu();
});
