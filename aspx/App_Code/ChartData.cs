using System.Collections.Generic;
using System.Text;

namespace SharePointPmDashboard.App_Code
{
    /// <summary>Builds the literal JS array that Google Charts' arrayToDataTable()
    /// consumes, escaping values so list data can't break out of the script block.</summary>
    public static class ChartData
    {
        public static string ToJsArray(string categoryHeader, string valueHeader,
            IEnumerable<KeyValuePair<string, int>> rows)
        {
            var sb = new StringBuilder();
            sb.Append("[['").Append(Escape(categoryHeader)).Append("','").Append(Escape(valueHeader)).Append("']");
            foreach (var row in rows)
            {
                sb.Append(",['").Append(Escape(row.Key)).Append("',").Append(row.Value).Append("]");
            }
            sb.Append("]");
            return sb.ToString();
        }

        /// <summary>Escapes for a single-quoted JS string literal inside an inline
        /// &lt;script&gt; block. Angle brackets and ampersands are escaped as well so a
        /// value containing "&lt;/script&gt;" cannot terminate the block early.</summary>
        private static string Escape(string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                return "";
            }
            return value
                .Replace("\\", "\\\\")
                .Replace("'", "\\'")
                .Replace("\r", "")
                .Replace("\n", " ")
                .Replace("<", "\\u003c")
                .Replace(">", "\\u003e")
                .Replace("&", "\\u0026");
        }
    }
}
