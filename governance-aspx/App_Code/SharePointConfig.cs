using System.Configuration;

namespace ItGovernanceSite.App_Code
{
    public class SharePointConfig
    {
        public string TenantId { get; set; }
        public string ClientId { get; set; }
        public string ClientSecret { get; set; }
        public string SiteHostname { get; set; }
        public string SitePath { get; set; }
        public string PoliciesList { get; set; }
        public string ControlsList { get; set; }
        public string FindingsList { get; set; }
        public string RisksList { get; set; }
        public string ExceptionsList { get; set; }

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

            return new SharePointConfig
            {
                TenantId = tenantId,
                ClientId = clientId,
                ClientSecret = clientSecret,
                SiteHostname = siteHostname,
                SitePath = sitePath,
                PoliciesList = Or(settings["SharePoint:PoliciesList"], "Policies"),
                ControlsList = Or(settings["SharePoint:ControlsList"], "Controls"),
                FindingsList = Or(settings["SharePoint:FindingsList"], "AuditFindings"),
                RisksList = Or(settings["SharePoint:RisksList"], "RiskRegister"),
                ExceptionsList = Or(settings["SharePoint:ExceptionsList"], "PolicyExceptions"),
            };
        }

        private static string Or(string value, string fallback)
        {
            return string.IsNullOrEmpty(value) ? fallback : value;
        }
    }
}
