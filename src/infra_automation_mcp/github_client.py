"""GitHub API Client for PR and Repository Operations"""

import os
from typing import Optional
from github import Github, GithubException


class GitHubError(Exception):
    def __init__(self, message: str):
        self.message = message
        super().__init__(self.message)


class GitHubClient:
    """Client for GitHub operations - PRs, commits, workflow triggers."""
    
    def __init__(self):
        self.token = os.getenv("GITHUB_TOKEN", "")
        self.repo_name = os.getenv("GITHUB_REPO", "")  # format: owner/repo
        if not self.token:
            raise GitHubError("GITHUB_TOKEN must be configured")
        self.client = Github(self.token)
        self._repo = None

    @property
    def repo(self):
        if not self._repo and self.repo_name:
            self._repo = self.client.get_repo(self.repo_name)
        return self._repo

    def create_branch(self, branch_name: str, base_branch: str = "main") -> dict:
        """Create a new branch from base branch."""
        try:
            base_ref = self.repo.get_branch(base_branch)
            self.repo.create_git_ref(
                ref=f"refs/heads/{branch_name}",
                sha=base_ref.commit.sha
            )
            return {"success": True, "branch": branch_name, "base": base_branch}
        except GithubException as e:
            raise GitHubError(f"Failed to create branch: {e}")

    def create_file(self, path: str, content: str, message: str, branch: str) -> dict:
        """Create or update a file in the repository."""
        try:
            # Check if file exists
            try:
                existing = self.repo.get_contents(path, ref=branch)
                result = self.repo.update_file(
                    path=path,
                    message=message,
                    content=content,
                    sha=existing.sha,
                    branch=branch
                )
            except GithubException:
                result = self.repo.create_file(
                    path=path,
                    message=message,
                    content=content,
                    branch=branch
                )
            return {"success": True, "path": path, "sha": result["commit"].sha}
        except GithubException as e:
            raise GitHubError(f"Failed to create file: {e}")

    def create_pull_request(self, title: str, body: str, head_branch: str, 
                            base_branch: str = "main") -> dict:
        """Create a pull request."""
        try:
            pr = self.repo.create_pull(
                title=title,
                body=body,
                head=head_branch,
                base=base_branch
            )
            return {
                "success": True,
                "pr_number": pr.number,
                "url": pr.html_url,
                "title": title
            }
        except GithubException as e:
            raise GitHubError(f"Failed to create PR: {e}")

    def list_pull_requests(self, state: str = "open") -> list:
        """List pull requests."""
        try:
            prs = self.repo.get_pulls(state=state)
            return [{
                "number": pr.number,
                "title": pr.title,
                "state": pr.state,
                "author": pr.user.login,
                "url": pr.html_url,
                "created_at": pr.created_at.isoformat()
            } for pr in prs]
        except GithubException as e:
            raise GitHubError(f"Failed to list PRs: {e}")

    def get_pull_request(self, pr_number: int) -> dict:
        """Get details of a specific PR."""
        try:
            pr = self.repo.get_pull(pr_number)
            return {
                "number": pr.number,
                "title": pr.title,
                "body": pr.body,
                "state": pr.state,
                "author": pr.user.login,
                "url": pr.html_url,
                "mergeable": pr.mergeable,
                "files_changed": pr.changed_files,
                "additions": pr.additions,
                "deletions": pr.deletions
            }
        except GithubException as e:
            raise GitHubError(f"Failed to get PR: {e}")

    def merge_pull_request(self, pr_number: int, merge_method: str = "squash") -> dict:
        """Merge a pull request."""
        try:
            pr = self.repo.get_pull(pr_number)
            result = pr.merge(merge_method=merge_method)
            return {
                "success": result.merged,
                "message": result.message,
                "sha": result.sha
            }
        except GithubException as e:
            raise GitHubError(f"Failed to merge PR: {e}")

    def list_workflow_runs(self, workflow_name: str = None, limit: int = 10) -> list:
        """List recent workflow runs."""
        try:
            if workflow_name:
                workflow = self.repo.get_workflow(workflow_name)
                runs = workflow.get_runs()[:limit]
            else:
                runs = self.repo.get_workflow_runs()[:limit]
            
            return [{
                "id": run.id,
                "name": run.name,
                "status": run.status,
                "conclusion": run.conclusion,
                "branch": run.head_branch,
                "url": run.html_url,
                "created_at": run.created_at.isoformat()
            } for run in runs]
        except GithubException as e:
            raise GitHubError(f"Failed to list workflows: {e}")

    def trigger_workflow(self, workflow_name: str, ref: str = "main", inputs: dict = None) -> dict:
        """Trigger a workflow dispatch event."""
        try:
            workflow = self.repo.get_workflow(workflow_name)
            result = workflow.create_dispatch(ref=ref, inputs=inputs or {})
            return {"success": True, "workflow": workflow_name, "ref": ref}
        except GithubException as e:
            raise GitHubError(f"Failed to trigger workflow: {e}")