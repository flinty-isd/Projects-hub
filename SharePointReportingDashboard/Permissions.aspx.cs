using System;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using SharePointReportingDashboard.Services;

namespace SharePointReportingDashboard
{
    public partial class PermissionsPage : Page
    {
        protected Repeater statsRepeater;
        protected GridView permissionsGrid;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack)
            {
                return;
            }

            var service = DataServiceFactory.GetService();
            var permissions = service.GetPermissions();

            permissionsGrid.DataSource = permissions;
            permissionsGrid.DataBind();

            statsRepeater.DataSource = new[]
            {
                new StatTile { Value = permissions.Count.ToString(), Label = "Permission Entries" },
                new StatTile { Value = permissions.Select(p => p.PrincipalName).Distinct().Count().ToString(), Label = "Unique Principals" },
                new StatTile { Value = permissions.Count(p => !p.InheritsPermissions).ToString(), Label = "Broken Inheritance" },
                new StatTile { Value = permissions.Count(p => p.IsExternalUser).ToString(), Label = "External Users" }
            };
            statsRepeater.DataBind();
        }

        protected string GetInheritanceBadge(bool inherits)
        {
            return inherits
                ? "<span class=\"badge badge-ok\">Inherited</span>"
                : "<span class=\"badge badge-broken\">Broken</span>";
        }

        protected string GetExternalBadge(bool isExternal)
        {
            return isExternal
                ? "<span class=\"badge badge-external\">External</span>"
                : "&#8212;";
        }

        private class StatTile
        {
            public string Value { get; set; }
            public string Label { get; set; }
        }
    }
}
