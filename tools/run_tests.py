"""The self-test, run once and waited for: one call, a timeout, the whole log on disk, a short summary out.

    python tools/run_tests.py                     the full run (headless, ~12 min)
    python tools/run_tests.py sabotaje traza      one mode, with its extra flags (--selftest --sabotaje --traza)
    python tools/run_tests.py radio shots --window   a picture mode, in a window (1280x720)
    python tools/run_tests.py grua --repeat 3     the same mode three times (for intermittent failures)
    options: --timeout SECONDS (default 1500 for the full run, 600 for a mode), --window

The log goes to logs/selftest_<mode>_<time>.log. What is printed: the result line, how many checks passed, every
failing check, the script errors (each once), how long it took and where the log is. A parse error stops the run at
once (the game would otherwise sit at its title until the timeout). If another self-test is already running, it
says so before starting (two at once share user:// and slow each other: README, "Pruebas a la vez").
"""
import os
import queue
import re
import subprocess
import sys
import threading
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = "C:/Users/luis_/Fable/tools/godot/Godot_v4.7.2-stable_win64_console.exe"
LOGS = os.path.join(ROOT, "logs")


def others_running() -> bool:
    try:
        out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq Godot*", "/FO", "CSV", "/NH"], capture_output=True, text=True, timeout=20).stdout
        return "Godot" in out
    except Exception:
        return False


def run_once(modes: list, window: bool, timeout: float) -> int:
    name = re.sub(r"[^A-Za-z0-9_.-]+", "_", "_".join(modes))[:60] if modes else "full"     # (a vistas=a:x,z;... mode is no file name)
    os.makedirs(LOGS, exist_ok=True)
    log_path = os.path.join(LOGS, "selftest_%s_%s.log" % (name, time.strftime("%Y%m%d_%H%M%S")))
    args = [GODOT]
    args += ["--path", "godot", "--resolution", "1280x720"] if window else ["--headless", "--path", "godot", "--fixed-fps", "60"]
    args += ["--", "--selftest"] + ["--" + m for m in modes] + (["--window"] if window else [])
    if others_running():
        print("note: another Godot is running (a test of another session, or the game): results may be slower or mixed")
    start = time.time()
    fails, errors, result, oks, parse_error = [], [], "", 0, False
    with open(log_path, "w", encoding="utf-8", errors="replace", buffering=1) as log:
        proc = subprocess.Popen(args, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace")
        lines = queue.Queue()

        def read() -> None:
            # (in a thread of its own: a Godot that hangs without printing anything would otherwise never let the
            # timeout be looked at)
            for l in proc.stdout:
                lines.put(l)
            lines.put(None)

        threading.Thread(target=read, daemon=True).start()
        try:
            while True:
                if time.time() - start > timeout:
                    break
                try:
                    line = lines.get(timeout=1.0)
                except queue.Empty:
                    continue
                if line is None:
                    break
                log.write(line)
                s = line.rstrip()
                if s.startswith("  ok"):
                    oks += 1
                elif s.startswith("  FAIL"):
                    fails.append(s.strip())
                elif "SCRIPT ERROR" in s:
                    if s not in errors:
                        errors.append(s)
                    if "Parse Error" in s:
                        parse_error = True
                        break
                elif (" OK (" in s or " FAILED (" in s) and s.split(" ")[0].isupper():
                    result = s
        finally:
            if proc.poll() is None:
                # (our own child, and whatever it started: the console Godot starts the game itself)
                subprocess.run(["taskkill", "/T", "/F", "/PID", str(proc.pid)], capture_output=True)
            proc.wait()
    took = time.time() - start
    if parse_error:
        result = "PARSE ERROR: stopped at once"
    elif not result:
        result = "NO RESULT (timeout after %.0f s, or the run stopped)" % took
    print("%s  |  %d ok, %d failed  |  %.0f s  |  %s" % (result, oks, len(fails), took, os.path.relpath(log_path, ROOT)))
    for f in fails:
        print("  " + f[:400])
    for e in errors[:10]:
        print("  " + e[:300])
    if len(errors) > 10:
        print("  (%d more script errors in the log)" % (len(errors) - 10))
    return 0 if (not fails and not errors and " OK (" in result) else 1


def main() -> int:
    argv = sys.argv[1:]
    if "-h" in argv or "--help" in argv:
        print(__doc__)
        return 0
    window = "--window" in argv
    repeat = 1
    timeout = None
    modes = []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--window":
            pass
        elif a == "--repeat":
            repeat = int(argv[i + 1]); i += 1
        elif a == "--timeout":
            timeout = float(argv[i + 1]); i += 1
        else:
            modes.append(a.lstrip("-"))
        i += 1
    if modes:                                    # (a mode the self-test does not know runs the whole of it instead: say so)
        main_mode = modes[0].split("=")[0]
        with open(os.path.join(ROOT, "godot", "scripts", "selftest.gd"), encoding="utf-8") as f:
            src = f.read()
        if '"--%s"' % main_mode not in src and '"--%s=' % main_mode not in src:
            print('unknown mode "%s": selftest.gd has no "--%s" (see the has("--...") lines in _run)' % (main_mode, main_mode))
            return 2
    if timeout is None:
        timeout = 600.0 if modes else 1500.0
    worst = 0
    for k in range(repeat):
        if repeat > 1:
            print("[%d/%d] " % (k + 1, repeat), end="")
        worst = max(worst, run_once(modes, window, timeout))
    return worst


if __name__ == "__main__":
    sys.exit(main())
