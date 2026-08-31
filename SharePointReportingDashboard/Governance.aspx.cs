using System;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using SharePointReportingDashboard.Services;

namespace SharePointReportingDashboard
{
    public partial class GovernancePage : Page
    {
        protected Literal snapshotDateLiteral;
        protected Literal snapshotSitesLiteral;
        protected Literal snapshotRemainingLiteral;
        protected Literal snapshotRagLiteral;
        protected Literal snapshotRisksLiteral;
        protected Literal snapshotOverdueLiteral;
        protected Literal snapshotPagesLiteral;
        protected Literal snapshotCommentaryLiteral;
        protected GridView raidGrid;
        protected GridView overdueActionsGrid;
        protected GridView pendingDecisionsGrid;
        protected GridView scopeChangesGrid;
        protected GridView snapshotHistoryGrid;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack)
            {
                return;
            }

            var service = DataServiceFactory.GetService();
            var snapshot = service.GetLatestSnapshot();
            var raid = service.GetRaidItems();
            var actions = service.GetActions();
            var decisions = service.GetDecisions();
            var pages = service.GetPageDeliveryItems();

            snapshotDateLiteral.Text = snapshot.SnapshotDate.ToString("yyyy-MM-dd");
            snapshotSitesLiteral.Text = snapshot.SitesComplete.ToString();
            snapshotRemainingLiteral.Text = snapshot.RemainingSites.ToString();
            snapshotRagLiteral.Text = GetRagBadge(snapshot.OverallRag);
            snapshotRisksLiteral.Text = snapshot.OpenRisks.ToString();
            snapshotOverdueLiteral.Text = snapshot.OverdueActions.ToString();
            snapshotPagesLiteral.Text = snapshot.PagesOutstanding.ToString();
            snapshotCommentaryLiteral.Text = snapshot.Commentary;

            raidGrid.DataSource = raid.Where(r => r.Rag == "Red" || r.Rag == "Amber").ToList();
            raidGrid.DataBind();

            overdueActionsGrid.DataSource = actions.Where(a => a.IsOverdue).ToList();
            overdueActionsGrid.DataBind();

            pendingDecisionsGrid.DataSource = decisions.Where(d => d.Status == "Pending").ToList();
            pendingDecisionsGrid.DataBind();

            scopeChangesGrid.DataSource = pages.Where(p => p.ScopeClassification == "Scope Change").ToList();
            scopeChangesGrid.DataBind();

            snapshotHistoryGrid.DataSource = service.GetSnapshotHistory();
            snapshotHistoryGrid.DataBind();
        }

        protected string GetRagBadge(string rag)
        {
            var cssClass = rag == "Red" ? "rag-red" : rag == "Amber" ? "rag-amber" : rag == "Green" ? "rag-green" : "rag-grey";
            return "<span class=\"rag-badge " + cssClass + "\">" + (rag ?? "Unknown") + "</span>";
        }
    }
}
