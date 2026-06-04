#!/usr/bin/env python3
"""Block dangerous bash commands."""
import json, sys, re

PATTERNS = [
    (r'rm\s+-rf\s+/', "Recursive delete from root"),
    (r'rm\s+-rf\s+~', "Recursive delete from home"),
    (r'rm\s+-rf\s+\*', "Recursive delete wildcard"),
    (r'git\s+push.*--force.*main', "Force push to main"),
    (r'git\s+push.*--force.*master', "Force push to master"),
    (r'git\s+push\s+-f\s+.*main', "Force push to main"),
    (r'git\s+push\s+-f\s+.*master', "Force push to master"),
    (r'DROP\s+DATABASE', "Drop database"),
    (r'DROP\s+TABLE', "Drop table"),
    (r'TRUNCATE\s+TABLE', "Truncate table"),
    (r'DELETE\s+FROM\s+\w+\s*;?\s*$', "Delete all rows without WHERE"),
    (r'chmod\s+-R\s+777', "Recursive chmod 777"),
    (r'mkfs\.', "Format filesystem"),
]

def main():
    try:
        hook_input = json.load(sys.stdin)
    except Exception:
        hook_input = {}

    command = hook_input.get('tool_input', {}).get('command', '')

    for pattern, description in PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            print(json.dumps({
                "block": True,
                "message": f"BLOCKED: {description}. Run manually if intentional."
            }))
            sys.exit(2)

    sys.exit(0)

if __name__ == "__main__":
    main()
