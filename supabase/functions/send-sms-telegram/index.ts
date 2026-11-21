// Supabase Auth "Send SMS" hook: delivers the phone OTP through the Athar Telegram bot.
// Contract: specs/001-otp-auth/contracts/send-sms-telegram.md
import { Webhook } from "npm:standardwebhooks@1.0.0";
import { normalizeE164 } from "../_shared/phone.ts";
import { db, sendTelegram } from "../_shared/telegram.ts";

const hook = new Webhook(
  Deno.env.get("SEND_SMS_HOOK_SECRET")!.replace("v1,whsec_", ""),
);

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
const fail = (status: number, message: string) =>
  json(status, { error: { http_code: status, message } });

Deno.serve(async (req) => {
  const body = await req.text();
  let payload: { user: { phone?: string }; sms: { otp: string } };
  try {
    payload = hook.verify(body, Object.fromEntries(req.headers)) as typeof payload;
  } catch {
    return fail(401, "invalid signature");
  }

  const phone = normalizeE164(payload.user.phone ?? "");
  const { data: link } = phone
    ? await db.from("telegram_links").select("chat_id").eq("phone", phone).maybeSingle()
    : { data: null };
  if (!link) return fail(500, "telegram_not_linked");

  // Never log the code (spec FR-014).
  const sent = await sendTelegram(
    link.chat_id,
    `Your Athar code is ${payload.sms.otp}. It expires in 5 minutes. ` +
      "If you didn't ask for it, ignore this message.",
  );
  if (!sent.ok) return fail(500, "telegram_send_failed"); // e.g. user blocked the bot
  return json(200, {});
});
