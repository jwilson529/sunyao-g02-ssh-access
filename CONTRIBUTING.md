# Contributing

Keep the main guide usable by someone who has never opened a terminal. Prefer visible success/error messages and exact filenames over jargon.

Run `python3 tests/test_access.py` before sending changes. Test key validation, repeated setup, preservation of unrelated keys, and removal. Keep all credentials and real device reports out of commits. Document hardware evidence separately from simulated tests.

Firmware updates and flashing are outside this package's scope. Device support changes should include an anonymized diagnostic and an explanation of any changed assumptions.
