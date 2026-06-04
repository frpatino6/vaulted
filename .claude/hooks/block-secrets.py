#!/usr/bin/env python3
"""Block editing .env and secrets files."""
import json, sys, os

def main():
    try:
        hook_input = json.load(sys.stdin)
    except Exception:
        hook_input = {}

    file_path = hook_input.get('tool_input', {}).get('file_path', '')
    file_name = os.path.basename(file_path.lower())

    blocked = ['.env', '.env.local', '.env.prod', '.env.production',
               '.env.staging', '.env.development', 'secrets.', 'credentials.']

    for pattern in blocked:
        if file_name == pattern or file_name.startswith(pattern):
            print(json.dumps({
                "block": True,
                "message": f"BLOCKED: '{file_path}' may contain secrets. Edit manually."
            }))
            sys.exit(2)

    sys.exit(0)

if __name__ == "__main__":
    main()
