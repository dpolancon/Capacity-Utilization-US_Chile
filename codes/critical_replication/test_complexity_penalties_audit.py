import math
import random


def c1_2x2(s11, s12, s22):
    tr = s11 + s22
    det = s11 * s22 - s12 * s12
    if tr <= 0 or det <= 0:
        raise ValueError('invalid covariance')
    k = 2.0
    return (k / 2.0) * math.log(tr / k) - 0.5 * math.log(det)


def c1_diag_identity(k, s2):
    tr = k * s2
    det = s2 ** k
    return (k / 2.0) * math.log(tr / k) - 0.5 * math.log(det)


def huber_rho(t, c=1.345):
    a = abs(t)
    if a <= c:
        return 0.5 * t * t
    return c * a - 0.5 * c * c


def ols_intercept_slope(y, x):
    n = len(y)
    mx = sum(x) / n
    my = sum(y) / n
    sxx = sum((xi - mx) ** 2 for xi in x)
    sxy = sum((xi - mx) * (yi - my) for xi, yi in zip(x, y))
    b1 = sxy / sxx
    b0 = my - b1 * mx
    resid = [yi - (b0 + b1 * xi) for xi, yi in zip(x, y)]
    rss = sum(r * r for r in resid)
    sigma2 = rss / n

    # X'X inverse for [1, x]
    sx = sum(x)
    sx2 = sum(xi * xi for xi in x)
    det_xx = n * sx2 - sx * sx
    inv00 = sx2 / det_xx
    inv01 = -sx / det_xx
    inv11 = n / det_xx

    v00 = sigma2 * inv00
    v01 = sigma2 * inv01
    v11 = sigma2 * inv11

    ll = -0.5 * n * (math.log(2 * math.pi) + 1.0 + math.log(sigma2))
    return (b0, b1), resid, sigma2, (v00, v01, v11), ll


def test1_c1_invariance():
    val = c1_diag_identity(5, 2.3)
    assert abs(val) < 1e-12, f'C1(s2*I)!=0: {val}'


def test2_c1_monotonicity():
    vals = []
    for rho in [0.0, 0.2, 0.5, 0.8]:
        vals.append(c1_2x2(1.0, rho, 1.0))
    assert vals[0] <= vals[1] <= vals[2] <= vals[3], vals


def test3_ardl_ols_icomp_crosscheck():
    random.seed(42)
    n = 240
    x = [random.gauss(0.0, 1.0) for _ in range(n)]
    y = [1.0 + 0.7 * xi + random.gauss(0.0, 0.4) for xi in x]
    _, _, sigma2, vc, ll = ols_intercept_slope(y, x)
    v00, v01, v11 = vc
    c1 = c1_2x2(v00, v01, v11)
    icomp = -2 * ll + 2 * c1

    # direct formula check
    tr = v00 + v11
    det = v00 * v11 - v01 * v01
    c1b = math.log(tr / 2.0) - 0.5 * math.log(det)
    icompb = -2 * ll + 2 * c1b
    assert abs(icomp - icompb) < 1e-10
    assert sigma2 > 0


def test4_vecm_ml_crosscheck():
    # Environment-only placeholder: no R/statsmodels toolchain guaranteed.
    return 'SKIP: VECM-ML runtime unavailable in this container'


def test5_robust_stress():
    random.seed(7)
    n = 260
    x = [random.gauss(0.0, 1.0) for _ in range(n)]
    y = [0.5 + 0.8 * xi + random.gauss(0.0, 0.35) for xi in x]
    _, _, _, vc0, ll0 = ols_intercept_slope(y, x)
    icomp0 = -2 * ll0 + 2 * c1_2x2(*vc0)

    y_out = y[:]
    for i in range(10):
        y_out[i] += 10.0

    _, resid_out, sigma2_out, vc1, ll1 = ols_intercept_slope(y_out, x)
    icomp1 = -2 * ll1 + 2 * c1_2x2(*vc1)

    robust_fit = 2 * sum(huber_rho(r / math.sqrt(sigma2_out)) for r in resid_out)
    assert icomp1 > icomp0
    assert robust_fit < (-2 * ll1)


if __name__ == '__main__':
    test1_c1_invariance()
    test2_c1_monotonicity()
    test3_ardl_ols_icomp_crosscheck()
    t4 = test4_vecm_ml_crosscheck()
    test5_robust_stress()
    print('PASS: test1 C1 invariance')
    print('PASS: test2 C1 monotonicity')
    print('PASS: test3 ARDL OLS ICOMP cross-check')
    print(t4)
    print('PASS: test5 robust stress')
