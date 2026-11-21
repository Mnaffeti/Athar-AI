/** E.164 (`+21650123456`) or null. Telegram contacts and Supabase may omit the `+`. */
export function normalizeE164(input: string): string | null {
  let s = input.replace(/[\s\-.()]/g, "");
  if (s.startsWith("00")) s = "+" + s.slice(2);
  else if (!s.startsWith("+")) s = "+" + s;
  return /^\+[1-9]\d{6,14}$/.test(s) ? s : null;
}

type ContactMessage = {
  from?: { id: number };
  contact?: { user_id?: number; phone_number: string };
};

/** True only when the sender shared their own Telegram contact. */
export function isOwnContact(message: ContactMessage): boolean {
  const owner = message.contact?.user_id;
  return owner !== undefined && owner === message.from?.id;
}
