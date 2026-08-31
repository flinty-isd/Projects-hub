using System;
using System.IO;
using System.Web.UI.HtmlControls;

namespace SharePointReportingDashboard
{
    public partial class SiteMaster : System.Web.UI.MasterPage
    {
        protected HtmlAnchor navOverview;
        protected HtmlAnchor navMigration;
        protected HtmlAnchor navPages;
        protected HtmlAnchor navGovernance;
        protected HtmlGenericControl footerTimestamp;

        protected void Page_Load(object sender, EventArgs e)
        {
            var currentPage = Path.GetFileName(Request.AppRelativeCurrentExecutionFilePath ?? string.Empty);

            HighlightIfCurrent(navOverview, currentPage, "Default.aspx");
            HighlightIfCurrent(navMigration, currentPage, "Migration.aspx");
            HighlightIfCurrent(navPages, currentPage, "Pages.aspx");
            HighlightIfCurrent(navGovernance, currentPage, "Governance.aspx");

            footerTimestamp.InnerText = "Last refreshed: " + DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm") + " UTC";
        }

        private static void HighlightIfCurrent(HtmlAnchor anchor, string currentPage, string pageName)
        {
            if (string.Equals(currentPage, pageName, StringComparison.OrdinalIgnoreCase))
            {
                anchor.Attributes["class"] = "active";
            }
        }
    }
}
