from streamlit.testing.v1 import AppTest


def test_app_runs_without_exceptions():
    at = AppTest.from_file("../streamlit_app.py").run()
    assert not at.exception


def test_app_renders_title():
    at = AppTest.from_file("../streamlit_app.py").run()
    assert at.title[0].value == "🎈 My new app"
