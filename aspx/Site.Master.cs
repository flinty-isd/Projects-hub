using System;
using System.IO;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class SiteMaster : MasterPage
{
    protected void Page_Load(object sender, EventArgs e)
    {
        var currentPage = Path.GetFileName(Request.Path);
        HighlightTab(TabOverview, currentPage, "Default.aspx");
        HighlightTab(TabTimeline, currentPage, "Timeline.aspx");
        HighlightTab(TabKpis, currentPage, "Kpis.aspx");
        HighlightTab(TabRisks, currentPage, "Risks.aspx");
    }

    private static void HighlightTab(HyperLink tab, string currentPage, string matchPage)
    {
        tab.CssClass = string.Equals(currentPage, matchPage, StringComparison.OrdinalIgnoreCase)
            ? "tab active"
            : "tab";
    }

    public void ShowStatus(bool isLive, string loadError)
    {
        if (!string.IsNullOrEmpty(loadError))
        {
            StatusBanner.CssClass = "banner banner-warning";
            StatusMessage.Text = "Couldn't load live SharePoint data, showing demo data instead: "
                + System.Web.HttpUtility.HtmlEncode(loadError);
        }
        else if (!isLive)
        {
            StatusBanner.CssClass = "banner banner-info";
            StatusMessage.Text = "Demo mode &mdash; showing sample data. Add SharePoint credentials to "
                + "Web.config to connect a live site.";
        }
        else
        {
            StatusBanner.CssClass = "banner banner-success";
            StatusMessage.Text = "Connected to live SharePoint data.";
        }
    }
}
