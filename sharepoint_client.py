"""Microsoft Graph API client for reading SharePoint list items.

Auth uses the client-credentials (app-only) flow via MSAL, since this
dashboard runs unattended rather than as a signed-in user. Requires an
Azure AD app registration with the Sites.Read.All application permission
(admin consent granted). See README.md for setup steps.
"""

from dataclasses import dataclass
from typing import Optional

import msal
import requests
import streamlit as st

GRAPH_ROOT = "https://graph.microsoft.com/v1.0"


@dataclass
class SharePointConfig:
    tenant_id: str
    client_id: str
    client_secret: str
    site_hostname: str
    site_path: str
    tasks_list: str = "Tasks"
    risks_list: str = "Risks"


def load_config_from_secrets() -> Optional[SharePointConfig]:
    """Returns None (rather than raising) whenever secrets aren't configured,
    so the caller can fall back to demo mode."""
    try:
        section = st.secrets.get("sharepoint")
    except Exception:
        return None
    if not section:
        return None

    required = ["tenant_id", "client_id", "client_secret", "site_hostname", "site_path"]
    if not all(section.get(k) for k in required):
        return None

    return SharePointConfig(
        tenant_id=section["tenant_id"],
        client_id=section["client_id"],
        client_secret=section["client_secret"],
        site_hostname=section["site_hostname"],
        site_path=section["site_path"],
        tasks_list=section.get("tasks_list", "Tasks"),
        risks_list=section.get("risks_list", "Risks"),
    )


class SharePointClient:
    def __init__(self, config: SharePointConfig):
        self.config = config
        self._token = None
        self._site_id = None

    def _get_token(self) -> str:
        if self._token:
            return self._token
        app = msal.ConfidentialClientApplication(
            client_id=self.config.client_id,
            client_credential=self.config.client_secret,
            authority=f"https://login.microsoftonline.com/{self.config.tenant_id}",
        )
        result = app.acquire_token_for_client(scopes=["https://graph.microsoft.com/.default"])
        if "access_token" not in result:
            raise RuntimeError(
                f"Failed to acquire Graph token: {result.get('error_description', result)}"
            )
        self._token = result["access_token"]
        return self._token

    def _graph_get(self, url: str) -> dict:
        headers = {"Authorization": f"Bearer {self._get_token()}"}
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        return response.json()

    def get_site_id(self) -> str:
        if self._site_id:
            return self._site_id
        url = f"{GRAPH_ROOT}/sites/{self.config.site_hostname}:{self.config.site_path}"
        self._site_id = self._graph_get(url)["id"]
        return self._site_id

    def get_list_items(self, list_name: str) -> list:
        site_id = self.get_site_id()
        url = (
            f"{GRAPH_ROOT}/sites/{site_id}/lists/{list_name}/items"
            "?expand=fields&$top=200"
        )
        items = []
        while url:
            page = self._graph_get(url)
            items.extend(page.get("value", []))
            url = page.get("@odata.nextLink")
        return items

    def get_tasks(self) -> list:
        return self.get_list_items(self.config.tasks_list)

    def get_risks(self) -> list:
        return self.get_list_items(self.config.risks_list)
