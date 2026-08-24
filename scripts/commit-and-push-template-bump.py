import os

from ci_utils import clean_env_value, run, run_allow_failure


def main():
    if run_allow_failure(["git", "diff", "--quiet"]).returncode == 0:
        print("No git diff after bump script; skipping commit and push")
        return

    source_repo_uri = os.environ.get("SYSTEM_PULLREQUEST_SOURCEREPOSITORYURI", "")
    if not source_repo_uri:
        build_repository_name = os.environ.get("BUILD_REPOSITORY_NAME", "")
        source_repo_uri = f"https://github.com/{build_repository_name}.git"

    source_repo_uri = source_repo_uri.rstrip("/")
    if source_repo_uri.endswith(".git"):
        push_repo_url = source_repo_uri
    else:
        push_repo_url = f"{source_repo_uri}.git"

    source_branch = os.environ.get("SOURCE_BRANCH", "")
    if not source_branch:
        print("SOURCE_BRANCH is empty. Check sourceBranch pipeline variable.")
        raise SystemExit(1)

    github_username = clean_env_value("GITHUB_USERNAME")
    if not github_username:
        print("GITHUB_USERNAME is not set. Check Key Vault secret github-chart-automation-username.")
        raise SystemExit(1)

    github_token = clean_env_value("GITHUB_TOKEN")
    if not github_token:
        print("GITHUB_TOKEN is empty. Check Key Vault secret github-chart-automation-token.")
        raise SystemExit(1)

    auth_push_url = push_repo_url.replace("https://", f"https://{github_username}:{github_token}@", 1)

    print(f"Push target repository: {push_repo_url}")
    print(f"Push target branch: {source_branch}")

    run(["git", "remote", "set-url", "origin", auth_push_url])

    dry_run = run_allow_failure(
        ["git", "push", "--dry-run", "origin", f"HEAD:{source_branch}"],
        capture_output=True,
        text=True,
    )
    if dry_run.returncode != 0:
        print(f"Push preflight failed for {push_repo_url} on branch {source_branch}.")
        if dry_run.stdout:
            print(dry_run.stdout)
        if dry_run.stderr:
            print(dry_run.stderr)
        print("Check token scope, org SSO authorization, repository write permission, and branch protection/rulesets.")
        raise SystemExit(1)

    run(["git", "config", "user.name", "hmcts-platform-operations"])
    run(["git", "config", "user.email", "github-platform-operations@hmcts.net"])

    run(["git", "add", "-A", "library/templates/v2"])
    if run_allow_failure(["git", "diff", "--cached", "--quiet"]).returncode == 0:
        print("No staged template changes to commit; skipping push")
        return

    run(["git", "commit", "-m", "Bump helm template versions [auto-bump]"])
    run(["git", "push", "origin", f"HEAD:{source_branch}"])


if __name__ == "__main__":
    main()
