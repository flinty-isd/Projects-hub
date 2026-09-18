import msal
import pandas as pd
import requests
import streamlit as st

st.set_page_config(page_title="SharePoint Permissions Audit", page_icon="🔐", layout="wide")
st.title("🔐 SharePoint Site Permissions Audit")
st.write(
    "Shows the **current** ('as now') permissions on a SharePoint site: "
    "site-level role assignments plus any lists/libraries that have broken "
    "inheritance and carry their own unique permissions."
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
                "Roles": ", ".join(roles),
            }
        )
    return rows


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

    st.success(f"Fetched current permissions for **{web['Title']}**")

    st.subheader("Site-level permissions")
    site_df = pd.DataFrame(site_rows)
    st.dataframe(site_df, use_container_width=True)

    st.subheader(
        f"Libraries/lists with unique (broken-inheritance) permissions "
        f"({len(unique_lists)} found)"
    )
    if library_rows:
        library_df = pd.DataFrame(library_rows)
        st.dataframe(library_df, use_container_width=True)
    else:
        st.info("No lists or libraries have unique permissions — all inherit from the site.")

    combined = pd.concat(
        [pd.DataFrame(site_rows), pd.DataFrame(library_rows)], ignore_index=True
    )
    st.download_button(
        "Download full report as CSV",
        combined.to_csv(index=False).encode("utf-8"),
        file_name="sharepoint_permissions_current.csv",
        mime="text/csv",
    )
else:
    st.info("Fill in the app registration details and site URL in the sidebar, then click **Fetch current permissions**.")
