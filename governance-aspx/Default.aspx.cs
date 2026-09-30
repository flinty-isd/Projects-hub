using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using ItGovernanceSite.App_Code;

public partial class PoliciesPage : System.Web.UI.Page
{
    public int TotalPolicies { get; set; }
    public double CurrencyRate { get; set; }
    public int DueForReview { get; set; }
    public string StatusChartDataJson { get; set; }

    public string CurrencyRateClass
    {
        get { return CurrencyRate >= 90 ? "good" : CurrencyRate >= 70 ? "warn" : "alert"; }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        StatusChartDataJson = "[]";

        var data = DashboardDataProvider.Load();
        Master.ShowStatus(data.IsLive, data.LoadError);

        if (!IsPostBack)
        {
            PopulateFilters(data.Policies);
        }

        Render(data.Policies);
    }

    private void PopulateFilters(List<PolicyItem> policies)
    {
        BindAllSelected(StatusFilter, policies.Select(p => p.Status));
        BindAllSelected(CategoryFilter, policies.Select(p => p.Category));
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
        Render(DashboardDataProvider.Load().Policies);
    }

    private void Render(List<PolicyItem> policies)
    {
        var statuses = SelectedValues(StatusFilter);
        var categories = SelectedValues(CategoryFilter);

        var filtered = policies
            .Where(p => statuses.Count == 0 || statuses.Contains(p.Status ?? ""))
            .Where(p => categories.Count == 0 || categories.Contains(p.Category ?? ""))
            .OrderBy(p => p.Category)
            .ThenBy(p => p.Title)
            .ToList();

        PoliciesGrid.DataSource = filtered;
        PoliciesGrid.DataBind();

        var today = DateTime.Today;
        TotalPolicies = filtered.Count;
        CurrencyRate = GovernanceKpis.PolicyCurrencyRate(filtered, today);
        DueForReview = GovernanceKpis.PoliciesDueForReview(filtered, today);

        StatusChartDataJson = ChartData.ToJsArray("Status", "Count", GovernanceKpis.PoliciesByStatus(filtered));
    }

    private static List<string> SelectedValues(ListBox listBox)
    {
        return listBox.Items.Cast<ListItem>().Where(i => i.Selected).Select(i => i.Value).ToList();
    }
}
