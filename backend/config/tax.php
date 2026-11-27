<?php

/*
|--------------------------------------------------------------------------
| Nepal income tax and TDS (FY 2083/84)
|--------------------------------------------------------------------------
|
| Every tax number lives here, so next year's budget is a one-file change.
| The results are estimates only, not tax advice.
|
*/

return [

    // 1 Shrawan 2083 to 32 Asar 2084.
    'fiscal_year' => [
        'label' => '2083/84',
        'start' => '2026-07-17',
        'end' => '2027-07-16',
    ],

    // Each slab is taxed at its rate up to `up_to` (null = no upper limit).
    'slabs' => [
        ['up_to' => 1000000, 'rate' => 0.01],
        ['up_to' => 1500000, 'rate' => 0.10],
        ['up_to' => 2500000, 'rate' => 0.20],
        ['up_to' => 4000000, 'rate' => 0.27],
        ['up_to' => null, 'rate' => 0.29],
    ],

    // The first (1%) slab is Social Security Tax, waived for SSF contributors.
    'ssf_waives_first_slab' => true,

    // TDS by income type. A null rate means the user types the TDS in (salary).
    // Final-withholding income is left out of taxable income.
    'tds_types' => [
        'salary' => ['label' => 'Salary', 'rate' => null, 'final' => false],
        'service_pan' => ['label' => 'Service fee · PAN only', 'rate' => 0.15, 'final' => false],
        'service_vat' => ['label' => 'Service fee · VAT bill', 'rate' => 0.015, 'final' => false],
        'rent' => ['label' => 'House rent', 'rate' => 0.10, 'final' => false],
        'interest' => ['label' => 'Bank interest', 'rate' => 0.06, 'final' => true],
        'dividend' => ['label' => 'Dividend', 'rate' => 0.05, 'final' => true],
    ],

];
