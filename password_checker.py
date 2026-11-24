"""Password checks based on the IT Security Password Policy.

Required rules (all must pass):
  * At least 8 characters
  * Contains an uppercase letter, a lowercase letter, a number and a symbol
  * Does not contain the account name or full name

Pitfalls (should be avoided; they lower the strength score):
  * Dictionary words, including backwards, abbreviated or "leet" spellings
  * Sequences or repeated characters (12345678, 222222, abcdefg, qwerty)
  * Personal information (name, birthday, ID numbers)

The "not used in the previous 24 passwords" and "expires after 90 days"
rules are enforced by the account system and cannot be checked here.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field

MIN_LENGTH = 8
STRONG_LENGTH = 12
MIN_TOKEN_LENGTH = 3  # shortest name/word fragment treated as a match

SYMBOL_EXAMPLES = "! % * & #"

# Common words and passwords. Kept deliberately short and high-signal; real
# attackers use far larger lists, so any match here is a clear warning sign.
COMMON_WORDS = frozenset(
    """
    password passwort passe contrasena parola wachtwoord senha
    admin administrator root user login welcome letmein access master
    secret private default guest test temp changeme
    qwerty azerty qwertz asdf zxcv
    love lover iloveyou hello hi monkey dragon shadow sunshine princess
    football soccer baseball basketball hockey cricket rugby golf tennis
    superman batman starwars pokemon matrix
    summer winter spring autumn fall
    january february march april june july august september october
    november december monday tuesday wednesday thursday friday saturday sunday
    freedom trustno1 whatever nothing ninja mustang harley ranger buster
    tigger charlie jordan michael jennifer thomas daniel robert
    computer internet security company office work port ship dock cargo
    container harbour harbor felixstowe england london britain
    cheese coffee chocolate pepper orange banana apple cookie
    flower angel baby family friend forever happy money power
    """.split()
)

LEET_MAP = str.maketrans(
    {"0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t", "8": "b",
     "9": "g", "@": "a", "$": "s", "!": "i", "|": "i", "+": "t"}
)

KEYBOARD_ROWS = (
    "`1234567890-=",
    "qwertyuiop[]\\",
    "asdfghjkl;'",
    "zxcvbnm,./",
)
SEQUENCE_SOURCES = (
    "abcdefghijklmnopqrstuvwxyz",
    "0123456789",
    *KEYBOARD_ROWS,
)
MIN_SEQUENCE = 4  # e.g. "abcd", "qwer"
MIN_DIGIT_SEQUENCE = 3  # e.g. "123", "987"
MIN_REPEAT = 3  # e.g. "222", "aaa"

DATE_PATTERN = re.compile(r"(19|20)\d{2}|\d{1,2}[/.\-]\d{1,2}[/.\-]\d{2,4}")


@dataclass
class Check:
    label: str
    passed: bool
    detail: str = ""


@dataclass
class Result:
    required: list[Check] = field(default_factory=list)
    pitfalls: list[Check] = field(default_factory=list)
    score: int = 0  # 0-100

    @property
    def meets_policy(self) -> bool:
        return all(c.passed for c in self.required)

    @property
    def rating(self) -> str:
        if not self.meets_policy:
            return "Does not meet policy"
        if not all(c.passed for c in self.pitfalls):
            return "Weak"
        if self.score >= 80:
            return "Strong"
        if self.score >= 60:
            return "Good"
        return "Weak"


def _tokens(*values: str) -> set[str]:
    """Split names/personal info into lowercase fragments worth matching."""
    found: set[str] = set()
    for value in values:
        if not value:
            continue
        cleaned = value.strip().lower()
        # The account name may look like "jsmith" or "john.smith@corp.com".
        cleaned = cleaned.split("@")[0]
        joined = re.sub(r"[^a-z0-9]", "", cleaned)
        if len(joined) >= MIN_TOKEN_LENGTH:
            found.add(joined)
        for part in re.split(r"[^a-z0-9]+", cleaned):
            if len(part) >= MIN_TOKEN_LENGTH:
                found.add(part)
    return found


def _variants(password: str) -> set[str]:
    """Lowercase, de-leeted and reversed forms of the password."""
    lower = password.lower()
    unleet = lower.translate(LEET_MAP)
    return {lower, unleet, lower[::-1], unleet[::-1]}


def _find_sequences(password: str) -> list[str]:
    lower = password.lower()
    hits: list[str] = []
    for source in SEQUENCE_SOURCES:
        size = MIN_DIGIT_SEQUENCE if source.isdigit() else MIN_SEQUENCE
        for direction in (source, source[::-1]):
            for i in range(len(direction) - size + 1):
                run = direction[i : i + size]
                if run in lower and run not in hits:
                    hits.append(run)
    return hits


def _find_repeats(password: str) -> list[str]:
    return [m.group(0) for m in re.finditer(rf"(.)\1{{{MIN_REPEAT - 1},}}", password)]


def _find_words(password: str) -> list[str]:
    variants = _variants(password)
    hits = {w for w in COMMON_WORDS if len(w) >= 4 and any(w in v for v in variants)}
    # Report the longest matches first and drop words contained in another hit.
    ordered = sorted(hits, key=len, reverse=True)
    return [w for w in ordered if not any(w != o and w in o for o in ordered)]


def check_password(
    password: str,
    account_name: str = "",
    full_name: str = "",
    personal_info: str = "",
) -> Result:
    result = Result()
    pw = password or ""

    result.required = [
        Check(
            f"At least {MIN_LENGTH} characters",
            len(pw) >= MIN_LENGTH,
            f"{len(pw)} characters",
        ),
        Check("Uppercase letter (A-Z)", bool(re.search(r"[A-Z]", pw))),
        Check("Lowercase letter (a-z)", bool(re.search(r"[a-z]", pw))),
        Check("Number (0-9)", bool(re.search(r"[0-9]", pw))),
        Check(
            f"Symbol ({SYMBOL_EXAMPLES} ...)",
            bool(re.search(r"[^A-Za-z0-9]", pw)),
        ),
    ]

    variants = _variants(pw)
    name_hits = sorted(
        t for t in _tokens(account_name, full_name) if any(t in v for v in variants)
    )
    result.required.append(
        Check(
            "Does not contain your account or full name",
            not name_hits,
            ("Contains: " + ", ".join(name_hits)) if name_hits else "",
        )
    )

    words = _find_words(pw)
    sequences = _find_sequences(pw)
    repeats = _find_repeats(pw)
    personal_hits = sorted(
        t for t in _tokens(personal_info) if any(t in v for v in variants)
    )
    dates = [m.group(0) for m in DATE_PATTERN.finditer(pw)]

    result.pitfalls = [
        Check(
            "No dictionary words (incl. backwards or l33t spellings)",
            not words,
            ("Found: " + ", ".join(words)) if words else "",
        ),
        Check(
            "No sequences (123, abcd, qwerty)",
            not sequences,
            ("Found: " + ", ".join(sequences)) if sequences else "",
        ),
        Check(
            "No repeated characters (222, aaa)",
            not repeats,
            ("Found: " + ", ".join(repeats)) if repeats else "",
        ),
        Check(
            "No personal information (birthdays, years, ID numbers)",
            not personal_hits and not dates,
            ("Found: " + ", ".join(personal_hits + dates))
            if (personal_hits or dates)
            else "",
        ),
    ]

    result.score = _score(pw, result)
    return result


def _score(pw: str, result: Result) -> int:
    if not pw:
        return 0
    # Length: up to 50 points, full marks at 16+ characters.
    score = min(len(pw), 16) / 16 * 50
    # Variety: up to 30 points across the four character classes.
    classes = sum(c.passed for c in result.required[1:5])
    score += classes / 4 * 30
    # Mix: up to 20 points for how many distinct characters are used.
    score += min(len(set(pw)) / max(len(pw), 1), 1) * 20
    # Each pitfall and a name match are heavy penalties.
    score -= 20 * sum(not c.passed for c in result.pitfalls)
    if not result.required[5].passed:
        score -= 30
    if not result.meets_policy:
        score = min(score, 39)
    return max(0, min(100, round(score)))
