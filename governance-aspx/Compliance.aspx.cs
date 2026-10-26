using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using ItGovernanceSite.App_Code;

public partial class CompliancePage : System.Web.UI.Page
{
    public int TotalControls { get; set; }
    public double ComplianceRate { get; set; }
    public int NonCompliant { get; set; }
    public int NotAssessed { get; set; }
    public string StatusChartDataJson { get; set; }
    public string FrameworkChartDataJson { get; set; }

    public string ComplianceRateClass
    {
        get { return ComplianceRate >= 90 ? "good" : ComplianceRate >= 70 ? "warn" : "alert"; }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        StatusChartDataJson = "[]";
        FrameworkChartDataJson = "[]";

        var data = DashboardDataProvider.Load();
        Master.ShowStatus(data.IsLive, data.LoadError);

        if (!IsPostBack)
        {
            BindAllSelected(FrameworkFilter, data.Controls.Select(c => c.Framework));
            BindAllSelected(StatusFilter, data.Controls.Select(c => c.Status));
        }

        Render(data.Controls);
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
        Render(DashboardDataProvider.Load().Controls);
    }

    private void Render(List<ControlItem> controls)
    {
        var frameworks = SelectedValues(FrameworkFilter);
        var statuses = SelectedValues(StatusFilter);

        var filtered = controls
            .Where(c => frameworks.Count == 0 || frameworks.Contains(c.Framework ?? ""))
            .Where(c => statuses.Count == 0 || statuses.Contains(c.Status ?? ""))
            .OrderBy(c => c.Framework)
            .ThenBy(c => c.ControlId)
            .ToList();

        ControlsGrid.DataSource = filtered;
        ControlsGrid.DataBind();

        TotalControls = filtered.Count;
        ComplianceRate = GovernanceKpis.ComplianceRate(filtered);
        NonCompliant = GovernanceKpis.NonCompliantCount(filtered);
        NotAssessed = GovernanceKpis.NotAssessedCount(filtered);

        StatusChartDataJson = ChartData.ToJsArray("Status", "Count", GovernanceKpis.ControlsByStatus(filtered));
        FrameworkChartDataJson = ChartData.ToJsArray("Framework", "Count", GovernanceKpis.ControlsByFramework(filtered));
    }

    private static List<string> SelectedValues(ListBox listBox)
    {
        return listBox.Items.Cast<ListItem>().Where(i => i.Selected).Select(i => i.Value).ToList();
    }
}
