<?php

namespace App\Services;

use App\Models\User;

/**
 * Estimates a user's income tax and TDS for the fiscal year in config/tax.php.
 */
class TaxEstimator
{
    public function estimate(User $user): array
    {
        $fy = config('tax.fiscal_year');
        $types = config('tax.tds_types');

        $incomes = $user->incomes()->whereBetween('date', [$fy['start'], $fy['end']])->get();

        $salary = $incomes->where('type', 'salary');
        $final = $incomes->filter(fn ($income) => $types[$income->type]['final'] ?? false);
        $nonFinal = $incomes->diff($final)->diff($salary);

        // Average per month that has a salary entry, projected over 12 months.
        $salaryMonths = $salary->map(fn ($income) => $income->date->format('Y-m'))->unique()->count();
        $projectedSalary = $salaryMonths ? $salary->sum('amount') / $salaryMonths * 12 : 0;
        $projectedSalaryTds = $salaryMonths ? $salary->sum('tds_amount') / $salaryMonths * 12 : 0;

        $taxableIncome = $projectedSalary + $nonFinal->sum('amount');
        $slabs = $this->slabs($taxableIncome, $user->ssf_contributor);
        $tax = array_sum(array_column($slabs, 'tax'));
        $adjustableTds = $projectedSalaryTds + $nonFinal->sum('tds_amount');

        return [
            'fiscal_year' => $fy,
            'types' => $types,
            'ssf_contributor' => $user->ssf_contributor,
            'totals' => [
                'gross' => $this->money($incomes->sum('amount')),
                'tds' => $this->money($incomes->sum('tds_amount')),
                'received' => $this->money($incomes->sum('amount') - $incomes->sum('tds_amount')),
                'salary' => $this->money($salary->sum('amount')),
                'salary_tds' => $this->money($salary->sum('tds_amount')),
                'salary_months' => $salaryMonths,
                'other' => $this->money($nonFinal->sum('amount')),
                'other_tds' => $this->money($nonFinal->sum('tds_amount')),
                'final' => $this->money($final->sum('amount')),
            ],
            'projected_salary' => $this->money($projectedSalary),
            'taxable_income' => $this->money($taxableIncome),
            'slabs' => $slabs,
            'estimated_tax' => $this->money($tax),
            'effective_rate' => $taxableIncome > 0 ? round($tax / $taxableIncome * 100, 2) : 0,
            'tds_so_far' => $this->money($salary->sum('tds_amount') + $nonFinal->sum('tds_amount')),
            'final_tds' => $this->money($final->sum('tds_amount')),
            'adjustable_tds_year_end' => $this->money($adjustableTds),
            'result' => $this->money($adjustableTds - $tax),
        ];
    }

    /**
     * Split the income across the slabs and tax each part.
     */
    private function slabs(float $income, bool $ssfContributor): array
    {
        $rows = [];
        $from = 0;

        foreach (config('tax.slabs') as $index => $slab) {
            $to = $slab['up_to'];
            $taxable = max(0, min($income, $to ?? $income) - $from);
            $waived = $index === 0 && $ssfContributor && config('tax.ssf_waives_first_slab');

            $rows[] = [
                'from' => $from,
                'to' => $to,
                'rate' => $slab['rate'],
                'taxable' => $this->money($taxable),
                'tax' => $waived ? 0.0 : $this->money($taxable * $slab['rate']),
                'waived' => $waived,
            ];

            if ($to === null) {
                break;
            }
            $from = $to;
        }

        return $rows;
    }

    private function money(float $amount): float
    {
        return round($amount, 2);
    }
}
