// Sends a behaviour report (chart + text) to the caller's Athar bot chat.
// Contract: specs/002-behaviour-insights/contracts/send-report-telegram.md
// Deployed with --no-verify-jwt: the caller is verified here with auth.getUser.
import { normalizeE164 } from "../_shared/phone.ts";
import { db, sendTelegram, sendTelegramPhoto } from "../_shared/telegram.ts";

const MAX_TEXT = 4000;
const MAX_PNG_BASE64 = 7_000_000; // ≈ 5 MB of image

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });

// Telegram answers 403 when the user blocked the bot.
const telegramFailure = (res: Response) =>
  res.status === 403
    ? json(409, { error: "telegram_blocked" })
    : json(502, { error: "telegram_failed" });

Deno.serve(async (req) => {
  const token = (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "");
  const { data } = await db.auth.getUser(token);
  const user = data?.user;
  if (!user) return json(401, { error: "unauthorized" });

  // Only accounts that signed in with Telegram (spec FR-010, FR-013).
  const phone = user.phone ? normalizeE164(user.phone) : null;
  if (!phone) return json(403, { error: "not_telegram_account" });

  let body: { text?: unknown; chartPngBase64?: unknown };
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "bad_request" });
  }
  const { text, chartPngBase64: png } = body;
  if (typeof text !== "string" || !text.trim() || text.length > MAX_TEXT) {
    return json(400, { error: "bad_request" });
  }
  if (png !== undefined && (typeof png !== "string" || png.length > MAX_PNG_BASE64)) {
    return json(400, { error: "bad_request" });
  }

  const { data: link } = await db.from("telegram_links").select("chat_id")
    .eq("phone", phone).maybeSingle();
  if (!link) return json(404, { error: "telegram_not_linked" });

  if (png) {
    let bytes: Uint8Array;
    try {
      bytes = Uint8Array.from(atob(png), (c) => c.charCodeAt(0));
    } catch {
      return json(400, { error: "bad_request" });
    }
    const sent = await sendTelegramPhoto(link.chat_id, bytes, "Your Athar report");
    if (!sent.ok) return telegramFailure(sent);
  }
  const sent = await sendTelegram(link.chat_id, text);
  if (!sent.ok) return telegramFailure(sent);
  return json(200, { ok: true });
});
