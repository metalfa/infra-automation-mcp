"""Slack Notification Client"""

import os
import httpx
from typing import Optional


class SlackError(Exception):
    def __init__(self, message: str):
        self.message = message
        super().__init__(self.message)


class SlackClient:
    """Client for sending Slack notifications."""
    
    def __init__(self):
        self.webhook_url = os.getenv("SLACK_WEBHOOK_URL", "")
    
    async def send_message(self, message: str, channel: Optional[str] = None) -> dict:
        """Send a simple message to Slack."""
        if not self.webhook_url:
            return {"success": False, "error": "SLACK_WEBHOOK_URL not configured"}
        
        payload = {"text": message}
        if channel:
            payload["channel"] = channel
        
        async with httpx.AsyncClient() as client:
            response = await client.post(self.webhook_url, json=payload)
            if response.status_code == 200:
                return {"success": True, "message": "Notification sent"}
            else:
                return {"success": False, "error": f"Failed: {response.status_code}"}
    
    async def send_pr_notification(
        self, 
        pr_title: str, 
        pr_url: str, 
        pr_number: int,
        author: str,
        approvers: list,
        description: str = ""
    ) -> dict:
        """Send a formatted PR notification to Slack."""
        if not self.webhook_url:
            return {"success": False, "error": "SLACK_WEBHOOK_URL not configured"}
        
        approver_mentions = ", ".join([f"@{a}" for a in approvers])
        
        payload = {
            "blocks": [
                {
                    "type": "header",
                    "text": {
                        "type": "plain_text",
                        "text": "🔔 New Infrastructure PR Awaiting Approval",
                        "emoji": True
                    }
                },
                {
                    "type": "section",
                    "fields": [
                        {"type": "mrkdwn", "text": f"*PR:*\n<{pr_url}|#{pr_number} {pr_title}>"},
                        {"type": "mrkdwn", "text": f"*Author:*\n{author}"}
                    ]
                },
                {
                    "type": "section",
                    "fields": [
                        {"type": "mrkdwn", "text": f"*Approvers Needed:*\n{approver_mentions}"},
                        {"type": "mrkdwn", "text": f"*Type:*\nInfrastructure Change"}
                    ]
                },
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": f"*Description:*\n{description[:200] if description else 'No description provided'}"
                    }
                },
                {
                    "type": "actions",
                    "elements": [
                        {
                            "type": "button",
                            "text": {"type": "plain_text", "text": "Review PR", "emoji": True},
                            "url": pr_url,
                            "style": "primary"
                        }
                    ]
                }
            ]
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(self.webhook_url, json=payload)
            if response.status_code == 200:
                return {"success": True, "message": "PR notification sent to Slack"}
            else:
                return {"success": False, "error": f"Failed: {response.status_code}"}