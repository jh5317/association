// Supabase 접속 정보와 네이버 지도 키를 Vercel 환경 변수에서 읽어 브라우저에 전달합니다.
// 키 값은 저장소에 두지 않고 Vercel 환경 변수(로컬에서는 .env)에만 둡니다.
module.exports = (req, res) => {
  const config = {
    url: process.env.SUPABASE_URL || "",
    key: process.env.SUPABASE_PUBLISHABLE_KEY || process.env.SUPABASE_ANON_KEY || "",
    // 네이버 지도 Client ID는 브라우저에 공개되는 값이고 NCP에 등록한 주소에서만 동작합니다. (Client Secret은 넣지 않음)
    naverMapKey: process.env.NAVER_MAP_CLIENT_ID || "zgfmv56w4o",
  };
  res.setHeader("Content-Type", "application/javascript; charset=utf-8");
  res.setHeader("Cache-Control", "no-store");
  res.end(`window.SUPABASE_CONFIG = ${JSON.stringify(config)};`);
};
