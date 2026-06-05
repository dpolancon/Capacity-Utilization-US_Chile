"""Compare old vs new mu_CL series."""
import pandas as pd

REPO = "C:/ReposGitHub/Capacity-Utilization-US_Chile"
CSV = f"{REPO}/output/stage_a/Chile/csv"

old = pd.read_csv(f"{CSV}/stage2_theta_mu_panel.csv")
new = pd.read_csv(f"{CSV}/stage2_panel_with_mu_v2.csv")

print("=== OLD panel (stage2_theta_mu_panel.csv) ===")
print(f"Columns: {list(old.columns)}")
print(f"Years: {old['year'].min()}-{old['year'].max()} (N={len(old)})")
print()

print("=== SIDE-BY-SIDE: theta_CL and mu_CL ===")
print(f"{'year':>4} {'old_theta':>10} {'new_theta':>10} {'old_mu':>8} {'new_mu':>8} {'old_g_Yp':>9} {'new_g_Yp':>9}")
print("-" * 70)

merged = old[["year","theta_CL","mu_CL","g_Yp"]].merge(
    new[["year","theta_CL","mu_CL","g_Yp","s_ME"]], on="year", suffixes=("_old","_new"))

for _, r in merged.iterrows():
    yr = int(r["year"])
    if yr in list(range(1940,1973)) + list(range(1975,1986)) + list(range(1995,2025)):
        print(f"{yr:>4} {r['theta_CL_old']:>10.4f} {r['theta_CL_new']:>10.4f} "
              f"{r['mu_CL_old']:>8.4f} {r['mu_CL_new']:>8.4f} "
              f"{r['g_Yp_old']:>9.4f} {r['g_Yp_new']:>9.4f}")

print()
print("=== PERIOD AVERAGES ===")
for label, yr1, yr2 in [("ISI (1940-72)", 1940, 1972),
                          ("Crisis (1973-82)", 1973, 1982),
                          ("Recovery (1986-96)", 1986, 1996),
                          ("Late neolib (1997-24)", 1997, 2024)]:
    mask = (merged["year"] >= yr1) & (merged["year"] <= yr2)
    sub = merged.loc[mask]
    print(f"{label}:")
    print(f"  theta_CL: old={sub['theta_CL_old'].mean():.4f}  new={sub['theta_CL_new'].mean():.4f}")
    print(f"  mu_CL:    old={sub['mu_CL_old'].mean():.4f}  new={sub['mu_CL_new'].mean():.4f}")
    print(f"  g_Yp:     old={sub['g_Yp_old'].mean():.4f}  new={sub['g_Yp_new'].mean():.4f}")
    print()

# Check what specification the old panel used
print("=== OLD panel extra columns ===")
print(f"Has 'lphi': {'lphi' in old.columns}")
print(f"Has 'regime': {'regime' in old.columns}")
if 'lphi' in old.columns:
    print(f"lphi range: [{old['lphi'].min():.4f}, {old['lphi'].max():.4f}]")
if 'phi' in old.columns:
    print(f"phi range: [{old['phi'].min():.4f}, {old['phi'].max():.4f}]")
print()

# The key: what was g_Yp computed from in the old version?
print("=== OLD g_Yp decomposition check ===")
print(f"Old columns: {list(old.columns)}")
# g_Yp_old uses g_kNR and g_lphi — the split-sample frontier approach
if 'g_kNR' in old.columns and 'g_lphi' in old.columns:
    print("Old used: g_kNR, g_lphi (split-sample frontier with lphi=log(K_ME/K_NR))")
    print(f"g_kNR mean: {old['g_kNR'].mean():.4f}")
    print(f"g_lphi mean: {old['g_lphi'].mean():.4f}")
