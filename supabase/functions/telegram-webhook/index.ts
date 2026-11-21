// Telegram bot updates: links a user's own phone number to their chat.
// Contract: specs/001-otp-auth/contracts/telegram-webhook.md
import { isOwnContact, normalizeE164 } from "../_shared/phone.ts";
import { db, sendTelegram } from "../_shared/telegram.ts";

const secret = Deno.env.get("TELEGRAM_WEBHOOK_SECRET")!;

const shareKeyboard = {
  keyboard: [[{ text: "Share my number", request_contact: true }]],
  one_time_keyboard: true,
  resize_keyboard: true,
};

Deno.serve(async (req) => {
  if (req.headers.get("x-telegram-bot-api-secret-token") !== secret) {
    return new Response("unauthorized", { status: 401 });
  }
  const msg = (await req.json()).message;
  // Ignore anything but private chats; always 200 so Telegram doesn't retry.
  if (!msg?.chat || msg.chat.type !== "private") return new Response("ok");

  if (!msg.contact) {
    // Typed numbers can't be trusted; only Telegram's contact share proves ownership.
    const typedNumber = /^\+?[\d\s\-().]{6,}$/.test(msg.text ?? "");
    await sendTelegram(
      msg.chat.id,
      (typedNumber
        ? "Typing the number doesn't work: Telegram has to confirm it's yours.\n\n"
        : "Share your phone number to get Athar sign-in codes here.\n\n") +
        'Tap the "Share my number" button below. On desktop or web, click the ' +
        "keyboard icon next to the message box to show it.",
      shareKeyboard,
    );
    return new Response("ok");
  }

  const phone = normalizeE164(msg.contact.phone_number);
  if (!isOwnContact(msg) || !phone) {
    await sendTelegram(
      msg.chat.id,
      "Please share your own number with the button below.",
      shareKeyboard,
    );
    return new Response("ok");
  }

  const { error } = await db.from("telegram_links").upsert({
    phone,
    chat_id: msg.chat.id,
    telegram_user_id: msg.from.id,
    linked_at: new Date().toISOString(),
  });
  await sendTelegram(
    msg.chat.id,
    error
      ? "Something went wrong. Please share your number again."
      : `Linked ${phone}. Go back to Athar and tap "Send code again".`,
    error ? shareKeyboard : { remove_keyboard: true },
  );
  return new Response("ok");
});
