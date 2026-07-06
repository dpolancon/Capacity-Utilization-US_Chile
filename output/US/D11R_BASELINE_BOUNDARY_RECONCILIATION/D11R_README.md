# D11R Baseline Boundary Reconciliation

## Why D11R Was Needed

D11 correctly blocked D12 because it found total-capital variables carrying baseline authorization. D11R repairs that role leak in a documented downstream reconciliation layer.

## What D11 Blocked

D11 blocked on baseline boundary leakage. The target variables were G_TOT_GPIM_2017 and LOG_G_TOT_GPIM_2017.

## Where The Leak Was Found

The leak source ledger records every D10 and D11 occurrence of the target variables. The confirmed leak is BASELINE_AUTHORIZED metadata on total-capital variables.

## Reclassification

Both target variables are retained and reclassified as EXCLUDED_FROM_BASELINE with baseline_eligible=FALSE and d12_baseline_eligible=FALSE.

## Why The Variables Were Not Deleted

The problem is role authorization, not data corruption. Total-capital objects may remain as report, comparison, diagnostic, or excluded variables outside the baseline capital object.

## ME/NRC Baseline Protection

Baseline capacity capital remains K_capacity = K_ME + K_NRC. ME retains L=14 and alpha=1.7; NRC retains L=30 and alpha=1.6.

## q_omega Status

q_omega remains parked. D11R did not construct or promote a q_omega-family object.

## Validation Result

26/26 PASS

## Terminal Decision

AUTHORIZE_D12_BASELINE_ESTIMATION_DESIGN

## D12 Next Step

D12 is authorized for baseline estimation design, not for uncontrolled final estimation.
