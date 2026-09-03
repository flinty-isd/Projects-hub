using System;
using System.Linq;
using System.Web.UI.WebControls;
using SharePointPmDashboard.App_Code;

public partial class _Default : System.Web.UI.Page
{
    public string StatusChartDataJson { get; set; }

    protected void Page_Load(object sender, EventArgs e)
    {
        StatusChartDataJson = "[['Status','Count']]";

        var data = DashboardDataProvider.Load();
        ((SiteMaster)Master).ShowStatus(data.IsLive, data.LoadError);

        if (!IsPostBack)
        {
            PopulateFilterOptions(data);
        }

        BindGrid(data);
    }

    private void PopulateFilterOptions(DashboardData data)
    {
        var statuses = data.Tasks.Select(t => t.Status).Distinct().OrderBy(s => s).ToList();
        StatusFilter.DataSource = statuses;
        StatusFilter.DataBind();
        foreach (ListItem item in StatusFilter.Items)
        {
            item.Selected = true;
        }

        var owners = data.Tasks.Select(t => t.AssignedTo).Distinct().OrderBy(o => o).ToList();
        OwnerFilter.DataSource = owners;
        OwnerFilter.DataBind();
        foreach (ListItem item in OwnerFilter.Items)
        {
            item.Selected = true;
        }
    }

    protected void Filter_Changed(object sender, EventArgs e)
    {
        BindGrid(DashboardDataProvider.Load());
    }

    private void BindGrid(DashboardData data)
    {
        var selectedStatuses = StatusFilter.Items.Cast<ListItem>().Where(i => i.Selected).Select(i => i.Value).ToList();
        var selectedOwners = OwnerFilter.Items.Cast<ListItem>().Where(i => i.Selected).Select(i => i.Value).ToList();
        FilterState.Save(Session, selectedStatuses, selectedOwners);

        var filtered = FilterState.Apply(Session, data.Tasks);

        TasksGrid.DataSource = filtered;
        TasksGrid.DataBind();

        StatusChartDataJson = ChartData.ToJsArray("Status", "Count", Kpis.TasksByStatus(filtered));
    }
}
