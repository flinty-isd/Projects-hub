from password_checker import check_password


def failed(result):
    return {c.label for c in result.required + result.pitfalls if not c.passed}


def test_policy_example_is_strong():
    r = check_password('?lACpAs56IKMs"', "jsmith", "John Smith")
    assert r.meets_policy
    assert not failed(r)
    assert r.rating == "Strong"


def test_missing_character_classes():
    r = check_password("abcdefgh")
    assert not r.meets_policy
    labels = failed(r)
    assert any("Uppercase" in l for l in labels)
    assert any("Number" in l for l in labels)
    assert any("Symbol" in l for l in labels)
    assert any("sequences" in l for l in labels)


def test_too_short():
    r = check_password("aB3!x")
    assert not r.required[0].passed
    assert not r.meets_policy


def test_name_is_rejected_including_leet_and_backwards():
    for pw in ("Smith#2k9Q", "5m1th#2k9Q", "htimS#2k9Q"):
        r = check_password(pw, full_name="John Smith")
        assert not r.meets_policy, pw
    r = check_password("Jsmith!9xQ", account_name="jsmith@corp.com")
    assert not r.meets_policy


def test_pitfalls():
    assert failed(check_password("P@ssw0rd!9"))  # dictionary word, leet
    assert failed(check_password("Qx!7drowssap"))  # backwards
    assert failed(check_password("Zz!9aaa7Kq"))  # repeats
    assert failed(check_password("Zx!9Qwerty"))  # keyboard sequence
    assert failed(check_password("Zx!9Kq1987"))  # year
    assert failed(check_password("Zx!9Kq-Rex7", personal_info="Rex"))


def test_empty():
    r = check_password("")
    assert r.score == 0 and not r.meets_policy


def test_pitfall_caps_rating_at_weak():
    r = check_password("P@ssw0rd123")
    assert r.meets_policy
    assert r.rating == "Weak"
    assert any("123" in c.detail for c in r.pitfalls)
