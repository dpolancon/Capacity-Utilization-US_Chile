
Is not possible to  justify the claim that the rate of exploitation remains unchanged when the organic composition of capital increases.

There are at least two possible questions that arise with respect to this celebrated argument of Marx. 
	 + _First: can we justify the assumption that the rate of exploitation remains unchanged even as the organic composition of capital increases exogenously?_
	 +_Second: can we oqer a convincing explanation of why the organic composition of capital must rise over time?_


# Basu's Propositions 

## Proposition 1 

 Let Q denote the organic composition of capital. If the elasticity of the rate of exploitation with respect to the organic composition of capital is less than Q/ (1+ Q), then any increase in the organic composition will lead to a fall in the rate of profit.

## Proposition 2

Let β1 and β2 denote the rates of growth of labor productivity and capital productivity (the output- capital ratio), respectively, which is associated with a new technique of production; and let γ denote the organic composition of capital of the new technique of production evaluated at prices that prevailed prior to the economywide adoption of the new technique of production. In such a setting, we can deCne a Marx- Okishio threshold as follows: α* = β1 + γβ2 . 

Using the threshold, we have:  
	+ Marx’s Result: If the actual growth rate of the real wage rate is higher than α*, then the average rate of $\alpha$ falls axer the adoption of the new technique of production; 
	+ Okishio’s Result: If the actual growth rate of the real wage rate is lower than α*, then the average rate of proCt rises axer the adoption of the new technique of production



# Notebook — Rewriting Basu’s Marx–Okishio Threshold in Terms of Mechanization Growth

## Purpose

This notebook starts from Deepankar Basu’s Appendix A proof of the Marx–Okishio threshold and extends it with a new notation that expresses the threshold as a function of the growth rate of mechanization. The final result is a compact exact re-expression of the threshold in terms of:

- capital-productivity growth,
- mechanization growth, and
- a stricter elasticity-like object linking the two.

The Basu starting point comes from Appendix A, pages 22–24 of the uploaded PDF. In Basu’s one-good corn model, the technique is given by $ (a,n) $, where $a$ is corn input per unit of output and $n$ is labor input per unit of output. The real wage is $b = w/p$. Basu writes the pre-adoption profit rate as

$$
r = \frac{1}{a+bn}-1,
$$

and the post-adoption profit rate, after economy-wide diffusion of the new technique $ (a',n') $, as

$$
r'' = \frac{1}{a' + \delta b n'} - 1,
$$

where $\delta b$ is the new real wage and $\alpha = \delta - 1$ is the growth rate of the real wage. Setting $r'' = r$ yields Basu’s threshold. See Appendix A, especially the derivation of $\delta^*$ and $\alpha^*$ on pp. 23–24 of the PDF.

---

## 1. Basu’s original threshold

Basu shows that the threshold value of real-wage growth is

$$
\alpha^* = \beta_1 + \gamma \beta_2,
$$

where

$$
1+\beta_1 = \frac{n}{n'},
\qquad
1+\beta_2 = \frac{a}{a'},
\qquad
\gamma = \frac{pa'}{wn'} = \frac{a'}{bn'}.
$$

Interpretation:

- $\beta_1$ is the discrete growth rate of labor productivity,
- $\beta_2$ is the discrete growth rate of capital productivity,
- $\gamma$ is the organic composition of capital of the **new** technique, evaluated at **pre-adoption** prices.

So the exact Basu threshold is

$$
\boxed{\alpha^* = \beta_1 + \gamma \beta_2.}
$$

---

## 2. Introduce mechanization

Define mechanization as

$$
m \equiv \frac{a}{n} = \frac{K}{L}.
$$

Under the new technique,

$$
m' \equiv \frac{a'}{n'}.
$$

Now define the **growth rate of mechanization** as

$$
\beta_3 \equiv \frac{m'}{m} - 1.
$$

Hence,

$$
1+\beta_3 = \frac{m'}{m} = \frac{a'/n'}{a/n}.
$$

This is the exact discrete mechanization-growth factor.

---

## 3. Exact identity linking productivity and mechanization

Since

$$
\frac{Y}{K} = \frac{Y/L}{K/L},
$$

capital productivity equals labor productivity divided by mechanization. In Basu’s coefficient notation,

$$
\frac{1}{a} = \frac{1/n}{a/n}.
$$

Therefore, in exact discrete factor form,

$$
1+\beta_2 = \frac{1+\beta_1}{1+\beta_3}.
$$

Equivalently,

$$
1+\beta_1 = (1+\beta_2)(1+\beta_3).
$$

Subtracting 1 from both sides gives

$$
\boxed{\beta_1 = \beta_2 + \beta_3 + \beta_2\beta_3.}
$$

This is the exact discrete decomposition of labor-productivity growth into capital-productivity growth, mechanization growth, and their interaction.

---

## 4. Rewriting the Marx–Okishio threshold

Start from Basu:

$$
\alpha^* = \beta_1 + \gamma \beta_2.
$$

Substitute

$$
\beta_1 = \beta_2 + \beta_3 + \beta_2\beta_3.
$$

Then

$$
\alpha^* = (\beta_2 + \beta_3 + \beta_2\beta_3) + \gamma \beta_2.
$$

Collect terms in $\beta_2$:

$$
\alpha^* = \beta_3 + \beta_2(1 + \gamma + \beta_3).
$$

So the exact mechanization-based rewrite is

$$
\boxed{\alpha^* = \beta_3 + \beta_2(1 + \gamma + \beta_3).}
$$

Equivalent forms are

$$
\boxed{\alpha^* = \beta_2(1+\gamma) + \beta_3(1+\beta_2),}
$$

and

$$
\boxed{\alpha^* - \beta_3 = \beta_2(1+\gamma+\beta_3).}
$$

---

## 5. Ratio form

Define the ratio

$$
\rho_{23} \equiv \frac{\beta_2}{\beta_3},
\qquad \beta_3 \neq 0.
$$

Then the threshold becomes

$$
\alpha^* = \beta_3\left[1 + \rho_{23}(1+\gamma+\beta_3)\right].
$$

That is,

$$
\boxed{\alpha^* = \beta_3\left[1 + \rho_{23}(1+\gamma+\beta_3)\right].}
$$

This is algebraically clean, but $\rho_{23}$ is best interpreted as a **relative growth ratio**, not as a strict elasticity.

---

## 6. A stricter elasticity-style formulation

To obtain something closer to a genuine elasticity, define

$$
\varepsilon_{23} \equiv \frac{\ln(1+\beta_2)}{\ln(1+\beta_3)},
\qquad 1+\beta_3 > 0,
\qquad \beta_3 \neq 0.
$$

Then

$$
1+\beta_2 = (1+\beta_3)^{\varepsilon_{23}}.
$$

Hence

$$
\beta_2 = (1+\beta_3)^{\varepsilon_{23}} - 1.
$$

Substitute this into the exact threshold:

$$
\alpha^* = \beta_3 + \left[(1+\beta_3)^{\varepsilon_{23}} - 1\right](1+\gamma+\beta_3).
$$

So the threshold expressed entirely as a function of mechanization growth and the productivity–mechanization elasticity is

$$
\boxed{
\alpha^* = \beta_3 + \Big[(1+\beta_3)^{\varepsilon_{23}} - 1\Big](1+\gamma+\beta_3).
}
$$

This is the cleanest exact form when the goal is to express everything in terms of mechanization growth.

---

## 7. Proposition and proof

### Proposition

Let Basu’s Marx–Okishio threshold be given by

$$
\alpha^* = \beta_1 + \gamma\beta_2,
$$

where

$$
1+\beta_1 = \frac{n}{n'},
\qquad
1+\beta_2 = \frac{a}{a'},
\qquad
\gamma = \frac{pa'}{wn'}.
$$

Define mechanization by

$$
m = \frac{a}{n},
\qquad
1+\beta_3 = \frac{m'}{m},
$$

and define the productivity–mechanization elasticity by

$$
\varepsilon_{23} = \frac{\ln(1+\beta_2)}{\ln(1+\beta_3)}.
$$

Then the Marx–Okishio threshold can be written as

$$
\boxed{
\alpha^* = \beta_3 + \Big[(1+\beta_3)^{\varepsilon_{23}} - 1\Big](1+\gamma+\beta_3).
}
$$

### Proof

By definition of mechanization,

$$
1+\beta_3 = \frac{m'}{m} = \frac{a'/n'}{a/n}.
$$

Since

$$
1+\beta_1 = \frac{n}{n'},
\qquad
1+\beta_2 = \frac{a}{a'},
$$

we have

$$
1+\beta_2 = \frac{a}{a'} = \frac{n/n'}{(a'/n')/(a/n)} = \frac{1+\beta_1}{1+\beta_3}.
$$

Therefore,

$$
1+\beta_1 = (1+\beta_2)(1+\beta_3),
$$

so

$$
\beta_1 = \beta_2 + \beta_3 + \beta_2\beta_3.
$$

Substituting into Basu’s threshold,

$$
\alpha^* = \beta_1 + \gamma\beta_2 = \beta_3 + \beta_2(1+\gamma+\beta_3).
$$

Now define

$$
\varepsilon_{23} = \frac{\ln(1+\beta_2)}{\ln(1+\beta_3)}.
$$

Then

$$
1+\beta_2 = (1+\beta_3)^{\varepsilon_{23}},
$$

hence

$$
\beta_2 = (1+\beta_3)^{\varepsilon_{23}} - 1.
$$

Substituting again,

$$
\alpha^* = \beta_3 + \Big[(1+\beta_3)^{\varepsilon_{23}} - 1\Big](1+\gamma+\beta_3).
$$

This proves the result.

---

## 8. Interpretation

This reformulation delivers three gains.

First, it separates **technical deepening** from **productivity effects**. In the rewritten threshold, $\beta_3$ captures the growth of mechanization directly, while the second term captures the capital-productivity response to mechanization.

Second, it preserves Basu’s exact discrete structure. No log-linear approximation is required to obtain the result.

Third, it highlights the role of $\gamma$ as an ex ante valuation term: the new technique’s organic composition evaluated at pre-adoption prices. Thus the threshold depends jointly on technical change, mechanization, and the valuation-weighted capital intensity of the new technique.

---

## 9. Compact summary of the main formulas

Baseline Basu threshold:

$$
\alpha^* = \beta_1 + \gamma\beta_2.
$$

Mechanization-growth definition:

$$
1+\beta_3 = \frac{m'}{m},
\qquad m = \frac{a}{n} = \frac{K}{L}.
$$

Exact link:

$$
1+\beta_2 = \frac{1+\beta_1}{1+\beta_3}.
$$

Equivalent labor-productivity decomposition:

$$
\beta_1 = \beta_2 + \beta_3 + \beta_2\beta_3.
$$

Mechanization rewrite of the threshold:

$$
\alpha^* = \beta_3 + \beta_2(1+\gamma+\beta_3).
$$

Elasticity-style rewrite:

$$
\varepsilon_{23} = \frac{\ln(1+\beta_2)}{\ln(1+\beta_3)},
\qquad
\alpha^* = \beta_3 + \Big[(1+\beta_3)^{\varepsilon_{23}} - 1\Big](1+\gamma+\beta_3).
$$

