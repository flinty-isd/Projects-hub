from streamlit.testing.v1 import AppTest


def test_app_runs_without_exceptions():
    at = AppTest.from_file("../streamlit_app.py").run()
    assert not at.exception


def test_app_renders_title_in_demo_mode():
    # No .streamlit/secrets.toml is present in this environment, so the app
    # should fall back to demo mode rather than raising.
    at = AppTest.from_file("../streamlit_app.py").run()
    assert at.title[0].value == "📊 SharePoint PM Dashboard"
    assert any("Demo mode" in info.value for info in at.info)


def test_kpi_tab_shows_metrics():
    at = AppTest.from_file("../streamlit_app.py").run()
    metric_labels = [m.label for m in at.metric]
    assert "Total tasks" in metric_labels
    assert "Overdue tasks" in metric_labels
    assert "Open risks" in metric_labels
