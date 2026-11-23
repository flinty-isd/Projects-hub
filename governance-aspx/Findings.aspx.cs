using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using ItGovernanceSite.App_Code;

public partial class FindingsPage : System.Web.UI.Page
{
    private static readonly string[] SeverityOrder = { "Critical", "High", "Medium", "Low" };

    public int OpenFindings { get; set; }
    public int OpenHighSeverity { get; set; }
    public int OverdueFindings { get; set; }
    public string SeverityChartDataJson { get; set; }

    protected void Page_Load(object sender, EventArgs e)
    {
        SeverityChartDataJson = "[]";

        var data = DashboardDataProvider.Load();
        Master.ShowStatus(data.IsLive, data.LoadError);

        if (!IsPostBack)
        {
            BindAllSelected(SeverityFilter, data.Findings.Select(f => f.Severity));
            BindAllSelected(StatusFilter, data.Findings.Select(f => f.Status));
            BindAllSelected(SourceFilter, data.Findings.Select(f => f.Source));
        }

        Render(data.Findings);
    }

    private static void BindAllSelected(ListBox listBox, IEnumerable<string> values)
    {
        listBox.DataSource = values.Distinct().OrderBy(v => v).ToList();
        listBox.DataBind();
        foreach (ListItem item in listBox.Items)
        {
            item.Selected = true;
        }
    }

    protected void Filter_Changed(object sender, EventArgs e)
    {
        Render(DashboardDataProvider.Load().Findings);
    }

    private void Render(List<FindingItem> findings)
    {
        var severities = SelectedValues(SeverityFilter);
        var statuses = SelectedValues(StatusFilter);
        var sources = SelectedValues(SourceFilter);

        var filtered = findings
            .Where(f => severities.Count == 0 || severities.Contains(f.Severity ?? ""))
            .Where(f => statuses.Count == 0 || statuses.Contains(f.Status ?? ""))
            .Where(f => sources.Count == 0 || sources.Contains(f.Source ?? ""))
            .OrderBy(f => SeverityRank(f.Severity))
            .ThenBy(f => f.DueDate ?? DateTime.MaxValue)
            .ToList();

        FindingsGrid.DataSource = filtered;
        FindingsGrid.DataBind();

        var today = DateTime.Today;
        OpenFindings = GovernanceKpis.OpenFindingCount(filtered);
        OpenHighSeverity = GovernanceKpis.OpenHighSeverityCount(filtered);
        OverdueFindings = GovernanceKpis.OverdueFindingCount(filtered, today);

        // Keep severity buckets in Critical -> Low order rather than by count.
        var bySeverity = GovernanceKpis.FindingsBySeverity(filtered)
            .OrderBy(kv => SeverityRank(kv.Key))
            .ToList();
        SeverityChartDataJson = ChartData.ToJsArray("Severity", "Count", bySeverity);
    }

    protected void FindingsGrid_RowDataBound(object sender, GridViewRowEventArgs e)
    {
        if (e.Row.RowType != DataControlRowType.DataRow)
        {
            return;
        }
        var finding = e.Row.DataItem as FindingItem;
        if (finding == null)
        {
            return;
        }
        if (GovernanceKpis.IsFindingOpen(finding) && finding.DueDate.HasValue && finding.DueDate.Value < DateTime.Today)
        {
            e.Row.Style["background-color"] = "#fef2f2";
            e.Row.Style["color"] = "#b91c1c";
        }
    }

    private static int SeverityRank(string severity)
    {
        var index = Array.FindIndex(SeverityOrder,
            s => string.Equals(s, severity, StringComparison.OrdinalIgnoreCase));
        return index < 0 ? SeverityOrder.Length : index;
    }

    private static List<string> SelectedValues(ListBox listBox)
    {
        return listBox.Items.Cast<ListItem>().Where(i => i.Selected).Select(i => i.Value).ToList();
    }
}
