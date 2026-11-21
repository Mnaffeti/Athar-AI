How the Superpowers plugin helped
=================================

`Superpowers <https://github.com/obra/superpowers>`_ is a Claude Code plugin
that gives the coding agent a library of **process skills**. These are
written methods for brainstorming, planning, test-driven development,
systematic debugging, verifying before claiming success, and code review. It
was active for the whole project and loaded at the start of each session.

**How it fit with Spec Kit.** Spec Kit drove the feature workflow: specify,
plan, tasks, implement. Superpowers shaped *how* each step was carried out.
Most of its skills weren't called by name; what showed up was their
practices. The examples below are real moments from building Athar.

Verification before completion
------------------------------

*Rule: don't call something done until you've seen the evidence.*

* Every implementation step ended with ``flutter analyze`` and
  ``flutter test`` (22 tests passing at the end), and the results were
  reported as they were, failures included.
* After pushing the Supabase config, ``supabase config diff`` was used to
  confirm that no auth settings were still out of sync.
* Each deployed function was checked with ``curl``: requests without the
  secret were rejected (401), and the report function rejected callers who
  weren't signed in (401).
* ``getWebhookInfo`` confirmed that Telegram was reaching the webhook with no
  errors.
* Facts the plan depended on (Supabase free-plan features, hook payloads,
  session limits) were checked against the official docs before planning,
  instead of being trusted from memory.

Systematic debugging
--------------------

*Rule: find the root cause before fixing anything, then fix it once in the
shared code.*

* **"No connection" on Telegram send:**

  - Symptom: the app said "No connection" although the network was fine.
  - Root cause: the gotrue client (``fetch.dart:49``) raises its "retryable
    fetch" error for any status of 500 or above, so the hook's "not linked"
    500 looked like being offline.
  - Fix: one change in ``AuthService`` (offline only when there's no status
    code), plus a regression test.

* **Failing widget test:** it was traced to an earlier home-header redesign,
  commit ``891f778``, which put the name into rich text. The test was fixed;
  the app code was fine.
* **Release build failures:**

  - The first failure was the Android Gradle Plugin version, which the Flutter
    SDK requires to be 9.1.1 or newer. The fix was taken from a freshly
    generated Flutter template rather than guessed.
  - A later failure came from two Flutter commands running at once. It was
    diagnosed and rerun, with no code change.

Test-driven checks on pure logic
--------------------------------

*Rule: tests should check the behaviour, and a failing test should be
questioned honestly, whether the code is wrong or the test is.*

* The report math was written as a pure Dart file so it could be unit
  tested in isolation.
* One test expected the forecast floor (0) to be reached. Working through
  the maths showed that with 7 days of non-negative data the floor can never
  be reached, so the **test** was corrected rather than the code bent to
  fit.
* Validation of the LLM's reply (unknown apps dropped, wrong shapes
  rejected) is tested without calling the network.

Brainstorming and planning discipline
-------------------------------------

*Rule: settle the open questions before building.*

* At most three focused questions per feature, each with clear options and
  their consequences. For example, real vs mocked delivery, and whether to
  include a weekly scheduled report.
* Recommendations rather than surveys of options. For example, Supabase over
  Firebase (which needs a paid plan) or Cloudflare (where the session logic
  would have to be written by hand).

Safety around irreversible actions
----------------------------------

* Changes to the live Supabase project (secrets, deploys, config pushes) and
  to Telegram were confirmed with the project owner before running.
* When GitHub push protection flagged the Brevo key, the unpushed commits
  were rewritten to remove it. The key now lives in a gitignored file, and
  email delivery kept working.

Summary
-------

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Practice
     - Effect on Athar
   * - Verify before done
     - Every "it works" is backed by a test, a config diff or a live check
   * - Systematic debugging
     - Three real bugs fixed at their root, each with a guard
   * - Test the pure logic
     - Report numbers you can trust, and a wrong test caught
   * - Clarify first
     - Scope settled before coding, so little rework
   * - Confirm risky actions
     - No surprise changes to production or leaked keys
