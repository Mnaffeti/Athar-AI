Running, building and deploying
===============================

Requirements: the Flutter SDK, Node.js (for ``npx supabase``), and Python 3
with Sphinx if you want to build these docs.

Run the app
-----------

.. code-block:: bash

   flutter pub get
   flutter run --dart-define-from-file=env.json              # phone / emulator
   flutter run -d chrome --dart-define-from-file=env.json    # browser (sample data)

``env.json`` holds ``GROQ_API_KEY`` (copy ``env.example.json``). Without it,
the coach uses canned replies and reports use the offline summary.

Build a shareable APK
---------------------

.. code-block:: bash

   flutter build apk --release --dart-define-from-file=env.json
   # → build/app/outputs/flutter-apk/app-release.apk

On Windows, turn on Developer Mode first (``start ms-settings:developers``).
Don't run two Flutter commands at the same time; they overwrite each other's
generated plugin files.

Supabase (already deployed)
---------------------------

.. code-block:: bash

   npx supabase login
   npx supabase link --project-ref ysrusubsulkfemzrlxvx
   npx supabase db push --remote
   npx supabase secrets set --env-file supabase/.env
   npx supabase functions deploy send-sms-telegram    --no-verify-jwt --use-api
   npx supabase functions deploy telegram-webhook     --no-verify-jwt --use-api
   npx supabase functions deploy send-report-telegram --no-verify-jwt --use-api
   export SEND_SMS_HOOK_SECRET=…   # from supabase/.env
   export SMTP_PASS=…              # from supabase/.env.local
   npx supabase config push

Details are in ``supabase/README.md``. Before a demo, make sure the free
project isn't paused (it pauses after 7 idle days), and that **SMS OTP
Expiry** is set to 300 in the dashboard.

Tests
-----

.. code-block:: bash

   flutter analyze
   flutter test

Build these docs
----------------

.. code-block:: bash

   python docs/charts/make_charts.py      # regenerate the charts from the repo
   python -m sphinx -b html docs docs/_build/html
   # open docs/_build/html/index.html
