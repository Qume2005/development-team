#!/usr/bin/env bash
# Dry-run test driver for hooks/stop. Feeds JSON via stdin and asserts
# ALLOW (exit 0, no stdout) vs BLOCK (exit 0, decision:block JSON) across the
# full case set (1-19). Prints per-case PASS/FAIL and a final tally.
#
# Usage: ./hooks/test-stop.sh
# Env overrides honored: DEV_TEAM_TASKS_DIR (fixture), DEV_TEAM_POLL_MAX_WAIT_S,
#   plus MARKER_DIR (XDG_RUNTIME_DIR) for the PM marker + audit log.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STOP_HOOK="${SCRIPT_DIR}/stop"

# Isolated runtime dir so the PM marker + audit log do not collide with a
# real dev-team session. We export XDG_RUNTIME_DIR for the hook subprocess.
export XDG_RUNTIME_DIR="$(mktemp -d "${TMPDIR:-/tmp}/stop-hook-test.XXXXXX")"
MARKER="${XDG_RUNTIME_DIR}"
# Make the PM-loaded marker so step 2 passes (we ARE a PM session).
SUFFIX="${UID:-$(id -u 2>/dev/null || echo 0)}"
touch "${MARKER}/.dev-team-pm-loaded-${SUFFIX}"

# Fixture tasks dir.
TASKS_FIXTURE="$(mktemp -d "${TMPDIR:-/tmp}/stop-tasks.XXXXXX")"
export DEV_TEAM_TASKS_DIR="$TASKS_FIXTURE"
export DEV_TEAM_POLL_MAX_WAIT_S="3600"

# A stable session id whose subdir we populate with pending/completed tasks.
SESSION_ID="test-session-0001"
SESS_DIR="${TASKS_FIXTURE}/${SESSION_ID}"
mkdir -p "$SESS_DIR"

# Helper: write a task JSON file. $1=filename, $2=status.
write_task() {
    local fname="$1" status="$2"
    cat > "${SESS_DIR}/${fname}" <<EOF
{"id":"${fname%.json}","subject":"task ${fname}","status":"${status}"}
EOF
}

PASS=0
FAIL=0
FAILURES=""

# run_case <label> <expect> <json-on-stdin>
# expect = "ALLOW" or "BLOCK"
run_case() {
    local label="$1" expect="$2" json="$3"
    local out rc
    out=$(printf '%s' "$json" | bash "$STOP_HOOK" 2>/tmp/stop-test-stderr.$$)
    rc=$?
    local err
    err=$(cat /tmp/stop-test-stderr.$$ 2>/dev/null; rm -f /tmp/stop-test-stderr.$$)
    local got
    if printf '%s' "$out" | grep -qE '"decision"[[:space:]]*:[[:space:]]*"block"'; then
        got="BLOCK"
    elif [ -z "$out" ] && [ "$rc" -eq 0 ]; then
        got="ALLOW"
    else
        got="UNEXPECTED(rc=$rc out=$out err=$err)"
    fi
    if [ "$got" = "$expect" ]; then
        printf 'PASS | %-58s -> %s\n' "$label" "$got"
        PASS=$((PASS + 1))
    else
        printf 'FAIL | %-58s expected=%s got=%s\n' "$label" "$expect" "$got"
        [ -n "$err" ] && printf '     stderr: %s\n' "$err"
        [ -n "$out" ] && printf '     stdout: %s\n' "$out"
        FAIL=$((FAIL + 1))
        FAILURES="${FAILURES:+${FAILURES}; }${label}"
    fi
}

# Reset fixture between case groups as needed.
reset_pending() {
    rm -f "${SESS_DIR}"/*.json "${SESS_DIR}"/*.lock 2>/dev/null || true
}

# --- Build a "pending" fixture for cases that need it ----------------------
make_pending() {
    reset_pending
    write_task "1.json" "in_progress"
    write_task "2.json" "blocked"
    write_task "3.json" "pending"
}

# ===========================================================================
# CASE 1: no pending todos -> ALLOW
# ===========================================================================
reset_pending
write_task "1.json" "completed"
write_task "2.json" "deleted"
run_case "1 no-pending-todos -> ALLOW" "ALLOW" \
    "{\"hook_event_name\":\"Stop\",\"session_id\":\"${SESSION_ID}\"}"

# ===========================================================================
# CASE 2: pending + no bg + no cron -> BLOCK
# ===========================================================================
make_pending
run_case "2 pending+no-bg+no-cron -> BLOCK" "BLOCK" \
    "{\"hook_event_name\":\"Stop\",\"session_id\":\"${SESSION_ID}\",\"background_tasks\":[],\"session_crons\":[]}"

# ===========================================================================
# CASE 3: pending + no bg + valid cron (non-trivial prompt + next-fire within threshold) -> ALLOW
# ===========================================================================
make_pending
run_case "3 pending+no-bg+valid-cron -> ALLOW" "ALLOW" \
    "$(cat <<EOF
{"hook_event_name":"Stop","session_id":"${SESSION_ID}","background_tasks":[],"session_crons":[{"id":"c1","schedule":"*/5 * * * *","recurring":true,"prompt":"Poll whether the build server finished deploying service X and notify user of result."}]}
EOF
)"

# ===========================================================================
# CASE 4: pending + no bg + cron next-fire BEYOND threshold -> BLOCK
# ===========================================================================
make_pending
# daily cron (86400s gap) > 3600s threshold => beyond threshold => BLOCK
run_case "4 pending+no-bg+cron-too-far(daily) -> BLOCK" "BLOCK" \
    "$(cat <<EOF
{"hook_event_name":"Stop","session_id":"${SESSION_ID}","background_tasks":[],"session_crons":[{"id":"c1","schedule":"0 9 * * *","recurring":true,"prompt":"Check daily whether the quarterly migration completed and notify the user."}]}
EOF
)"

# ===========================================================================
# CASE 5: pending + no bg + cron with empty/trivial prompt -> BLOCK
# ===========================================================================
make_pending
# valid schedule (*/5), but trivial prompt (<=10 chars) => not explainable => BLOCK
run_case "5 pending+no-bg+trivial-prompt-cron -> BLOCK" "BLOCK" \
    "$(cat <<EOF
{"hook_event_name":"Stop","session_id":"${SESSION_ID}","background_tasks":[],"session_crons":[{"id":"c1","schedule":"*/5 * * * *","recurring":true,"prompt":"continue"}]}
EOF
)"

# ===========================================================================
# CASE 6: stop_hook_active=true -> ALLOW (anti-loop, unconditional)
# ===========================================================================
make_pending
run_case "6 stop_hook_active=true -> ALLOW" "ALLOW" \
    "{\"hook_event_name\":\"Stop\",\"session_id\":\"${SESSION_ID}\",\"stop_hook_active\":true,\"background_tasks\":[],\"session_crons\":[]}"

# ===========================================================================
# CASE 7: pending + background_tasks non-empty -> ALLOW
# ===========================================================================
make_pending
run_case "7 pending+bg-non-empty -> ALLOW" "ALLOW" \
    "$(cat <<EOF
{"hook_event_name":"Stop","session_id":"${SESSION_ID}","background_tasks":[{"id":"b1","type":"shell","status":"running","description":"long deploy script"}],"session_crons":[]}
EOF
)"

# ===========================================================================
# CASE 8: background_tasks/session_crons fields ABSENT (old version) -> no crash
# ===========================================================================
make_pending
# No background_tasks, no session_crons, no stop_hook_active. Must not error.
out8=$(printf '{"hook_event_name":"Stop","session_id":"%s"}' "$SESSION_ID" | bash "$STOP_HOOK" 2>/tmp/stop-test-err8.$$)
rc8=$?
err8=$(cat /tmp/stop-test-err8.$$ 2>/dev/null; rm -f /tmp/stop-test-err8.$$)
if [ "$rc8" -eq 0 ] && [ -z "$err8" ]; then
    # Decision can be either ALLOW or BLOCK; the requirement is "does not crash"
    # (exit 0, no stderr). We assert the crash-freedom explicitly.
    if printf '%s' "$out8" | grep -qE '"decision"[[:space:]]*:[[:space:]]*"block"'; then
        printf 'PASS | %-58s -> BLOCK (no crash)\n' "8 fields-absent(old-ver) -> no-crash"
        PASS=$((PASS + 1))
    elif [ -z "$out8" ]; then
        printf 'PASS | %-58s -> ALLOW (no crash)\n' "8 fields-absent(old-ver) -> no-crash"
        PASS=$((PASS + 1))
    else
        printf 'FAIL | %-58s unexpected stdout: %s\n' "8 fields-absent(old-ver) -> no-crash" "$out8"
        FAIL=$((FAIL + 1))
        FAILURES="${FAILURES:+${FAILURES}; }case8"
    fi
else
    printf 'FAIL | %-58s crashed rc=%s err=%s\n' "8 fields-absent(old-ver) -> no-crash" "$rc8" "$err8"
    FAIL=$((FAIL + 1))
    FAILURES="${FAILURES:+${FAILURES}; }case8"
fi

# ===========================================================================
# CASE 9 (REGRESSION): pending + no bg + BARE-* cron schedule (* * * * *)
#   + non-trivial prompt -> ALLOW.
#   Guards finding 1: `set -- $expr` filename-globs bare `*`, so the canonical
#   "every minute" poll returned -1 and BLOCKed. MUST be ALLOW.
#   (Also exercises the `* 9 * * *` branch implicitly via the `*` hour glob.)
# ===========================================================================
make_pending
run_case "9 bare-* schedule (* * * * *) -> ALLOW" "ALLOW" \
    "$(cat <<EOF
{"hook_event_name":"Stop","session_id":"${SESSION_ID}","background_tasks":[],"session_crons":[{"id":"c1","schedule":"* * * * *","recurring":true,"prompt":"Poll every minute whether the deploy lock cleared and escalate to user if still held."}]}
EOF
)"

# ===========================================================================
# CASE 10 (REGRESSION): pending + no bg + SHORT/malformed cron schedule
#   (< 5 fields) -> exit 0 AND EMPTY stderr (BLOCK or ALLOW per logic is fine).
#   Guards finding 2: `local minute="$1" hour="$2" ...` under set -u leaked
#   "unbound variable" to stderr when set -- yielded <5 tokens.
# ===========================================================================
make_pending
out10=$(printf '{"hook_event_name":"Stop","session_id":"%s","background_tasks":[],"session_crons":[{"id":"c1","schedule":"onlymin","recurring":true,"prompt":"A sufficiently long explanatory prompt for the malformed-schedule regression case."}]}' "$SESSION_ID" | bash "$STOP_HOOK" 2>/tmp/stop-test-err10.$$)
rc10=$?
err10=$(cat /tmp/stop-test-err10.$$ 2>/dev/null; rm -f /tmp/stop-test-err10.$$)
label10="10 short-schedule(onlymin) -> no-crash,no-stderr"
if [ "$rc10" -eq 0 ] && [ -z "$err10" ]; then
    if printf '%s' "$out10" | grep -qE '"decision"[[:space:]]*:[[:space:]]*"block"'; then
        printf 'PASS | %-58s -> BLOCK (no crash, empty stderr)\n' "$label10"
        PASS=$((PASS + 1))
    elif [ -z "$out10" ]; then
        printf 'PASS | %-58s -> ALLOW (no crash, empty stderr)\n' "$label10"
        PASS=$((PASS + 1))
    else
        printf 'FAIL | %-58s unexpected stdout: %s\n' "$label10" "$out10"
        FAIL=$((FAIL + 1))
        FAILURES="${FAILURES:+${FAILURES}; }case10"
    fi
else
    printf 'FAIL | %-58s rc=%s err=%s\n' "$label10" "$rc10" "$err10"
    FAIL=$((FAIL + 1))
    FAILURES="${FAILURES:+${FAILURES}; }case10"
fi

# ===========================================================================
# CASE 11 (REGRESSION — round-2 false-allow closure): pending + no bg +
#   constrained cron `* 9 * * *` (every minute, ONLY during hour 9) +
#   non-trivial prompt -> BLOCK.
#   This was the round-2 ACCEPTED LIMITATION: minute `*` short-circuited and
#   returned 60s WITHOUT examining the non-`*` hour field, so the real ~23h
#   gap was hidden and the cron false-ALLOWed. The new GUARD (all of
#   hour/dom/month/dow must be `*` for minute-only bounding) now returns
#   BEYOND for any non-`*` non-minute field -> BLOCK. THE CORE FIX.
# ===========================================================================
make_pending
run_case "11 constrained(* 9 * * *) -> BLOCK" "BLOCK" \
    "$(cat <<EOF
{"hook_event_name":"Stop","session_id":"${SESSION_ID}","background_tasks":[],"session_crons":[{"id":"c1","schedule":"* 9 * * *","recurring":true,"prompt":"Poll whether the build server finished deploying service X and notify user of result."}]}
EOF
)"

# ===========================================================================
# CASE 12 (REGRESSION — reviewer repro): pending + no bg +
#   `*/30 9-17 * * 1-5` (every 30min during business hours weekdays) +
#   non-trivial prompt -> BLOCK.
#   Non-`*` hour (9-17) AND non-`*` dow (1-5) -> GUARD returns BEYOND -> BLOCK.
# ===========================================================================
make_pending
run_case "12 constrained(*/30 9-17 * * 1-5) -> BLOCK" "BLOCK" \
    "$(cat <<EOF
{"hook_event_name":"Stop","session_id":"${SESSION_ID}","background_tasks":[],"session_crons":[{"id":"c1","schedule":"*/30 9-17 * * 1-5","recurring":true,"prompt":"Poll whether the business-hours deploy finished and escalate to the on-call user if it stalled."}]}
EOF
)"

# ===========================================================================
# CASE 13 (REGRESSION — over-conservative documentation): pending + no bg +
#   `* */2 * * *` (every minute during every 2nd hour) + non-trivial prompt
#   -> BLOCK.
#   Non-`*` hour (`*/2`) -> GUARD returns BEYOND -> BLOCK. This is
#   DELIBERATELY over-conservative: minute-only math would say 60s, but the
#   real gap across the inactive hour is ~1h+, so blocking is safe. The
#   STRICTNESS NOTE in cron_gap_upper_bound_seconds documents why we do not
#   special-case `*/N` in non-minute fields.
# ===========================================================================
make_pending
run_case "13 constrained(* */2 * * *) -> BLOCK" "BLOCK" \
    "$(cat <<EOF
{"hook_event_name":"Stop","session_id":"${SESSION_ID}","background_tasks":[],"session_crons":[{"id":"c1","schedule":"* */2 * * *","recurring":true,"prompt":"Poll whether the bi-hourly sync checkpoint completed and notify the user of the result."}]}
EOF
)"

# ===========================================================================
# CASE 14 (REGRESSION — hourly poll ALLOW): pending + no bg +
#   `0 * * * *` (hourly at minute 0) + non-trivial prompt -> ALLOW.
#   minute `0` (single value), hour/dom/month/dow all `*` -> GUARD enters the
#   minute-only branch -> minute "anything else" -> 3600s. The threshold
#   comparison uses -le (<=), so gap==3600 with default threshold 3600 ->
#   ALLOW. Verifies the hourly-polling cadence the supervisory-polling skill
#   prescribes is admitted, AND that the comparison operator is <= (not <).
# ===========================================================================
make_pending
run_case "14 hourly(0 * * * *) gap==3600 -> ALLOW" "ALLOW" \
    "$(cat <<EOF
{"hook_event_name":"Stop","session_id":"${SESSION_ID}","background_tasks":[],"session_crons":[{"id":"c1","schedule":"0 * * * *","recurring":true,"prompt":"Poll hourly whether the long-running migration completed and escalate to the user on stall."}]}
EOF
)"

# ===========================================================================
# CASE 15 (REGRESSION — boundary value analysis): prompt length exactly 10 chars
#   (<=10) -> NOT explainable -> BLOCK. Guards the ${#cron_prompt} -le 10 edge
#   that the prior suite skirted (it used "continue"=8 and a long prompt, never
#   the exact 10/11 boundary).
# ===========================================================================
make_pending
run_case "15 prompt 10chars (boundary) -> BLOCK" "BLOCK" \
    "$(cat <<EOF
{"hook_event_name":"Stop","session_id":"${SESSION_ID}","background_tasks":[],"session_crons":[{"id":"c1","schedule":"*/5 * * * *","recurring":true,"prompt":"0123456789"}]}
EOF
)"

# ===========================================================================
# CASE 16 (REGRESSION — bias-to-block on malformed cron): non-numeric step base
#   "*/" (empty N) and "*/abc" -> BEYOND -> BLOCK. Guards the step-branch's
#   numeric guard, an uncertainty path the prior suite never exercised.
# ===========================================================================
make_pending
run_case "16 malformed step(*/) -> BLOCK" "BLOCK" \
    "$(cat <<EOF
{"hook_event_name":"Stop","session_id":"${SESSION_ID}","background_tasks":[],"session_crons":[{"id":"c1","schedule":"*/ * * * *","recurring":true,"prompt":"A sufficiently long explanatory prompt for the malformed-step regression case."}]}
EOF
)"

# ===========================================================================
# CASE 17 (REGRESSION — bias-to-block on bg field shape): background_tasks as
#   null (not an array) -> NOT "non-empty array" -> BLOCK. Guards the jq
#   `if type=="array"` check; ensures null/non-array cannot fake an ALLOW.
# ===========================================================================
make_pending
run_case "17 background_tasks null -> BLOCK" "BLOCK" \
    '{"hook_event_name":"Stop","session_id":"'${SESSION_ID}'","background_tasks":null,"session_crons":[]}'

# ===========================================================================
# CASE 18 (REGRESSION — dom/month/dow GUARD coverage): every non-minute
#   non-* field must BLOCK. Probe dom-constrained (* * 1 * *) and
#   month-constrained (* * * 2 *) — forms the prior suite's cases 11/12/13
#   (which only exercised hour and dow) did not directly hit.
# ===========================================================================
make_pending
run_case "18 dom-constrained(* * 1 * *) -> BLOCK" "BLOCK" \
    "$(cat <<EOF
{"hook_event_name":"Stop","session_id":"${SESSION_ID}","background_tasks":[],"session_crons":[{"id":"c1","schedule":"* * 1 * *","recurring":true,"prompt":"Poll whether the first-of-month reconciliation job completed and escalate to user."}]}
EOF
)"
make_pending
run_case "18b month-constrained(* * * 2 *) -> BLOCK" "BLOCK" \
    "$(cat <<EOF
{"hook_event_name":"Stop","session_id":"${SESSION_ID}","background_tasks":[],"session_crons":[{"id":"c1","schedule":"* * * 2 *","recurring":true,"prompt":"Poll whether the February close finished and escalate to the user on stall."}]}
EOF
)"

# ===========================================================================
# CASE 19 (REGRESSION — SECURITY: session_id path traversal): a traversal-shaped
#   session_id must NOT make count_pending_todos scan outside DEV_TEAM_TASKS_DIR.
#
#   Setup: plant a pending-looking task file in $TASKS_FIXTURE/.. (the parent of
#   the tasks dir). A session_id of ".." would, WITHOUT the guard, construct
#   "${TASKS_FIXTURE}/.." and scan the parent, counting the planted file and
#   reporting "Pending todos: 1" (confirmed repro pre-fix). With the guard the
#   session_id is rejected BEFORE any path is built, so:
#     - the planted file is NOT counted (no "Pending todos: 1");
#     - pending is treated as unknown -> the "0 -> ALLOW" early-exit is skipped;
#     - with no background task and no valid cron -> safe BLOCK;
#     - exit 0, empty stderr (no crash).
#
#   We assert BOTH the decision (BLOCK) and the negative evidence (the block
#   reason must NOT claim a count sourced from the planted file — it should say
#   "Pending todos: unknown", reflecting that the tasks dir was unreadable, not
#   that a real count of 1 was found by escaping the tasks dir).
#
#   We also probe the URL-encoded variant "..%2f.." to confirm the guard is not
#   naive about the literal `..` substring (it contains `..` -> rejected).
# ===========================================================================
TRAV_PARENT="$(dirname "$TASKS_FIXTURE")"
PLANTED_FILE="${TRAV_PARENT}/planted-traversal-task.json"
cat > "$PLANTED_FILE" <<'EOF'
{"id":"evil","subject":"planted outside tasks dir","status":"in_progress"}
EOF

# 19a: session_id = ".." -> reject, no traversal count, safe BLOCK.
out19a=$(printf '{"hook_event_name":"Stop","session_id":"..","background_tasks":[],"session_crons":[]}' | bash "$STOP_HOOK" 2>/tmp/stop-test-err19a.$$)
rc19a=$?
err19a=$(cat /tmp/stop-test-err19a.$$ 2>/dev/null; rm -f /tmp/stop-test-err19a.$$)
label19a="19a session_id='..' (traversal) -> no-scan, BLOCK"
if [ "$rc19a" -eq 0 ] && [ -z "$err19a" ] \
    && printf '%s' "$out19a" | grep -qE '"decision"[[:space:]]*:[[:space:]]*"block"' \
    && ! printf '%s' "$out19a" | grep -q 'Pending todos: 1' \
    && printf '%s' "$out19a" | grep -q 'Pending todos: unknown'; then
    printf 'PASS | %-58s -> BLOCK (pending=unknown, planted file not counted)\n' "$label19a"
    PASS=$((PASS + 1))
else
    printf 'FAIL | %-58s rc=%s err=%s\n' "$label19a" "$rc19a" "$err19a"
    [ -n "$out19a" ] && printf '     stdout: %s\n' "$out19a"
    FAIL=$((FAIL + 1))
    FAILURES="${FAILURES:+${FAILURES}; }case19a"
fi

# 19b: URL-encoded traversal variant "..%2f.." -> contains ".." -> rejected,
#   never scans out, safe BLOCK.
out19b=$(printf '{"hook_event_name":"Stop","session_id":"..%%2f..","background_tasks":[],"session_crons":[]}' | bash "$STOP_HOOK" 2>/tmp/stop-test-err19b.$$)
rc19b=$?
err19b=$(cat /tmp/stop-test-err19b.$$ 2>/dev/null; rm -f /tmp/stop-test-err19b.$$)
label19b="19b session_id='..%%2f..' (enc-traversal) -> no-scan, BLOCK"
if [ "$rc19b" -eq 0 ] && [ -z "$err19b" ] \
    && printf '%s' "$out19b" | grep -qE '"decision"[[:space:]]*:[[:space:]]*"block"' \
    && ! printf '%s' "$out19b" | grep -q 'Pending todos: 1'; then
    printf 'PASS | %-58s -> safe BLOCK (no traversal count)\n' "$label19b"
    PASS=$((PASS + 1))
else
    printf 'FAIL | %-58s rc=%s err=%s\n' "$label19b" "$rc19b" "$err19b"
    [ -n "$out19b" ] && printf '     stdout: %s\n' "$out19b"
    FAIL=$((FAIL + 1))
    FAILURES="${FAILURES:+${FAILURES}; }case19b"
fi

# 19c: a traversal session_id WITH a valid background task still ALLOWs (the
#   guard does not over-block when an independent resume signal exists).
out19c=$(printf '{"hook_event_name":"Stop","session_id":"..","background_tasks":[{"id":"b1","type":"shell","status":"running","description":"deploy"}],"session_crons":[]}' | bash "$STOP_HOOK" 2>/tmp/stop-test-err19c.$$)
rc19c=$?
err19c=$(cat /tmp/stop-test-err19c.$$ 2>/dev/null; rm -f /tmp/stop-test-err19c.$$)
label19c="19c session_id='..' + bg-task -> ALLOW (no traversal scan)"
if [ "$rc19c" -eq 0 ] && [ -z "$err19c" ] && [ -z "$out19c" ]; then
    printf 'PASS | %-58s -> ALLOW (bg-task; tasks dir not scanned)\n' "$label19c"
    PASS=$((PASS + 1))
else
    printf 'FAIL | %-58s rc=%s err=%s out=%s\n' "$label19c" "$rc19c" "$err19c" "$out19c"
    FAIL=$((FAIL + 1))
    FAILURES="${FAILURES:+${FAILURES}; }case19c"
fi

# Cleanup the planted file so it cannot leak into other cases or the summary.
rm -f "$PLANTED_FILE" 2>/dev/null || true

# ===========================================================================
# Summary + audit-log evidence
# ===========================================================================
echo "---"
echo "RESULT: ${PASS} passed, ${FAIL} failed"
if [ -n "$FAILURES" ]; then
    echo "FAILED CASES: ${FAILURES}"
fi
echo "---"
echo "Audit log (requirement E) at ${MARKER}/.dev-team-poll-blocks-${SUFFIX}.log :"
if [ -f "${MARKER}/.dev-team-poll-blocks-${SUFFIX}.log" ]; then
    cat "${MARKER}/.dev-team-poll-blocks-${SUFFIX}.log"
else
    echo "(no blocks were logged)"
fi

# Cleanup
rm -rf "$TASKS_FIXTURE" "$MARKER" 2>/dev/null || true

[ "$FAIL" -eq 0 ]
