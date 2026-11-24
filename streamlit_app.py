import streamlit as st

from password_checker import MIN_LENGTH, check_password

st.set_page_config(page_title="Password Checker", page_icon="🔒")

st.title("🔒 Password Checker")
st.write(
    "Check a password against the IT Security Password Policy. "
    "Your password is only checked in this session. It is not saved or sent anywhere else."
)

password = st.text_input("Password", type="password")

with st.expander("Optional: check for your name and personal information"):
    account_name = st.text_input("Account name", placeholder="e.g. jsmith")
    full_name = st.text_input("Full name", placeholder="e.g. John Smith")
    personal_info = st.text_input(
        "Other personal information",
        placeholder="e.g. birthday, pet's name, licence or passport number",
        help="Separate items with spaces or commas.",
    )

if not password:
    st.info(
        f"Enter a password to check it. Passwords need at least {MIN_LENGTH} characters "
        "and must include uppercase and lowercase letters, a number and a symbol."
    )
    st.stop()

result = check_password(password, account_name, full_name, personal_info)

if result.rating == "Strong":
    st.success(f"**{result.rating}**: meets the password policy.")
elif result.meets_policy:
    st.warning(f"**{result.rating}**: meets the policy, but it could be stronger.")
else:
    st.error(f"**{result.rating}**. Fix the items marked ❌ below.")
st.progress(result.score, text=f"Strength score: {result.score}/100")


def show(checks):
    for c in checks:
        icon = "✅" if c.passed else "❌"
        line = f"{icon} {c.label}"
        if c.detail and not c.passed:
            line += f" ({c.detail})"
        st.markdown(line)


col1, col2 = st.columns(2)
with col1:
    st.subheader("Must have")
    show(result.required)
with col2:
    st.subheader("Avoid")
    show(result.pitfalls)

st.caption(
    "Also remember that you can't reuse any of your previous 24 passwords, and "
    "passwords expire after 90 days. This tool can't check those rules."
)

with st.expander("Tip: create a strong password you can remember"):
    st.markdown(
        """
1. **Start with a sentence or two** (about 10 words): *Long and complex passwords are safest. I keep mine secret.*
2. **Use the first letter of each word:** `lacpasikms`
3. **Uppercase only the letters from the first half of the alphabet:** `lACpAsIKMs`
4. **Put two meaningful numbers between the sentences:** `lACpAs56IKMs`
5. **Put a punctuation mark at the beginning:** `?lACpAs56IKMs`
6. **Put a symbol at the end:** `?lACpAs56IKMs"`

It's okay to write passwords down, but keep them somewhere secure.
"""
    )
