#!/usr/bin/env python3
"""Auto-format Dart files after editing."""
import json, sys, subprocess, os

def main():
    try:
        hook_input = json.load(sys.stdin)
    except Exception:
        hook_input = {}

    file_path = hook_input.get('tool_input', {}).get('file_path', '')

    if not file_path.endswith('.dart') or not os.path.exists(file_path):
        sys.exit(0)

    try:
        result = subprocess.run(
            ['dart', 'format', file_path],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode == 0:
            print(json.dumps({"feedback": f"Formatted: {os.path.basename(file_path)}"}))
        sys.exit(0)
    except FileNotFoundError:
        sys.exit(0)  # dart not in PATH — non-blocking
    except Exception:
        sys.exit(0)  # never block on format errors

if __name__ == "__main__":
    main()
