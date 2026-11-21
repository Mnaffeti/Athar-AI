import { assertEquals } from "jsr:@std/assert@1";
import { isOwnContact, normalizeE164 } from "./phone.ts";

Deno.test("normalizeE164", () => {
  assertEquals(normalizeE164("+216 50-123-456"), "+21650123456");
  assertEquals(normalizeE164("21650123456"), "+21650123456"); // Telegram style
  assertEquals(normalizeE164("0021650123456"), "+21650123456");
  assertEquals(normalizeE164("12345"), null);
  assertEquals(normalizeE164(""), null);
});

Deno.test("isOwnContact", () => {
  const contact = { user_id: 7, phone_number: "21650123456" };
  assertEquals(isOwnContact({ from: { id: 7 }, contact }), true);
  assertEquals(isOwnContact({ from: { id: 8 }, contact }), false);
  assertEquals(
    isOwnContact({ from: { id: 7 }, contact: { phone_number: "1" } }),
    false,
  );
  assertEquals(isOwnContact({ from: { id: 7 } }), false);
});
