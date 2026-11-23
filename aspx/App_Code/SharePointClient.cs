using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Microsoft.Identity.Client;
using Newtonsoft.Json.Linq;

namespace SharePointPmDashboard.App_Code
{
    /// <summary>
    /// Microsoft Graph API client for reading SharePoint list items.
    /// Auth uses the client-credentials (app-only) flow via MSAL.NET, since this
    /// dashboard runs unattended rather than as a signed-in user. Requires an
    /// Azure AD app registration with the Sites.Read.All application permission
    /// (admin consent granted). See README.md for setup steps.
    ///
    /// Requires the Microsoft.Identity.Client and Newtonsoft.Json NuGet packages
    /// (or their DLLs placed directly in /aspx/bin) to be available to this site.
    /// </summary>
    public class SharePointClient
    {
        private const string GraphRoot = "https://graph.microsoft.com/v1.0";
        private static readonly HttpClient HttpClient = new HttpClient();

        private readonly SharePointConfig _config;
        private readonly IConfidentialClientApplication _app;
        private string _siteId;

        public SharePointClient(SharePointConfig config)
        {
            _config = config;
            _app = ConfidentialClientApplicationBuilder.Create(config.ClientId)
                .WithClientSecret(config.ClientSecret)
                .WithAuthority(new Uri("https://login.microsoftonline.com/" + config.TenantId))
                .Build();
        }

        private async Task<string> GetAccessTokenAsync()
        {
            var scopes = new[] { "https://graph.microsoft.com/.default" };
            var result = await _app.AcquireTokenForClient(scopes).ExecuteAsync();
            return result.AccessToken;
        }

        private async Task<JObject> GraphGetAsync(string url)
        {
            var token = await GetAccessTokenAsync();
            using (var request = new HttpRequestMessage(HttpMethod.Get, url))
            {
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
                var response = await HttpClient.SendAsync(request);
                response.EnsureSuccessStatusCode();
                var body = await response.Content.ReadAsStringAsync();
                return JObject.Parse(body);
            }
        }

        private async Task<string> GetSiteIdAsync()
        {
            if (_siteId != null)
            {
                return _siteId;
            }
            var url = GraphRoot + "/sites/" + _config.SiteHostname + ":" + _config.SitePath;
            var result = await GraphGetAsync(url);
            _siteId = (string)result["id"];
            return _siteId;
        }

        private async Task<List<JObject>> GetListItemsAsync(string listName)
        {
            var siteId = await GetSiteIdAsync();
            var url = GraphRoot + "/sites/" + siteId + "/lists/" + listName + "/items?expand=fields&$top=200";
            var items = new List<JObject>();
            while (!string.IsNullOrEmpty(url))
            {
                var page = await GraphGetAsync(url);
                var values = page["value"];
                if (values != null)
                {
                    foreach (var item in values)
                    {
                        items.Add((JObject)item);
                    }
                }
                var nextLink = page["@odata.nextLink"];
                url = nextLink == null ? null : (string)nextLink;
            }
            return items;
        }

        public async Task<List<TaskItem>> GetTasksAsync()
        {
            var items = await GetListItemsAsync(_config.TasksList);
            var tasks = new List<TaskItem>();
            foreach (var item in items)
            {
                var fields = (JObject)item["fields"];
                tasks.Add(new TaskItem
                {
                    Title = GetString(fields, "Title"),
                    Status = GetString(fields, "Status"),
                    AssignedTo = ExtractPerson(fields["AssignedTo"]),
                    StartDate = ParseDate(fields["StartDate"]),
                    DueDate = ParseDate(fields["DueDate"]),
                    PercentComplete = ExtractPercent(fields["PercentComplete"]),
                    Priority = GetString(fields, "Priority"),
                });
            }
            return tasks;
        }

        public async Task<List<RiskItem>> GetRisksAsync()
        {
            var items = await GetListItemsAsync(_config.RisksList);
            var risks = new List<RiskItem>();
            foreach (var item in items)
            {
                var fields = (JObject)item["fields"];
                risks.Add(new RiskItem
                {
                    Title = GetString(fields, "Title"),
                    Severity = GetString(fields, "Severity"),
                    Owner = ExtractPerson(fields["Owner"]),
                    Status = GetString(fields, "Status"),
                    Description = GetString(fields, "Description"),
                });
            }
            return risks;
        }

        private static string GetString(JObject fields, string key)
        {
            var token = fields[key];
            return token == null ? "" : token.ToString();
        }

        /// <summary>SharePoint person fields can come back as a string, an object with
        /// LookupValue/DisplayName/Email, or an array of such objects (multi-select).</summary>
        private static string ExtractPerson(JToken value)
        {
            if (value == null || value.Type == JTokenType.Null)
            {
                return "";
            }
            if (value.Type == JTokenType.Array)
            {
                var names = new List<string>();
                foreach (var v in value)
                {
                    names.Add(ExtractPerson(v));
                }
                return string.Join(", ", names);
            }
            if (value.Type == JTokenType.Object)
            {
                var lookupValue = value["LookupValue"];
                var displayName = value["DisplayName"];
                var email = value["Email"];
                if (lookupValue != null) return (string)lookupValue;
                if (displayName != null) return (string)displayName;
                if (email != null) return (string)email;
                return "";
            }
            return value.ToString();
        }

        private static double ExtractPercent(JToken value)
        {
            if (value == null || value.Type == JTokenType.Null)
            {
                return 0.0;
            }
            double pct;
            if (!double.TryParse(value.ToString(), out pct))
            {
                return 0.0;
            }
            return pct > 1 ? pct / 100.0 : pct;
        }

        private static DateTime? ParseDate(JToken value)
        {
            if (value == null || value.Type == JTokenType.Null)
            {
                return null;
            }
            DateTime date;
            if (DateTime.TryParse(value.ToString(), out date))
            {
                return date;
            }
            return null;
        }
    }
}
