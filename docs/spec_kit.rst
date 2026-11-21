How we used Spec Kit
====================

`Spec Kit <https://github.com/github/spec-kit>`_ is an open-source toolkit
for **spec-driven development**. Each feature is first described (what and
why), then planned (how), broken into tasks, and only then coded. We
installed it with ``specify init --here --integration claude``, which adds
the ``.specify/`` folder and the ``/speckit-*`` skills in ``.claude/skills/``.

The workflow, step by step
--------------------------

.. list-table::
   :header-rows: 1
   :widths: 22 38 40

   * - Step (skill)
     - What it produced
     - Example from this project
   * - ``/speckit-specify``
     - ``spec.md``: user stories with priorities, functional requirements
       (``FR-xxx``), success criteria (``SC-xxx``), edge cases and
       assumptions. It stays free of technology choices.
     - 001: 3 stories (email P1, Telegram P2, session P3) and FR-001 to
       FR-019.
   * - Clarification questions
     - At most 3 ``[NEEDS CLARIFICATION]`` questions, answered and recorded
       under **Clarifications** in the spec.
     - 001: separate accounts per email or phone, remove Apple/Google, real
       delivery. 002: Telegram only for Telegram accounts, no weekly job.
   * - ``checklists/requirements.md``
     - A quality gate on the spec (testable, measurable, no implementation
       details).
     - Both specs pass 16 of 16.
   * - ``/speckit-plan``
     - ``plan.md`` (tech context, structure), ``research.md`` (decisions,
       with the alternatives considered), ``data-model.md``, ``contracts/``
       and ``quickstart.md``.
     - 001: Supabase, Brevo and a Telegram hook. 002: numbers computed in
       code, words from Groq.
   * - ``/speckit-tasks``
     - ``tasks.md``: tasks ordered by dependency and grouped by user story,
       with ``[P]`` for tasks that can run in parallel.
     - 001: 26 tasks. 002: 18 tasks.
   * - ``/speckit-implement``
     - The code, with each task ticked off in ``tasks.md``.
     - See :doc:`tasks`.

How the specs show up in the code
---------------------------------

**1. Requirement IDs in comments.** Code that enforces a requirement cites
it, so a reviewer can trace code back to the spec. IDs are per feature (001
and 002 each start at FR-001).

.. list-table::
   :header-rows: 1
   :widths: 14 46 40

   * - ID
     - Requirement
     - Where it's enforced
   * - 001 FR-012
     - Clear error messages that don't reveal whether an account exists
     - ``AuthService.errorMessage``
   * - 001 FR-014
     - Codes are never logged
     - ``send-sms-telegram/index.ts``
   * - 002 FR-005d
     - Suggestions tied to the onboarding goal
     - ``StatsScreen.goal``, passed to the report
   * - 002 FR-006
     - Only real apps, and predictions with ranges
     - ``BehaviourReportService.validate``
   * - 002 FR-007
     - An offline fallback
     - ``offlineReport`` in ``usage_insights.dart``
   * - 002 FR-009
     - One report per hour
     - ``BehaviourReportService.cooldownLeft``
   * - 002 FR-010 / FR-013
     - Telegram only for Telegram accounts
     - ``canSendToTelegram`` and ``send-report-telegram``
   * - 002 FR-012
     - Only aggregates go to the AI
     - ``BehaviourReportService._askGroq``

**2. Contracts as the source of truth for interfaces.** Each server function
and channel starts with a comment pointing to its contract, for example
``// Contract: specs/001-otp-auth/contracts/send-sms-telegram.md``. Status
codes, bodies and error names in the code match the contract tables.

**3. Research decisions turned into structure.** For example, 002's R3,
"numbers in code, words from the LLM", is why ``usage_insights.dart`` is a
separate, pure Dart file with its own tests.

**4. Quickstart scenarios as the acceptance test.** ``quickstart.md`` lists
numbered scenarios that map to the user stories and the success criteria.
They're the manual checks run on a device.

**5. Changes flow back into the spec.** When reality forced a change, the
spec or contract was updated rather than left out of date. For example:

* Supabase's free plan has no per-code attempt counter, so FR-006 was
  amended.
* The report function verifies the caller itself, so its contract was
  updated.

What Spec Kit gave us
---------------------

* **Fewer surprises.** The questions were answered before any code was
  written. For example, the Telegram first-time bot step came out of
  planning, not out of a bug.
* **Reviewable decisions.** Each choice is in ``research.md`` with the
  alternatives that were rejected.
* **Traceability.** From a user story, to its FR, to the task, to the code
  comment, to the quickstart scenario.
* **Incremental delivery.** The MVP (email sign-in, real charts) shipped
  first, and later stories built on it.
