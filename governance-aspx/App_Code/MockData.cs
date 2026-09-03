using System;
using System.Collections.Generic;

namespace ItGovernanceSite.App_Code
{
    /// <summary>Sample IT governance data used in demo mode, so the site is
    /// explorable before any SharePoint credentials are configured.</summary>
    public static class MockData
    {
        public static List<PolicyItem> GetSamplePolicies()
        {
            return new List<PolicyItem>
            {
                new PolicyItem { Title = "Information Security Policy", Category = "Security", Owner = "Priya Shah",
                    Status = "Approved", Version = "3.2", LastReviewed = new DateTime(2026, 3, 12), NextReview = new DateTime(2027, 3, 12) },
                new PolicyItem { Title = "Acceptable Use Policy", Category = "Security", Owner = "Priya Shah",
                    Status = "Approved", Version = "2.1", LastReviewed = new DateTime(2025, 11, 4), NextReview = new DateTime(2026, 11, 4) },
                new PolicyItem { Title = "Data Classification Standard", Category = "Data", Owner = "Jordan Lee",
                    Status = "Under Review", Version = "1.8", LastReviewed = new DateTime(2025, 6, 20), NextReview = new DateTime(2026, 6, 20) },
                new PolicyItem { Title = "Data Retention Schedule", Category = "Data", Owner = "Jordan Lee",
                    Status = "Approved", Version = "4.0", LastReviewed = new DateTime(2026, 1, 15), NextReview = new DateTime(2027, 1, 15) },
                new PolicyItem { Title = "Change Management Policy", Category = "Operations", Owner = "Sam Okafor",
                    Status = "Approved", Version = "2.4", LastReviewed = new DateTime(2025, 9, 1), NextReview = new DateTime(2026, 9, 1) },
                new PolicyItem { Title = "Incident Response Plan", Category = "Operations", Owner = "Sam Okafor",
                    Status = "Under Review", Version = "3.0", LastReviewed = new DateTime(2025, 5, 30), NextReview = new DateTime(2026, 5, 30) },
                new PolicyItem { Title = "Third-Party Risk Standard", Category = "Vendor", Owner = "Alex Rivera",
                    Status = "Approved", Version = "1.3", LastReviewed = new DateTime(2026, 2, 8), NextReview = new DateTime(2027, 2, 8) },
                new PolicyItem { Title = "Cloud Hosting Standard", Category = "Architecture", Owner = "Alex Rivera",
                    Status = "Draft", Version = "0.9", LastReviewed = null, NextReview = new DateTime(2026, 10, 1) },
                new PolicyItem { Title = "Access Control Standard", Category = "Security", Owner = "Priya Shah",
                    Status = "Approved", Version = "2.7", LastReviewed = new DateTime(2025, 8, 14), NextReview = new DateTime(2026, 8, 14) },
                new PolicyItem { Title = "Business Continuity Policy", Category = "Operations", Owner = "Morgan Diaz",
                    Status = "Expired", Version = "1.5", LastReviewed = new DateTime(2024, 4, 2), NextReview = new DateTime(2025, 4, 2) },
                new PolicyItem { Title = "AI Usage Guidelines", Category = "Architecture", Owner = "Morgan Diaz",
                    Status = "Draft", Version = "0.4", LastReviewed = null, NextReview = new DateTime(2026, 12, 1) },
                new PolicyItem { Title = "Software Licensing Policy", Category = "Vendor", Owner = "Morgan Diaz",
                    Status = "Approved", Version = "1.1", LastReviewed = new DateTime(2025, 10, 22), NextReview = new DateTime(2026, 10, 22) },
            };
        }

        public static List<ControlItem> GetSampleControls()
        {
            return new List<ControlItem>
            {
                new ControlItem { ControlId = "A.5.1", Title = "Policies for information security", Framework = "ISO 27001",
                    Owner = "Priya Shah", Status = "Compliant", LastAssessed = new DateTime(2026, 4, 10) },
                new ControlItem { ControlId = "A.8.2", Title = "Privileged access rights", Framework = "ISO 27001",
                    Owner = "Priya Shah", Status = "Partial", LastAssessed = new DateTime(2026, 4, 10) },
                new ControlItem { ControlId = "A.8.16", Title = "Monitoring activities", Framework = "ISO 27001",
                    Owner = "Sam Okafor", Status = "Non-Compliant", LastAssessed = new DateTime(2026, 2, 28) },
                new ControlItem { ControlId = "A.5.30", Title = "ICT readiness for continuity", Framework = "ISO 27001",
                    Owner = "Morgan Diaz", Status = "Non-Compliant", LastAssessed = new DateTime(2025, 12, 5) },
                new ControlItem { ControlId = "ID.AM-1", Title = "Physical devices inventoried", Framework = "NIST CSF",
                    Owner = "Sam Okafor", Status = "Compliant", LastAssessed = new DateTime(2026, 5, 2) },
                new ControlItem { ControlId = "PR.AC-4", Title = "Access permissions managed", Framework = "NIST CSF",
                    Owner = "Priya Shah", Status = "Partial", LastAssessed = new DateTime(2026, 5, 2) },
                new ControlItem { ControlId = "DE.CM-1", Title = "Network monitored", Framework = "NIST CSF",
                    Owner = "Sam Okafor", Status = "Compliant", LastAssessed = new DateTime(2026, 5, 2) },
                new ControlItem { ControlId = "RS.RP-1", Title = "Response plan executed", Framework = "NIST CSF",
                    Owner = "Sam Okafor", Status = "Not Assessed", LastAssessed = null },
                new ControlItem { ControlId = "CC6.1", Title = "Logical access controls", Framework = "SOC 2",
                    Owner = "Priya Shah", Status = "Compliant", LastAssessed = new DateTime(2026, 3, 18) },
                new ControlItem { ControlId = "CC7.2", Title = "System monitoring", Framework = "SOC 2",
                    Owner = "Sam Okafor", Status = "Partial", LastAssessed = new DateTime(2026, 3, 18) },
                new ControlItem { ControlId = "CC8.1", Title = "Change management", Framework = "SOC 2",
                    Owner = "Jordan Lee", Status = "Compliant", LastAssessed = new DateTime(2026, 3, 18) },
                new ControlItem { ControlId = "APO12", Title = "Managed risk", Framework = "COBIT",
                    Owner = "Alex Rivera", Status = "Partial", LastAssessed = new DateTime(2026, 1, 30) },
                new ControlItem { ControlId = "BAI06", Title = "Managed IT changes", Framework = "COBIT",
                    Owner = "Jordan Lee", Status = "Compliant", LastAssessed = new DateTime(2026, 1, 30) },
                new ControlItem { ControlId = "DSS05", Title = "Managed security services", Framework = "COBIT",
                    Owner = "Priya Shah", Status = "Not Assessed", LastAssessed = null },
            };
        }

        public static List<FindingItem> GetSampleFindings()
        {
            return new List<FindingItem>
            {
                new FindingItem { Title = "Privileged accounts lack MFA enforcement", Severity = "Critical", Source = "External Audit",
                    Owner = "Priya Shah", Status = "In Remediation", RaisedDate = new DateTime(2026, 4, 15), DueDate = new DateTime(2026, 7, 15) },
                new FindingItem { Title = "Log retention below 12-month requirement", Severity = "High", Source = "External Audit",
                    Owner = "Sam Okafor", Status = "Open", RaisedDate = new DateTime(2026, 4, 15), DueDate = new DateTime(2026, 8, 1) },
                new FindingItem { Title = "DR test not performed in last 12 months", Severity = "High", Source = "Internal Audit",
                    Owner = "Morgan Diaz", Status = "Open", RaisedDate = new DateTime(2026, 2, 20), DueDate = new DateTime(2026, 6, 30) },
                new FindingItem { Title = "Orphaned accounts in legacy AD OU", Severity = "Medium", Source = "Internal Audit",
                    Owner = "Priya Shah", Status = "In Remediation", RaisedDate = new DateTime(2026, 3, 5), DueDate = new DateTime(2026, 9, 30) },
                new FindingItem { Title = "Vendor security reviews incomplete", Severity = "Medium", Source = "Self-Assessment",
                    Owner = "Alex Rivera", Status = "Open", RaisedDate = new DateTime(2026, 5, 12), DueDate = new DateTime(2026, 10, 31) },
                new FindingItem { Title = "Change tickets missing rollback plans", Severity = "Medium", Source = "Internal Audit",
                    Owner = "Jordan Lee", Status = "Closed", RaisedDate = new DateTime(2025, 11, 8), DueDate = new DateTime(2026, 3, 1) },
                new FindingItem { Title = "Security awareness completion below target", Severity = "Low", Source = "Self-Assessment",
                    Owner = "Morgan Diaz", Status = "Open", RaisedDate = new DateTime(2026, 6, 1), DueDate = new DateTime(2026, 12, 1) },
                new FindingItem { Title = "Asset inventory missing cloud workloads", Severity = "High", Source = "Internal Audit",
                    Owner = "Sam Okafor", Status = "Closed", RaisedDate = new DateTime(2025, 9, 14), DueDate = new DateTime(2026, 2, 28) },
                new FindingItem { Title = "Encryption standard not applied to backups", Severity = "Critical", Source = "Internal Audit",
                    Owner = "Sam Okafor", Status = "Open", RaisedDate = new DateTime(2026, 7, 2), DueDate = new DateTime(2026, 8, 20) },
            };
        }

        public static List<GovernanceRiskItem> GetSampleRisks()
        {
            return new List<GovernanceRiskItem>
            {
                new GovernanceRiskItem { Title = "Ransomware impacting core file services", Category = "Security", Owner = "Priya Shah",
                    Treatment = "Mitigate", Status = "Open", Likelihood = 3, Impact = 5 },
                new GovernanceRiskItem { Title = "Unsupported legacy ERP platform", Category = "Technology", Owner = "Alex Rivera",
                    Treatment = "Mitigate", Status = "Open", Likelihood = 4, Impact = 4 },
                new GovernanceRiskItem { Title = "Key person dependency in network team", Category = "Operational", Owner = "Morgan Diaz",
                    Treatment = "Mitigate", Status = "Open", Likelihood = 4, Impact = 3 },
                new GovernanceRiskItem { Title = "Cloud cost overrun vs. approved budget", Category = "Financial", Owner = "Alex Rivera",
                    Treatment = "Accept", Status = "Monitored", Likelihood = 3, Impact = 2 },
                new GovernanceRiskItem { Title = "Data residency breach in SaaS tooling", Category = "Compliance", Owner = "Jordan Lee",
                    Treatment = "Transfer", Status = "Open", Likelihood = 2, Impact = 5 },
                new GovernanceRiskItem { Title = "Shadow IT procurement outside governance", Category = "Compliance", Owner = "Morgan Diaz",
                    Treatment = "Mitigate", Status = "Open", Likelihood = 4, Impact = 2 },
                new GovernanceRiskItem { Title = "Single-region hosting for tier-1 apps", Category = "Technology", Owner = "Sam Okafor",
                    Treatment = "Mitigate", Status = "Open", Likelihood = 2, Impact = 4 },
                new GovernanceRiskItem { Title = "Third-party breach via integration partner", Category = "Vendor", Owner = "Alex Rivera",
                    Treatment = "Transfer", Status = "Closed", Likelihood = 2, Impact = 4 },
            };
        }

        public static List<ExceptionItem> GetSampleExceptions()
        {
            return new List<ExceptionItem>
            {
                new ExceptionItem { Title = "Legacy SFTP without MFA", PolicyRef = "Access Control Standard", RequestedBy = "Sam Okafor",
                    Approver = "Priya Shah", Status = "Active", ExpiryDate = new DateTime(2026, 9, 30) },
                new ExceptionItem { Title = "Local admin rights for design team", PolicyRef = "Acceptable Use Policy", RequestedBy = "Morgan Diaz",
                    Approver = "Priya Shah", Status = "Active", ExpiryDate = new DateTime(2026, 12, 31) },
                new ExceptionItem { Title = "Unencrypted archive tapes in transit", PolicyRef = "Data Classification Standard", RequestedBy = "Jordan Lee",
                    Approver = "Alex Rivera", Status = "Active", ExpiryDate = new DateTime(2026, 9, 15) },
                new ExceptionItem { Title = "Direct DB access for reporting tool", PolicyRef = "Access Control Standard", RequestedBy = "Jordan Lee",
                    Approver = "Priya Shah", Status = "Expired", ExpiryDate = new DateTime(2026, 5, 1) },
                new ExceptionItem { Title = "Extended patch window for ERP", PolicyRef = "Change Management Policy", RequestedBy = "Alex Rivera",
                    Approver = "Morgan Diaz", Status = "Pending", ExpiryDate = new DateTime(2027, 1, 31) },
                new ExceptionItem { Title = "Non-standard VPN client for contractors", PolicyRef = "Information Security Policy", RequestedBy = "Morgan Diaz",
                    Approver = "Priya Shah", Status = "Active", ExpiryDate = new DateTime(2027, 3, 1) },
            };
        }
    }
}
