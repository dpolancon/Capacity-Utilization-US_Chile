"""Check mu_CL against regime classification and theta_CL behavior."""
import pandas as pd

REPO = "C:/ReposGitHub/Capacity-Utilization-US_Chile"
panel = pd.read_csv(f"{REPO}/output/stage_a/Chile/csv/stage2_panel_with_mu_v2.csv")
regime = pd.read_csv(f"{REPO}/output/stage_a/Chile/csv/stage2_regime_classification.csv")

panel = panel.merge(regime[["year", "R_t", "regime"]], on="year", how="left")

# Neoliberal breakdown
print("=== Neoliberal sub-periods ===\n")
for label, yr1, yr2 in [("Chicago (1975-81)", 1975, 1981),
                          ("Debt crisis (1982-85)", 1982, 1985),
                          ("Recovery (1986-96)", 1986, 1996),
                          ("Late neolib (1997-2024)", 1997, 2024)]:
    mask = (panel["year"] >= yr1) & (panel["year"] <= yr2)
    sub = panel.loc[mask]
    n_binding = sub["R_t"].sum() if "R_t" in sub else 0
    n_total = len(sub.dropna(subset=["R_t"]))
    print(f"{label}:")
    print(f"  theta_CL: {sub['theta_CL'].mean():.4f}  mu_CL: {sub['mu_CL'].mean():.4f}")
    print(f"  g_Y: {sub['g_Y'].mean():.4f}  g_Yp: {sub['g_Yp'].mean():.4f}  g_mu: {sub['g_mu'].mean():.4f}")
    print(f"  Regime 2 (binding): {n_binding}/{n_total}")
    print()

# Year-by-year neoliberal
print("=== Year-by-year 1975-2024 ===")
print(f"{'year':>4} {'mu_CL':>7} {'theta':>7} {'g_Y':>7} {'g_Yp':>7} {'g_mu':>7} {'R_t':>4} {'s_ME':>6}")
for _, r in panel.loc[panel["year"].between(1975, 2024)].iterrows():
    rt = int(r["R_t"]) if pd.notna(r.get("R_t")) else -1
    print(f"{int(r['year']):>4} {r['mu_CL']:>7.4f} {r['theta_CL']:>7.4f} "
          f"{r['g_Y']:>7.4f} {r['g_Yp']:>7.4f} {r['g_mu']:>7.4f} {rt:>4} {r['s_ME']:>6.4f}")

# Key diagnostic: where does mu cross 1.0?
cross = panel.loc[(panel["mu_CL"] > 1.0) & (panel["year"] > 1982)]
if not cross.empty:
    print(f"\nmu_CL first exceeds 1.0 in: {int(cross['year'].iloc[0])}")
    print(f"mu_CL at 2024: {panel.loc[panel['year']==2024, 'mu_CL'].values[0]:.4f}")
