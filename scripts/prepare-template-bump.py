import os
import shutil

from ci_utils import run, set_ado_variable


def main():
    source_branch_ref = os.environ.get("SYSTEM_PULLREQUEST_SOURCEBRANCH", "")
    target_branch_ref = os.environ.get("SYSTEM_PULLREQUEST_TARGETBRANCH", "")

    source_branch = source_branch_ref.replace("refs/heads/", "", 1)
    target_branch = target_branch_ref.replace("refs/heads/", "", 1)

    if not source_branch or not target_branch:
        print("PR source or target branch not available; skipping template bump")
        set_ado_variable("shouldRunTemplateBump", "false")
        set_ado_variable("hasTemplateChanges", "false")
        return

    set_ado_variable("sourceBranch", source_branch)
    set_ado_variable("targetBranch", target_branch)
    set_ado_variable("shouldRunTemplateBump", "true")

    print(f"Fetching PR branches: source={source_branch}, target={target_branch}")
    run(["git", "fetch", "origin", source_branch, target_branch])
    run(["git", "checkout", "-B", source_branch, f"origin/{source_branch}"])

    diff_command = [
        "git",
        "diff",
        "--name-only",
        f"origin/{target_branch}...HEAD",
        "--",
        "library/templates/v2/**",
    ]
    diff_result = run(diff_command, capture_output=True, text=True)
    changed_files = " ".join(line for line in diff_result.stdout.splitlines() if line.strip())

    if not changed_files:
        print("No template changes detected in library/templates/v2; skipping bump")
        set_ado_variable("hasTemplateChanges", "false")
        return

    print(f"Template files changed: {changed_files}")
    set_ado_variable("changedTemplateFiles", changed_files)
    set_ado_variable("hasTemplateChanges", "true")

    for file_path in ("/tmp/master-tpl-versions.txt", "/tmp/bumped-tpl-versions.txt"):
        if os.path.exists(file_path):
            os.remove(file_path)

    master_workdir = ".tmp/master-baseline"
    if os.path.isdir(master_workdir):
        shutil.rmtree(master_workdir)

    run(["git", "worktree", "add", master_workdir, f"origin/{target_branch}"])
    try:
        run(["python", "scripts/extract-tpl-versions.py"], cwd=master_workdir)
    finally:
        run(["git", "worktree", "remove", master_workdir, "--force"])


if __name__ == "__main__":
    main()
