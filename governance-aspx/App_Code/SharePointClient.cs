using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Microsoft.Identity.Client;
using Newtonsoft.Json.Linq;

namespace ItGovernanceSite.App_Code
{
    /// <summary>
    /// Microsoft Graph API client for reading the governance SharePoint lists.
    /// Auth uses the client-credentials (app-only) flow via MSAL.NET, since this
    /// site runs unattended rather than as a signed-in user. Requires an Azure AD
    /// app registration with the Sites.Read.All application permission (admin
    /// consent granted). See README.md for setup steps.
    ///
    /// Requires the Microsoft.Identity.Client and Newtonsoft.Json NuGet packages
    /// (or their DLLs placed directly in /governance-aspx/bin).
    ///
    /// If your lists use different internal column names than the ones read below,
    /// adjust the field lookups in each Get*Async method. Internal names can be
    /// found via Graph Explorer: GET /sites/{site-id}/lists/{list-id}/columns
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
                        var fields = item["fields"] as JObject;
                        if (fields != null)
                        {
                            items.Add(fields);
                        }
                    }
                }
                var nextLink = page["@odata.nextLink"];
                url = nextLink == null ? null : (string)nextLink;
            }
            return items;
        }

        public async Task<List<PolicyItem>> GetPoliciesAsync()
        {
            var fieldSets = await GetListItemsAsync(_config.PoliciesList);
            var policies = new List<PolicyItem>();
            foreach (var fields in fieldSets)
            {
                policies.Add(new PolicyItem
                {
                    Title = GetString(fields, "Title"),
                    Category = GetString(fields, "Category"),
                    Owner = ExtractPerson(fields["Owner"]),
                    Status = GetString(fields, "Status"),
                    Version = GetString(fields, "Version"),
                    LastReviewed = ParseDate(fields["LastReviewed"]),
                    NextReview = ParseDate(fields["NextReview"]),
                });
            }
            return policies;
        }

        public async Task<List<ControlItem>> GetControlsAsync()
        {
            var fieldSets = await GetListItemsAsync(_config.ControlsList);
            var controls = new List<ControlItem>();
            foreach (var fields in fieldSets)
            {
                controls.Add(new ControlItem
                {
                    ControlId = GetString(fields, "ControlId"),
                    Title = GetString(fields, "Title"),
                    Framework = GetString(fields, "Framework"),
                    Owner = ExtractPerson(fields["Owner"]),
                    Status = GetString(fields, "Status"),
                    LastAssessed = ParseDate(fields["LastAssessed"]),
                });
            }
            return controls;
        }

        public async Task<List<FindingItem>> GetFindingsAsync()
        {
            var fieldSets = await GetListItemsAsync(_config.FindingsList);
            var findings = new List<FindingItem>();
            foreach (var fields in fieldSets)
            {
                findings.Add(new FindingItem
                {
                    Title = GetString(fields, "Title"),
                    Severity = GetString(fields, "Severity"),
                    Source = GetString(fields, "Source"),
                    Owner = ExtractPerson(fields["Owner"]),
                    Status = GetString(fields, "Status"),
                    RaisedDate = ParseDate(fields["RaisedDate"]),
                    DueDate = ParseDate(fields["DueDate"]),
                });
            }
            return findings;
        }

        public async Task<List<GovernanceRiskItem>> GetRisksAsync()
        {
            var fieldSets = await GetListItemsAsync(_config.RisksList);
            var risks = new List<GovernanceRiskItem>();
            foreach (var fields in fieldSets)
            {
                risks.Add(new GovernanceRiskItem
                {
                    Title = GetString(fields, "Title"),
                    Category = GetString(fields, "Category"),
                    Owner = ExtractPerson(fields["Owner"]),
                    Treatment = GetString(fields, "Treatment"),
                    Status = GetString(fields, "Status"),
                    Likelihood = ParseInt(fields["Likelihood"]),
                    Impact = ParseInt(fields["Impact"]),
                });
            }
            return risks;
        }

        public async Task<List<ExceptionItem>> GetExceptionsAsync()
        {
            var fieldSets = await GetListItemsAsync(_config.ExceptionsList);
            var exceptions = new List<ExceptionItem>();
            foreach (var fields in fieldSets)
            {
                exceptions.Add(new ExceptionItem
                {
                    Title = GetString(fields, "Title"),
                    PolicyRef = GetString(fields, "PolicyRef"),
                    RequestedBy = ExtractPerson(fields["RequestedBy"]),
                    Approver = ExtractPerson(fields["Approver"]),
                    Status = GetString(fields, "Status"),
                    ExpiryDate = ParseDate(fields["ExpiryDate"]),
                });
            }
            return exceptions;
        }

        private static string GetString(JObject fields, string key)
        {
            var token = fields[key];
            return token == null || token.Type == JTokenType.Null ? "" : token.ToString();
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
                foreach (var entry in value)
                {
                    var name = ExtractPerson(entry);
                    if (!string.IsNullOrEmpty(name))
                    {
                        names.Add(name);
                    }
                }
                return string.Join(", ", names);
            }
            if (value.Type == JTokenType.Object)
            {
                var lookupValue = value["LookupValue"];
                if (lookupValue != null) return (string)lookupValue;
                var displayName = value["DisplayName"];
                if (displayName != null) return (string)displayName;
                var email = value["Email"];
                if (email != null) return (string)email;
                return "";
            }
            return value.ToString();
        }

        private static DateTime? ParseDate(JToken value)
        {
            if (value == null || value.Type == JTokenType.Null)
            {
                return null;
            }
            DateTime date;
            return DateTime.TryParse(value.ToString(), out date) ? (DateTime?)date : null;
        }

        private static int ParseInt(JToken value)
        {
            if (value == null || value.Type == JTokenType.Null)
            {
                return 0;
            }
            double parsed;
            return double.TryParse(value.ToString(), out parsed) ? (int)Math.Round(parsed) : 0;
        }
    }
}
