using System;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using SharePointReportingDashboard.Services;

namespace SharePointReportingDashboard
{
    public partial class SitesPage : Page
    {
        protected GridView sitesGrid;
        protected GridView listsGrid;
        protected DropDownList siteFilter;

        private ISharePointDataService Service => DataServiceFactory.GetService();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack)
            {
                return;
            }

            var sites = Service.GetSites();

            sitesGrid.DataSource = sites;
            sitesGrid.DataBind();

            siteFilter.Items.Clear();
            siteFilter.Items.Add(new ListItem("All Sites", ""));
            foreach (var site in sites)
            {
                siteFilter.Items.Add(new ListItem(site.Title, site.Title));
            }

            BindLists(string.Empty);
        }

        protected void siteFilter_SelectedIndexChanged(object sender, EventArgs e)
        {
            BindLists(siteFilter.SelectedValue);
        }

        private void BindLists(string siteTitle)
        {
            listsGrid.DataSource = Service.GetLists(siteTitle);
            listsGrid.DataBind();
        }
    }
}
