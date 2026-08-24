import os
import subprocess


def set_ado_variable(name, value):
    print(f"##vso[task.setvariable variable={name}]{value}")


def clean_env_value(name):
    return os.environ.get(name, "").replace("\r", "").replace("\n", "")


def run(command, cwd=None, capture_output=False, text=False):
    return subprocess.run(
        command,
        cwd=cwd,
        check=True,
        capture_output=capture_output,
        text=text,
    )


def run_allow_failure(command, cwd=None, capture_output=False, text=False):
    return subprocess.run(
        command,
        cwd=cwd,
        check=False,
        capture_output=capture_output,
        text=text,
    )
