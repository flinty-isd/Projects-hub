from datetime import datetime, timezone

import msal
import pandas as pd
import requests
import streamlit as st

st.set_page_config(page_title="SharePoint Permissions Audit", page_icon="🔐", layout="wide")
st.title("🔐 SharePoint Site Permissions Audit")
st.write(
    "Shows the **current** ('as now') permissions on a SharePoint site: "
    "site-level role assignments plus any lists/libraries that have broken "
    "inheritance and carry their own unique permissions. Optionally compare "
    "against a previously downloaded snapshot to see what's changed "
    "('as is' vs 'as now')."
)

with st.sidebar:
    st.header("Azure AD app registration")
    st.caption(
        "Needs the SharePoint (not Graph) application permission "
        "**Sites.FullControl.All** (or Sites.Read.All for read-only), "
        "admin-consented."
    )
    tenant_id = st.secrets.get("TENANT_ID", "") or st.text_input("Tenant ID")
    client_id = st.secrets.get("CLIENT_ID", "") or st.text_input("Client ID")
    client_secret = st.secrets.get("CLIENT_SECRET", "") or st.text_input(
        "Client secret", type="password"
    )

    st.header("Site")
    site_url = st.text_input(
        "Site URL",
        placeholder="https://contoso.sharepoint.com/sites/Marketing",
    )
    fetch = st.button("Fetch current permissions", type="primary")

    st.header("Compare with a baseline")
    st.caption(
        "Upload a snapshot CSV downloaded from a previous run of this app "
        "('as is') to see what's changed since then ('as now')."
    )
    baseline_file = st.file_uploader("Baseline snapshot (CSV)", type="csv")


def get_access_token(tenant_id: str, client_id: str, client_secret: str, resource: str) -> str:
    app = msal.ConfidentialClientApplication(
        client_id,
        authority=f"https://login.microsoftonline.com/{tenant_id}",
        client_credential=client_secret,
    )
    result = app.acquire_token_for_client(scopes=[f"{resource}/.default"])
    if "access_token" not in result:
        raise RuntimeError(
            f"{result.get('error')}: {result.get('error_description')}"
        )
    return result["access_token"]


def sp_get(site_url: str, token: str, path: str) -> dict:
    resp = requests.get(
        f"{site_url}/_api/{path}",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json;odata=verbose",
        },
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json()["d"]


def role_assignments_to_rows(raw: dict, scope: str) -> list[dict]:
    rows = []
    for ra in raw.get("results", []):
        member = ra.get("Member", {})
        roles = [
            b["Name"]
            for b in ra.get("RoleDefinitionBindings", {}).get("results", [])
        ]
        rows.append(
            {
                "Scope": scope,
                "Principal": member.get("Title"),
                "Type": "SharePoint group"
                if member.get("PrincipalType") == 8
                else member.get("PrincipalType"),
                "Login name": member.get("LoginName"),
                "Roles": ", ".join(sorted(roles)),
            }
        )
    return rows


def compare_permissions(baseline_df: pd.DataFrame, current_df: pd.DataFrame) -> pd.DataFrame:
    key_cols = ["Scope", "Login name"]
    baseline = baseline_df.fillna("").copy()
    current = current_df.fillna("").copy()

    merged = baseline.merge(
        current,
        on=key_cols,
        how="outer",
        suffixes=(" (baseline)", " (current)"),
        indicator=True,
    )

    def status(row):
        if row["_merge"] == "left_only":
            return "Removed"
        if row["_merge"] == "right_only":
            return "Added"
        if row["Roles (baseline)"] != row["Roles (current)"]:
            return "Roles changed"
        return "Unchanged"

    merged["Status"] = merged.apply(status, axis=1)
    merged["Principal"] = merged["Principal (current)"].where(
        merged["_merge"] != "left_only", merged["Principal (baseline)"]
    )

    return merged[merged["Status"] != "Unchanged"][
        [
            "Status",
            "Scope",
            "Principal",
            "Login name",
            "Roles (baseline)",
            "Roles (current)",
        ]
    ].sort_values(["Scope", "Status"])


if fetch:
    if not (tenant_id and client_id and client_secret and site_url):
        st.error("Please fill in tenant ID, client ID, client secret, and site URL.")
        st.stop()

    site_url = site_url.rstrip("/")
    root_site = "/".join(site_url.split("/")[:3])  # https://contoso.sharepoint.com

    try:
        with st.spinner("Authenticating..."):
            token = get_access_token(tenant_id, client_id, client_secret, root_site)

        with st.spinner("Reading site-level permissions..."):
            web = sp_get(
                site_url,
                token,
                "web?$select=Title,HasUniqueRoleAssignments",
            )
            site_roles_raw = sp_get(
                site_url,
                token,
                "web/roleassignments?$expand=Member,RoleDefinitionBindings",
            )
            site_rows = role_assignments_to_rows(site_roles_raw, scope=f"Site: {web['Title']}")

        with st.spinner("Scanning lists and libraries for unique permissions..."):
            lists_raw = sp_get(
                site_url,
                token,
                "web/lists?$select=Title,Id,HasUniqueRoleAssignments,Hidden,BaseTemplate",
            )
            unique_lists = [
                lst
                for lst in lists_raw.get("results", [])
                if lst.get("HasUniqueRoleAssignments") and not lst.get("Hidden")
            ]

            library_rows = []
            for lst in unique_lists:
                lib_roles_raw = sp_get(
                    site_url,
                    token,
                    f"web/lists(guid'{lst['Id']}')/roleassignments"
                    "?$expand=Member,RoleDefinitionBindings",
                )
                library_rows.extend(
                    role_assignments_to_rows(lib_roles_raw, scope=f"Library: {lst['Title']}")
                )

    except requests.HTTPError as e:
        st.error(f"SharePoint REST API error: {e}\n\n{e.response.text[:500]}")
        st.stop()
    except Exception as e:
        st.error(f"Failed to fetch permissions: {e}")
        st.stop()

    st.session_state["site_title"] = web["Title"]
    st.session_state["unique_list_count"] = len(unique_lists)
    st.session_state["current_df"] = pd.concat(
        [pd.DataFrame(site_rows), pd.DataFrame(library_rows)], ignore_index=True
    )
    st.session_state["fetched_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

if "current_df" in st.session_state:
    current_df = st.session_state["current_df"]

    st.success(
        f"Current permissions for **{st.session_state['site_title']}** "
        f"(fetched {st.session_state['fetched_at']})"
    )

    st.subheader("Site-level permissions")
    st.dataframe(
        current_df[current_df["Scope"].str.startswith("Site:")],
        use_container_width=True,
    )

    st.subheader(
        "Libraries/lists with unique (broken-inheritance) permissions "
        f"({st.session_state['unique_list_count']} found)"
    )
    library_df = current_df[current_df["Scope"].str.startswith("Library:")]
    if not library_df.empty:
        st.dataframe(library_df, use_container_width=True)
    else:
        st.info("No lists or libraries have unique permissions — all inherit from the site.")

    st.download_button(
        "Download as baseline snapshot (CSV)",
        current_df.to_csv(index=False).encode("utf-8"),
        file_name=f"sharepoint_permissions_{st.session_state['fetched_at'].split(' ')[0]}.csv",
        mime="text/csv",
    )

    if baseline_file is not None:
        st.subheader("Changes since baseline snapshot ('as is' → 'as now')")
        try:
            baseline_df = pd.read_csv(baseline_file)
            diff_df = compare_permissions(baseline_df, current_df)
        except Exception as e:
            st.error(f"Could not compare against the uploaded baseline: {e}")
        else:
            if diff_df.empty:
                st.info("No permission changes detected since the baseline snapshot.")
            else:
                st.dataframe(diff_df, use_container_width=True)
                st.download_button(
                    "Download changes as CSV",
                    diff_df.to_csv(index=False).encode("utf-8"),
                    file_name="sharepoint_permissions_changes.csv",
                    mime="text/csv",
                )
elif not fetch:
    st.info(
        "Fill in the app registration details and site URL in the sidebar, "
        "then click **Fetch current permissions**."
    )
