# S30G Financial-Claims Proxy Protocol

S30G constructs bounded financial-claims proxies from committed annual NFC accounting inputs.

The selected source is `NFC_NET_INT`, BEA NIPA Table 1.14 line 25, net interest and miscellaneous payments for nonfinancial corporate business.

The source passes the bounded proxy gate because the payer sector is NFC and the accounting position is explicitly net interest and miscellaneous payments. It does not pass the exact transfer gate because the recipient sector is not identified and actual and imputed components are not separated.

All constructed identities use annual inner alignment. No interpolation, backcasting, zero replacement, gap bridging, or endpoint extrapolation occurs.

The resulting variables are Shaikh-Tonak-inspired financial-claims proxies. They are not exact reproductions of Appendix 6.7 and do not equate operating surplus with profit after interest.
