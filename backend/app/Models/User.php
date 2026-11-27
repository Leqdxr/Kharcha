<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password', 'monthly_budget', 'calendar', 'ssf_contributor', 'payment_methods'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    public const PAYMENT_METHODS = ['cash', 'esewa', 'khalti', 'bank_card', 'mobile_banking'];

    /**
     * Defaults for new users, so the API never returns null for these.
     *
     * @var array<string, mixed>
     */
    protected $attributes = [
        'calendar' => 'bs',
        'ssf_contributor' => false,
        'payment_methods' => '["cash","esewa","khalti","bank_card","mobile_banking"]',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'monthly_budget' => 'integer',
            'ssf_contributor' => 'boolean',
            'payment_methods' => 'array',
        ];
    }

    public function expenses(): HasMany
    {
        return $this->hasMany(Expense::class);
    }

    public function incomes(): HasMany
    {
        return $this->hasMany(Income::class);
    }
}
