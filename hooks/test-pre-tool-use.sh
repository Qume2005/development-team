#!/usr/bin/env bash
# Dry-run test driver for hooks/pre-tool-use. Feeds PreToolUse JSON via stdin and
# asserts ALLOW (exit 0, no stdout) vs BLOCK (exit 0, decision:block JSON) across
# the case set. Prints per-case PASS/FAIL and a final tally.
#
# Coverage:
#   - root (agent_id:null) + orphaned active-counter + PM_LOADED present +
#     SESSION present + PM_RESTRICTED present AND NEWER than SESSION -> BLOCK
#     (THE genuine regression case for the 2026-06-17 root-bypass fix: before
#      the fix the counter fallback ran for a confirmed root and granted ALLOW
#      on a stale orphaned counter entry, BYPASSING the PM_RESTRICTED block;
#      after the fix the fallback is gated behind identity_known==0 (stdin
#      readable) and a confirmed root is never excused by the counter, so it
#      falls through to the PM_RESTRICTED check and BLOCKs).
#      Red-green proof: against the committed pre-fix hook (HEAD:hooks/pre-tool-use,
#      which keys markers by UID only, no session suffix), this setup yields ALLOW
#      (the bypass); against the post-fix on-disk hook it yields BLOCK. See the
#      handoff notes for the captured RED/GREEN outputs.
#   - root + clean (no markers, no orphan) -> BLOCK ("PM skills NOT loaded")
#   - subagent via agent_type -> ALLOW
#   - root + PM_LOADED + PM_RESTRICTED present, SESSION missing -> BLOCK
#   - root + PM_LOADED + PM_RESTRICTED + SESSION NEWER than PM_RESTRICTED -> ALLOW
#     (uses `sleep 2` between touches: macOS `-nt` is SECOND-granular)
#   - traversal: session_id "../../etc/x" stays under the marker dir (sanitized)
#   - empty stdin does not crash the hook
#
# Usage: ./hooks/test-pre-tool-use.sh
# Isolated via XDG_RUNTIME_DIR=$(mktemp -d); never touches live /tmp markers.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PRETOOL_HOOK="${SCRIPT_DIR}/pre-tool-use"

# Isolated runtime dir so PM markers + counter dirs do NOT collide with a real
# dev-team session. Exported so the hook subprocess inherits it.
export XDG_RUNTIME_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pretool-hook-test.XXXXXX")"
MARKER="${XDG_RUNTIME_DIR}"
SUFFIX="${UID:-$(id -u 2>/dev/null || echo 0)}"

# The session id we feed to the hook's stdin. The hook derives its marker key as
# .dev-team-<name>-${UID}-${SANITIZED_SESSION_ID}; we must touch markers under
# the SAME key or the hook will not see them. We feed this session_id verbatim in
# the simulated stdin so both sides agree on the sanitized key.
SESSION_ID="pretool-test-session-0001"
# The sanitized form the hook will compute (tr -cd 'A-Za-z0-9_-'): this id is
# already in the safe charset so SANITIZED == SESSION_ID.
SANITIZED_SESSION="${SESSION_ID}"

PASS=0
FAIL=0
FAILURES=""

# run_case <label> <expect> <json-on-stdin>
# expect = "ALLOW" or "BLOCK" or "NOCRASH"
run_case() {
    local label="$1" expect="$2" json="$3"
    local out rc err
    out=$(printf '%s' "$json" | bash "$PRETOOL_HOOK" 2>/tmp/pretool-test-stderr.$$)
    rc=$?
    err=$(cat /tmp/pretool-test-stderr.$$ 2>/dev/null; rm -f /tmp/pretool-test-stderr.$$)
    local got
    if printf '%s' "$out" | grep -qE '"decision"[[:space:]]*:[[:space:]]*"block"'; then
        got="BLOCK"
    elif [ -z "$out" ] && [ "$rc" -eq 0 ]; then
        got="ALLOW"
    else
        got="UNEXPECTED(rc=$rc out=$out err=$err)"
    fi

    if [ "$expect" = "NOCRASH" ]; then
        # Assert ONLY exit 0 + empty stderr (decision may be either ALLOW or
        # BLOCK). The requirement is crash-freedom, not a specific decision.
        if [ "$rc" -eq 0 ] && [ -z "$err" ]; then
            printf 'PASS | %-62s -> %s (no crash)\n' "$label" "$got"
            PASS=$((PASS + 1))
        else
            printf 'FAIL | %-62s crashed rc=%s err=%s\n' "$label" "$rc" "$err"
            [ -n "$out" ] && printf '     stdout: %s\n' "$out"
            FAIL=$((FAIL + 1))
            FAILURES="${FAILURES:+${FAILURES}; }${label}"
        fi
        return
    fi

    if [ "$got" = "$expect" ]; then
        printf 'PASS | %-62s -> %s\n' "$label" "$got"
        PASS=$((PASS + 1))
    else
        printf 'FAIL | %-62s expected=%s got=%s\n' "$label" "$expect" "$got"
        [ -n "$err" ] && printf '     stderr: %s\n' "$err"
        [ -n "$out" ] && printf '     stdout: %s\n' "$out"
        FAIL=$((FAIL + 1))
        FAILURES="${FAILURES:+${FAILURES}; }${label}"
    fi
}

# Helper: session-keyed marker path for our SESSION_ID.
mkpath() { printf '%s/.dev-team-%s-%s-%s' "$MARKER" "$1" "$SUFFIX" "$SANITIZED_SESSION"; }

# Helper: wipe all markers + counter dirs between cases so each case starts clean.
reset_markers() {
    rm -f "$MARKER"/.dev-team-* 2>/dev/null || true
    rm -rf "$MARKER"/.dev-team-active-* 2>/dev/null || true
}

# A root caller PreToolUse JSON (agent_id:null, agent_type absent/null). The
# PreToolUse payload carries the tool_name; identity is what matters here.
root_json() {
    printf '{"hook_event_name":"PreToolUse","tool_name":"Read","tool_input":{"file_path":"/tmp/x"},"session_id":"%s","agent_id":null,"agent_type":null}' "$1"
}

# ===========================================================================
# CASE 1 (TRUE REGRESSION — the bug this fix closes): root (agent_id:null) +
#   an orphaned active-counter entry + PM_LOADED present + SESSION present +
#   PM_RESTRICTED present AND NEWER than SESSION -> must BLOCK.
#
#   This is the GENUINE red-green signature for the 2026-06-17 root-bypass fix.
#   The full setup must be present for the test to exercise the counter-vs-marker
#   bypass path rather than an unrelated early-exit:
#     * PM_LOADED present  -> skips the "PM skills NOT loaded" early BLOCK, so
#                             control reaches the real restriction logic.
#     * SESSION present    -> the `[ ! -f "$SESSION" ]` sub-condition is false, so
#                             the PM_RESTRICTED block depends SOLELY on the mtime
#                             comparison.
#     * sleep 2 + PM_RESTRICTED touched AFTER SESSION -> PM_RESTRICTED is strictly
#                             newer than SESSION (macOS `-nt` is SECOND-granular),
#                             so the `[ "$PM_RESTRICTED" -nt "$SESSION" ]` test is
#                             true -> a confirmed root MUST be BLOCKed here.
#     * orphan counter     -> a stale entry in the session-keyed ACTIVE_DIR, as a
#                             crash-orphaned dispatch (died without firing
#                             SubagentStop) would leave behind.
#
#   PRE-FIX behavior (committed HEAD:hooks/pre-tool-use): the counter fallback at
#   the equivalent of lines 54-57 runs UNCONDITIONALLY for a confirmed root before
#   the PM_RESTRICTED check. The orphaned entry -> active_count>0 -> exit 0 ALLOW,
#   BYPASSING the restriction. This is the bug. (Note: pre-fix keys ACTIVE_DIR by
#   UID only, so a faithful RED reproduction against the pre-fix binary must place
#   the orphan at .dev-team-active-${UID}; see the handoff notes.)
#
#   POST-FIX behavior (on-disk hook): the counter fallback is gated behind
#   `identity_known==0`; a confirmed root (stdin readable) has identity_known==1,
#   so the counter is SKIPPED. Control falls to the PM_RESTRICTED check, which
#   BLOCKs because PM_RESTRICTED is newer than SESSION. This is the fix.
# ===========================================================================
reset_markers
touch "$(mkpath pm-loaded)"
touch "$(mkpath session)"
sleep 2
touch "$(mkpath pm-restricted)"
ACTIVE_DIR="$(mkpath active)"
mkdir -p "$ACTIVE_DIR"
touch "${ACTIVE_DIR}/orphan-$$"

# UID-only marker dup (pre-fix@HEAD keys markers by UID only, no session suffix).
# Under the committed pre-fix hook: the UID-only PM_LOADED is visible -> control
# reaches the UNCONDITIONAL counter fallback -> the UID-only orphan makes
# active_count>0 -> exit 0 ALLOW (the root bypass) -> case 1 FAILs (RED).
# Under the post-fix hook these UID-only files use a different key (UID+session)
# and are never read, so case 1 still BLOCKs for the right reason (PM_RESTRICTED
# newer than SESSION) -> PASS (GREEN).
touch "${MARKER}/.dev-team-pm-loaded-${SUFFIX}"
touch "${MARKER}/.dev-team-session-${SUFFIX}"
sleep 2
touch "${MARKER}/.dev-team-pm-restricted-${SUFFIX}"
mkdir -p "${MARKER}/.dev-team-active-${SUFFIX}"
touch "${MARKER}/.dev-team-active-${SUFFIX}/orphan-$$"
run_case "1 root+orphan+PM_LOADED+PM_RESTRICTED-newer -> BLOCK (TRUE REGRESSION)" "BLOCK" \
    "$(root_json "$SESSION_ID")"

# ===========================================================================
# CASE 2: root + clean (no markers, no orphan) -> BLOCK ("PM skills NOT loaded")
#   Hits the final `if [ ! -f "$PM_LOADED" ]` branch.
# ===========================================================================
reset_markers
run_case "2 root+clean -> BLOCK (PM skills NOT loaded)" "BLOCK" \
    "$(root_json "$SESSION_ID")"

# ===========================================================================
# CASE 3: subagent via agent_type -> ALLOW (any subagent is unrestricted).
# ===========================================================================
reset_markers
run_case "3 subagent(agent_type) -> ALLOW" "ALLOW" \
    "$(cat <<EOF
{"hook_event_name":"PreToolUse","tool_name":"Read","tool_input":{"file_path":"/tmp/x"},"session_id":"${SESSION_ID}","agent_id":null,"agent_type":"development-team:intern"}
EOF
)"

# ===========================================================================
# CASE 4: root + PM_LOADED + PM_RESTRICTED present, SESSION missing -> BLOCK
#   ("PM tool restriction active"). PM_RESTRICTED exists, SESSION does not ->
#   `[ ! -f "$SESSION" ]` is true -> block path fires.
# ===========================================================================
reset_markers
touch "$(mkpath pm-loaded)"
touch "$(mkpath pm-restricted)"
run_case "4 root+PM_LOADED+PM_RESTRICTED,no-SESSION -> BLOCK" "BLOCK" \
    "$(root_json "$SESSION_ID")"

# ===========================================================================
# CASE 5: root + PM_LOADED + PM_RESTRICTED + SESSION NEWER than PM_RESTRICTED
#   -> ALLOW. The restriction is considered superseded by a newer session.
#   macOS `-nt` is SECOND-granular: `sleep 2` between touches so the mtime
#   comparison is deterministic. (Without the gap, equal mtimes would leave
#   `-nt` false but so would the inverse — we make SESSION strictly newer so
#   the `[ "$PM_RESTRICTED" -nt "$SESSION" ]` test is definitely false.)
# ===========================================================================
reset_markers
touch "$(mkpath pm-loaded)"
touch "$(mkpath pm-restricted)"
sleep 2
touch "$(mkpath session)"
run_case "5 root+PM_RESTRICTED,SESSION-newer -> ALLOW" "ALLOW" \
    "$(root_json "$SESSION_ID")"

# ===========================================================================
# CASE 6 (SECURITY — path traversal): session_id like "../../etc/x" must stay
#   under the marker dir. The hook sanitizes with `tr -cd 'A-Za-z0-9_-'`, so the
#   traversal collapses to "etcx" (slashes/dots stripped) and no marker leaks
#   outside XDG_RUNTIME_DIR. With no PM_LOADED under the SANITIZED key, the hook
#   BLOCKs ("PM skills NOT loaded") and no file is written outside MARKER.
#
#   We assert BOTH:
#     (a) the decision is BLOCK (sanitized key has no PM_LOADED);
#     (b) NO file under the literal traversal path was created — i.e. nothing
#         exists at $MARKER/../../etc/x (the escape target).
# ===========================================================================
reset_markers
TRAV_SESSION="../../etc/x"
TRAV_JSON='{"hook_event_name":"PreToolUse","tool_name":"Read","tool_input":{"file_path":"/tmp/x"},"session_id":"'"${TRAV_SESSION}"'","agent_id":null,"agent_type":null}'
out6=$(printf '%s' "$TRAV_JSON" | bash "$PRETOOL_HOOK" 2>/tmp/pretool-test-stderr6.$$)
rc6=$?
err6=$(cat /tmp/pretool-test-stderr6.$$ 2>/dev/null; rm -f /tmp/pretool-test-stderr6.$$)
label6="6 session_id='../../etc/x' -> BLOCK, no traversal"
# Escape target: resolve $MARKER/../../etc/x literally and check it does not
# exist as a side effect of this call. Use the same shell expansion the hook
# WOULD have done unsafely, so a pre-fix leak would be caught here.
ESCAPE_PARENT="$(cd "$MARKER/../.." 2>/dev/null && pwd 2>/dev/null || echo "")"
leaked=0
if [ -n "$ESCAPE_PARENT" ] && { [ -e "${ESCAPE_PARENT}/etc/x" ] || [ -e "${ESCAPE_PARENT}/etc" ] && [ "$(find "${ESCAPE_PARENT}/etc" -maxdepth 1 -name 'x' 2>/dev/null | head -1)" != "" ]; }; then
    leaked=1
fi
if [ "$rc6" -eq 0 ] && [ -z "$err6" ] \
    && printf '%s' "$out6" | grep -qE '"decision"[[:space:]]*:[[:space:]]*"block"' \
    && [ "$leaked" -eq 0 ]; then
    printf 'PASS | %-62s -> BLOCK (key sanitized, no leak)\n' "$label6"
    PASS=$((PASS + 1))
else
    printf 'FAIL | %-62s rc=%s leaked=%s err=%s\n' "$label6" "$rc6" "$leaked" "$err6"
    [ -n "$out6" ] && printf '     stdout: %s\n' "$out6"
    FAIL=$((FAIL + 1))
    FAILURES="${FAILURES:+${FAILURES}; }${label6}"
fi

# ===========================================================================
# CASE 7: empty stdin does not crash the hook. stdin is unreadable/empty ->
#   identity_known stays 0; the counter fallback MAY run (and ALLOW if an
#   orphan exists, or fall through if clean). The requirement is crash-freedom:
#   exit 0 with empty stderr. Decision may be either ALLOW or BLOCK.
# ===========================================================================
reset_markers
run_case "7 empty-stdin -> no-crash" "NOCRASH" ""

# ===========================================================================
# Summary
# ===========================================================================
echo "---"
echo "RESULT: ${PASS} passed, ${FAIL} failed"
if [ -n "$FAILURES" ]; then
    echo "FAILED CASES: ${FAILURES}"
fi
echo "---"

# Cleanup the isolated marker dir (NEVER the live /tmp).
rm -rf "$MARKER" 2>/dev/null || true

[ "$FAIL" -eq 0 ]
