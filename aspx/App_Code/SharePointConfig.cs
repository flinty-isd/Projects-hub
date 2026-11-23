using System.Configuration;

namespace SharePointPmDashboard.App_Code
{
    public class SharePointConfig
    {
        public string TenantId { get; set; }
        public string ClientId { get; set; }
        public string ClientSecret { get; set; }
        public string SiteHostname { get; set; }
        public string SitePath { get; set; }
        public string TasksList { get; set; }
        public string RisksList { get; set; }

        /// <summary>Returns null (rather than throwing) whenever required settings are
        /// missing, so callers can fall back to demo mode.</summary>
        public static SharePointConfig LoadFromAppSettings()
        {
            var settings = ConfigurationManager.AppSettings;
            string tenantId = settings["SharePoint:TenantId"];
            string clientId = settings["SharePoint:ClientId"];
            string clientSecret = settings["SharePoint:ClientSecret"];
            string siteHostname = settings["SharePoint:SiteHostname"];
            string sitePath = settings["SharePoint:SitePath"];

            if (string.IsNullOrEmpty(tenantId) || string.IsNullOrEmpty(clientId) ||
                string.IsNullOrEmpty(clientSecret) || string.IsNullOrEmpty(siteHostname) ||
                string.IsNullOrEmpty(sitePath))
            {
                return null;
            }

            string tasksList = settings["SharePoint:TasksList"];
            string risksList = settings["SharePoint:RisksList"];

            return new SharePointConfig
            {
                TenantId = tenantId,
                ClientId = clientId,
                ClientSecret = clientSecret,
                SiteHostname = siteHostname,
                SitePath = sitePath,
                TasksList = string.IsNullOrEmpty(tasksList) ? "Tasks" : tasksList,
                RisksList = string.IsNullOrEmpty(risksList) ? "Risks" : risksList,
            };
        }
    }
}
