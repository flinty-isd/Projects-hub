# 🔒 Password Checker

A Streamlit app that checks a password against the IT Security Password Policy.

**Required:** at least 8 characters; uppercase, lowercase, a number and a symbol;
must not contain your account or full name.

**Pitfalls flagged:** dictionary words (including backwards or l33t spellings),
sequences (`123`, `abcd`, `qwerty`), repeated characters (`222`), and personal
information (years, dates, anything you enter in the optional field).

The rules against reusing any of your last 24 passwords and the 90-day expiry are
enforced by the account system, not by this app.

Passwords are checked in memory only. They are never stored or logged.

## Run it

```
$ pip install -r requirements.txt
$ streamlit run streamlit_app.py
```

## Test it

```
$ pip install pytest
$ python -m pytest tests
```
