"""The houses' cache (godot/scripts/lotes.gd), checked: three boots of the game, one building the town with no cache,
one building it and writing the cache, one reading it, and the three must leave the same town.

    python tools/cache_casas_check.py            headless (about 4 minutes)
    python tools/cache_casas_check.py --window   with the real renderer, for honest timings

Each boot prints (world.gd, --lotes-huella) a fingerprint of every merged mesh (name, turn, material, every byte), one
of what every house was left with (its own variables, how many children) and how many things the houses left with
the world. All three lines must be the same in the three boots; the third must say the cache was read.

Run it after touching casas.gd, casas_calles.gd or lotes.gd in any way that is more than a new house, and before a
release. The cache of this machine's own game (user://casas.cache) is rewritten by it: the next launch of the game
builds the town once more.

House rule that this guards: a house that is nothing but its pieces is not worked out at all when the cache is read
(casas.gd build). Its building may leave things only in its own variables, in its children, in world.hand_tags and
in MapData.outlines. Anything else it is ever made to leave somewhere must be added to `left` in casas.gd build, or
the real game (which reads the cache; the self-test does not) would lose it.
"""
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GODOT = "C:/Users/luis_/Fable/tools/godot/Godot_v4.7.2-stable_win64_console.exe"
RUNS = [("none", "--sin-cache-casas"), ("written", "--cache-casas"), ("read", "--cache-casas")]
WANT = ["the merged meshes' fingerprint", "the houses' own fingerprint"]


def godot_running() -> bool:
    out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq Godot*"], capture_output=True, text=True).stdout
    return "godot" in out.lower()


def boot(flag: str, log: Path, window: bool) -> str:
    while godot_running():
        time.sleep(10)
    cmd = [GODOT] + ([] if window else ["--headless"]) + ["--path", str(ROOT / "godot")]
    if window:
        cmd += ["--rendering-method", "mobile", "--resolution", "1280x720"]
    cmd += ["--", "--selftest", "--palabros", "--timing", "--lotes-huella", flag]
    with open(log, "w", encoding="utf-8", errors="replace") as f:
        subprocess.run(cmd, stdout=f, stderr=subprocess.STDOUT, timeout=900)
    return log.read_text(encoding="utf-8", errors="replace")


def main() -> int:
    window = "--window" in sys.argv
    logs = ROOT / "logs"
    logs.mkdir(exist_ok=True)
    got = []
    for name, flag in RUNS:
        text = boot(flag, logs / f"cache_casas_check_{name}.log", window)
        lines = {w: next((ln.strip() for ln in text.splitlines() if w in ln), "") for w in WANT}
        state = re.search(r"their cache: ([a-z]+)[^,]*, (\d+) MB, (\d+) ms, (\d+) houses not worked out", text)
        houses = re.search(r"boot: houses\s+(\d+) ms", text)
        got.append((name, lines, state, houses, "SCRIPT ERROR" in text or "Parse Error" in text))
        print("%-8s cache %-8s %4s MB  houses step %6s ms  %s houses not worked out" % (
            name, state.group(1) if state else "?", state.group(2) if state else "?", houses.group(1) if houses else "?",
            state.group(4) if state else "?"))
    bad = []
    for w in WANT:
        seen = {g[1][w] for g in got}
        if len(seen) != 1 or "" in seen:
            bad.append("%s differs:\n    %s" % (w, "\n    ".join("%s: %s" % (g[0], g[1][w] or "(none printed)") for g in got)))
    if any(g[4] for g in got):
        bad.append("script errors in a boot (see logs/cache_casas_check_*.log)")
    if not got[2][2] or got[2][2].group(1) != "read":
        bad.append("the third boot did not read the cache")
    if bad:
        print("CACHE CASAS FAILED\n  " + "\n  ".join(bad))
        return 1
    print("CACHE CASAS OK: the same town built, built and kept, and read back\n  " + "\n  ".join(got[0][1][w] for w in WANT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
