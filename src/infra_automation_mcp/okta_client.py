"""Okta API Client for Infrastructure Automation"""

import os
from typing import Any, Optional
import httpx
from dotenv import load_dotenv

load_dotenv()


class OktaAPIError(Exception):
    def __init__(self, message: str, status_code: Optional[int] = None):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class OktaClient:
    """Async client for Okta Management API."""
    
    def __init__(self):
        self.base_url = os.getenv("OKTA_BASE_URL", "").rstrip("/")
        self.api_token = os.getenv("OKTA_API_TOKEN", "")
        if not self.base_url or not self.api_token:
            raise OktaAPIError("OKTA_BASE_URL and OKTA_API_TOKEN must be configured")
        self._client: Optional[httpx.AsyncClient] = None

    async def __aenter__(self):
        self._client = httpx.AsyncClient(
            base_url=self.base_url,
            headers={
                "Authorization": f"SSWS {self.api_token}",
                "Accept": "application/json",
                "Content-Type": "application/json"
            },
            timeout=30.0
        )
        return self

    async def __aexit__(self, *args):
        if self._client:
            await self._client.aclose()

    async def _request(self, method: str, endpoint: str, params: dict = None, json_data: dict = None) -> Any:
        if not self._client:
            raise OktaAPIError("Client not initialized")
        response = await self._client.request(method, endpoint, params=params, json=json_data)
        if response.status_code in [200, 201]:
            return response.json()
        elif response.status_code == 204:
            return {"success": True}
        else:
            raise OktaAPIError(f"Request failed: {response.status_code}", response.status_code)

    # User operations
    async def list_users(self, search: str = None, limit: int = 20) -> list:
        params = {"limit": limit}
        if search:
            params["search"] = search
        return await self._request("GET", "/api/v1/users", params=params)

    async def get_user(self, user_id: str) -> dict:
        return await self._request("GET", f"/api/v1/users/{user_id}")

    async def create_user(self, email: str, first_name: str, last_name: str, 
                          department: str = None, title: str = None, activate: bool = True) -> dict:
        profile = {"firstName": first_name, "lastName": last_name, "email": email, "login": email}
        if department:
            profile["department"] = department
        if title:
            profile["title"] = title
        return await self._request("POST", "/api/v1/users", params={"activate": str(activate).lower()}, 
                                   json_data={"profile": profile})

    async def deactivate_user(self, user_id: str) -> dict:
        return await self._request("POST", f"/api/v1/users/{user_id}/lifecycle/deactivate")

    # Group operations
    async def list_groups(self, search: str = None, limit: int = 20) -> list:
        params = {"limit": limit}
        if search:
            params["q"] = search
        return await self._request("GET", "/api/v1/groups", params=params)

    async def get_group(self, group_id: str) -> dict:
        return await self._request("GET", f"/api/v1/groups/{group_id}")

    async def create_group(self, name: str, description: str = None) -> dict:
        return await self._request("POST", "/api/v1/groups", 
                                   json_data={"profile": {"name": name, "description": description or name}})

    async def get_group_members(self, group_id: str) -> list:
        return await self._request("GET", f"/api/v1/groups/{group_id}/users")

    async def add_user_to_group(self, group_id: str, user_id: str) -> dict:
        return await self._request("PUT", f"/api/v1/groups/{group_id}/users/{user_id}")

    async def remove_user_from_group(self, group_id: str, user_id: str) -> dict:
        return await self._request("DELETE", f"/api/v1/groups/{group_id}/users/{user_id}")

    # App operations
    async def list_apps(self, limit: int = 20) -> list:
        return await self._request("GET", "/api/v1/apps", params={"limit": limit})

    async def get_user_apps(self, user_id: str) -> list:
        return await self._request("GET", f"/api/v1/users/{user_id}/appLinks")