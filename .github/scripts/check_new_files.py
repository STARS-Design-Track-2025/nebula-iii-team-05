import subprocess
import sys
import re

# Integration mode flag — set to True to allow multiple teams' files (only do this during post-program integration phase)
INTEGRATION_MODE = False

# Define allowed (non-team) directories
ALLOWED_DIRECTORIES = {".github", "def", "docs", "gds", "lef", "lib", "mag", "sdc", "signoff", "spef", "spi", "verilog/rtl/team_projects"}

# Only change commit hash if you are a member of the post-program integration team.  All others will be banished off the face of the Earth
STABLE_COMMIT_HASH = "c91c049f5cc7811ddd143b471198dcea7065a06f"  # 07/23/2025


# Patterns for per-team project areas
TEAM_PATTERNS = [
    re.compile(r"^verilog/rtl/team_projects/(team_[0-9][0-9])/"),
    re.compile(r"^verilog/dv/(team_[0-9][0-9])/"),
    re.compile(r"^openlane/(team_[0-9][0-9])/"),
]

# Get added files compared to stable commit
result = subprocess.run(
    ["git", "diff", "--name-only", "--cached", f"{STABLE_COMMIT_HASH}"],
    capture_output=True,
    text=True,
    check=True
)

added_files = result.stdout.strip().splitlines()

invalid_files = []
touched_teams = set()

for f in added_files:
    # Check if in allowed general directories
    is_allowed = any(f.startswith(dir + "/") for dir in ALLOWED_DIRECTORIES)

    # Check if it's in a team folder and extract the team name
    matched_team = None
    for pattern in TEAM_PATTERNS:
        match = pattern.match(f)
        if match:
            matched_team = match.group(1)
            touched_teams.add(matched_team)
            break

    # If not allowed and not in any known team folder, it's invalid
    if not is_allowed and not matched_team:
        invalid_files.append(f)

# Report invalid location
if invalid_files:
    print("❌ These files are not in allowed directories:")
    for file in invalid_files:
        print(f"  - {file}")
    sys.exit(1)

# Check if more than one team was touched
if not INTEGRATION_MODE and len(touched_teams) > 1:
    print("❌ You are modifying files for multiple teams. THIS IS NOT ALLOWED")
    print("Teams affected:")
    for team in sorted(touched_teams):
        print(f"  - {team}")
    sys.exit(1)

print("✅ All added files are in allowed directories and team scope.")
