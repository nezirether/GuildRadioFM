import os
from pathlib import Path

from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
toc = (root / "GuildRadioFM.toc").read_text(encoding="utf-8-sig").splitlines()
assert "## Interface: 16001" in toc
modules = [root / line.strip() for line in toc if line.strip().endswith(".lua")]
suites = sorted((root / "tests").glob("*.lua"))
compiler = LuaRuntime().eval("function(source, name) assert(loadstring(source, name)) end")
for path in modules + suites:
    compiler(path.read_text(encoding="utf-8-sig"), "@" + str(path.relative_to(root)))
print(f"PASS: Lua 5.1 syntax for {len(modules)} TOC modules and {len(suites)} suites", flush=True)

os.chdir(root)
for suite in suites:
    LuaRuntime().execute(suite.read_text(encoding="utf-8-sig"))
