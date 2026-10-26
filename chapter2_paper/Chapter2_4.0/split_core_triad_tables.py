# split_core_triad_tables.py
#
# Splits each binding IM-OLS table fragment into a _CORE and a _TRIAD variant.
#
#   _CORE  -> main text. Coefficients + the Vogelsang-Wagner Type 2 row placed
#             directly beneath the parameter estimates, per E15 section 4 as amended
#             by the VW_PROMOTION_TO_CORE event. No ADF, no Shin, no VIF, no bandwidth.
#   _TRIAD -> Appendix D. The full three-test triad plus collinearity diagnostics,
#             bandwidth ratios, and the E17 mandatory star-reversal warning.
#
# Source of truth is the existing fragment. This script never invents a number:
# every cell it writes is copied verbatim from the input. Where the VW row carries
# no significance stars -- which is currently true of every model in every table --
# the CORE footnote says so explicitly rather than letting a bare statistic read as
# though inference had been performed.
#
# Run from anywhere; paths are resolved relative to the repo root.

import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent

BINDING = {
    "US_Section31_IMOLS_Results": [
        "table_specA_set1_gva.tex",
        "table_specA_set1_nva.tex",
        "table_specA_set2_gva.tex",
        "table_specA_set2_nva.tex",
    ],
    "US_Section32_IMOLS_Results": [
        "table_specB_set1_gva.tex",
        "table_specB_set1_nva.tex",
        "table_specB_set2_gva.tex",
        "table_specB_set2_nva.tex",
    ],
    "Chile_Section33_Peripheral_IMOLS_Results": [
        "table_chile_threshold_imols.tex",
    ],
}

# Row-stub markers used to segment a fragment.
VIF_HEADER = r"\textbf{Collinearity Diagnostics (VIF)}"
TRIAD_HEADER = r"\textbf{Cointegration Test Triad}"
STEP_STUB = "Step Shifts"
ADF_STUB = "Resid. ADF"
SHIN_STUB = "Shin LM"
VW_STUB = "VW Type 2"
BANDWIDTH_STUB = "Bandwidth Ratio"
SAMPLE_STUB = "Sample Size"
THRESHOLD_STUB = "Optimal Threshold"


def segment(lines):
    """Split a table fragment into its structural parts."""
    parts = {
        "preamble": [],      # up to and including \toprule
        "depvar": None,
        "model": None,
        "coefs": [],
        "step": None,
        "vif": [],           # VIF header + VIF rows
        "adf": None,
        "shin": None,
        "vw": None,
        "threshold": None,
        "bandwidth": None,
        "sample": None,
        "footnote": None,
        "close": [],         # \end{tabular} \end{table}
    }

    i = 0
    # preamble through \toprule
    while i < len(lines):
        parts["preamble"].append(lines[i])
        if lines[i].strip() == r"\toprule":
            i += 1
            break
        i += 1

    # dependent-variable banner, then a \midrule
    while i < len(lines) and "Dependent Variable" not in lines[i]:
        i += 1
    parts["depvar"] = lines[i]
    i += 1
    while i < len(lines) and lines[i].strip() == r"\midrule":
        i += 1

    # model / parameter header row
    parts["model"] = lines[i]
    i += 1
    while i < len(lines) and lines[i].strip() == r"\midrule":
        i += 1

    # coefficient rows until Step Shifts
    while i < len(lines) and not lines[i].lstrip().startswith(STEP_STUB):
        parts["coefs"].append(lines[i])
        i += 1
    parts["step"] = lines[i]
    i += 1

    # remaining rows, classified by stub
    for line in lines[i:]:
        s = line.strip()
        if VIF_HEADER in line or s.startswith("VIF ("):
            parts["vif"].append(line)
        elif s.startswith(ADF_STUB):
            parts["adf"] = line
        elif s.startswith(SHIN_STUB):
            parts["shin"] = line
        elif s.startswith(VW_STUB):
            parts["vw"] = line
        elif s.startswith(THRESHOLD_STUB):
            parts["threshold"] = line
        elif s.startswith(BANDWIDTH_STUB):
            parts["bandwidth"] = line
        elif s.startswith(SAMPLE_STUB):
            parts["sample"] = line
        elif s.startswith(r"\multicolumn") and r"\footnotesize" in line:
            parts["footnote"] = line
        elif s.startswith(r"\end{tabular}") or s.startswith(r"\end{table}"):
            parts["close"].append(line)

    return parts


def retitle(preamble, caption_suffix, label_suffix):
    """Rewrite the caption and label of a preamble block."""
    out = []
    for line in preamble:
        if line.lstrip().startswith(r"\caption{") and caption_suffix:
            line = line.rstrip()
            assert line.endswith("}")
            line = line[:-1] + caption_suffix + "}"
        elif line.lstrip().startswith(r"\label{"):
            line = re.sub(r"\\label\{([^}]+)\}", r"\\label{\1" + label_suffix + "}", line)
        out.append(line)
    return out


def ncols(depvar_line):
    m = re.search(r"\\multicolumn\{(\d+)\}", depvar_line)
    return int(m.group(1))


def span(footnote_line):
    """Recover the p{Xcm} note width from the source footnote."""
    m = re.search(r"\\multicolumn\{\d+\}\{p\{([\d.]+)cm\}\}", footnote_line)
    return m.group(1) if m else "14.5"


def core_footnote(n, width, is_chile):
    estimator = (
        "Estimated via Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS "
        "(Vogelsang and Wagner 2014; Vogelsang et al.\\ 2024)"
    )
    scope = (
        "over 1920--2024 on aggregate Chilean real GDP ($y_t$)"
        if is_chile
        else "over 1929--2024"
    )
    return (
        f"\\multicolumn{{{n}}}{{p{{{width}cm}}}}{{\\footnotesize \\textbf{{Note:}} {estimator} "
        f"{scope}. Standard errors in parentheses. Coefficient significance "
        f"($^* p < 0.10$, $^{{**}} p < 0.05$, $^{{***}} p < 0.01$) is derived from a "
        f"100,000-pass Monte Carlo simulation of the exact DGP variant. "
        f"The Vogelsang--Wagner Type 2 statistic tests $H_0$: \\emph{{cointegration}}. "
        f"Its stars therefore run opposite to the coefficient rows: an \\textbf{{absence of "
        f"stars is the favourable result}}, indicating the null of cointegration is not "
        f"rejected. \\textbf{{[PENDING: the Type 2 statistics below have not yet been "
        f"evaluated against the fixed-$b$ critical values in "
        f"\\texttt{{codes/COMMON\\_VW\\_fixedb\\_critical\\_values.R}}, which are indexed by "
        f"each model's bandwidth ratio $b$ and stochastic regressor count $k$. They are "
        f"reported here without inference.]}} Residual ADF and Shin LM diagnostics, "
        f"collinearity statistics, and bandwidth ratios are reported in Appendix D. "
        f"All interaction terms are FWL-orthogonalized against base capital regressors"
        f"{'' if is_chile else ' and step dummies'}.}} \\\\"
    )


def triad_footnote(n, width, is_chile):
    return (
        f"\\multicolumn{{{n}}}{{p{{{width}cm}}}}{{\\footnotesize \\textbf{{Note:}} Full "
        f"cointegration diagnostics for the estimates reported in the main text. "
        f"\\textbf{{Star reversal warning:}} for the Residual ADF test, significance stars "
        f"indicate rejection of No Cointegration (supporting cointegration). For the Shin LM "
        f"test, significance stars indicate rejection of Cointegration (indicating spurious "
        f"regression). The Vogelsang--Wagner Type 2 test shares the Shin null "
        f"($H_0$: cointegration) and its stars read the same way. "
        f"Critical values: Residual ADF (MacKinnon 2010, Case 2, constant only, $m=4$) "
        f"$-3.81$ / $-4.10$ / $-4.64$ at 10\\% / 5\\% / 1\\%; Shin LM (Shin 1994, Table 1, "
        f"demeaned $C_\\mu$) $0.163$ / $0.221$ / $0.380$ for $k=2$ and $0.121$ / $0.159$ / "
        f"$0.271$ for $k=3$, where $k$ counts stochastic $I(1)$ regressors; "
        f"Vogelsang--Wagner Type 2 critical values are fixed-$b$ and jointly indexed by "
        f"$(b, k)$, so no single constant applies across models "
        f"\\textbf{{[PENDING: see the note to the corresponding main-text table]}}. "
        f"Bandwidth ratio $b$ is the model's HAC bandwidth divided by $T$.}} \\\\"
    )


def build(parts, is_chile):
    n = ncols(parts["depvar"])
    width = span(parts["footnote"]) if parts["footnote"] else "14.5"
    MID = r"\midrule"
    BOT = r"\bottomrule"

    core = []
    core += retitle(parts["preamble"], "", "_core")
    core += [parts["depvar"], MID, parts["model"], MID]
    core += parts["coefs"]
    core += [parts["step"], MID]
    # VW row promoted: sits directly beneath the parameter block.
    core += [parts["vw"], MID]
    if parts["threshold"]:
        core.append(parts["threshold"])
    core += [parts["sample"], BOT, core_footnote(n, width, is_chile)]
    core += parts["close"]

    triad = []
    triad += retitle(
        parts["preamble"],
        " --- Cointegration Diagnostics and Collinearity",
        "_triad",
    )
    triad += [parts["depvar"], MID, parts["model"], MID]
    triad += parts["vif"]
    triad += [MID, "\\multicolumn{%d}{l}{\\textbf{Cointegration Test Triad}} \\\\" % n]
    triad += [parts["adf"], parts["shin"], parts["vw"], MID]
    if parts["bandwidth"]:
        triad.append(parts["bandwidth"])
    triad += [parts["sample"], BOT, triad_footnote(n, width, is_chile)]
    triad += parts["close"]

    return core, triad


def main():
    reports = REPO_ROOT / "reports"
    written = 0
    for folder, files in BINDING.items():
        is_chile = folder.startswith("Chile")
        for fname in files:
            src = reports / folder / fname
            if not src.exists():
                print(f"  MISSING {src}")
                continue
            lines = src.read_text(encoding="utf-8").splitlines()
            parts = segment(lines)

            missing = [k for k in ("depvar", "model", "step", "vw", "sample") if not parts[k]]
            if missing:
                print(f"  SKIP {fname}: could not locate {missing}")
                continue

            core, triad = build(parts, is_chile)
            stem = fname[:-4]
            (reports / folder / f"{stem}_CORE.tex").write_text(
                "\n".join(core) + "\n", encoding="utf-8"
            )
            (reports / folder / f"{stem}_TRIAD.tex").write_text(
                "\n".join(triad) + "\n", encoding="utf-8"
            )
            written += 2
            print(f"  {stem} -> _CORE + _TRIAD")
    print(f"\nWrote {written} fragments.")


if __name__ == "__main__":
    main()
