from __future__ import annotations

from s34r_common import run_py


for script in [
    "00_discover_inputs.py",
    "01_repair_capital_base.py",
    "02_rebuild_q_paths.py",
    "03_rerun_integration_order.py",
    "04_design_diagnostics.py",
    "05_residual_cointegration_gate.py",
    "06_s35_unblock_decision.py",
]:
    print(f"Running {script}")
    run_py(script)

