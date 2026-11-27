<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SettingsTest extends TestCase
{
    use RefreshDatabase;

    public function test_new_user_gets_default_settings(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/user')
            ->assertOk()
            ->assertJsonPath('calendar', 'bs')
            ->assertJsonPath('ssf_contributor', false)
            ->assertJsonPath('fiscal_year_view', true)
            ->assertJsonPath('payment_methods', User::PAYMENT_METHODS);
    }

    public function test_user_can_update_all_settings(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->putJson('/api/settings', [
            'calendar' => 'ad',
            'ssf_contributor' => true,
            'fiscal_year_view' => false,
            'payment_methods' => ['cash', 'esewa'],
        ])->assertOk()
            ->assertJsonPath('calendar', 'ad')
            ->assertJsonPath('ssf_contributor', true)
            ->assertJsonPath('fiscal_year_view', false)
            ->assertJsonPath('payment_methods', ['cash', 'esewa']);

        $this->getJson('/api/user')->assertJsonPath('calendar', 'ad')->assertJsonPath('payment_methods', ['cash', 'esewa']);
    }

    public function test_fields_left_out_stay_the_same(): void
    {
        $user = User::factory()->create(['ssf_contributor' => true]);
        Sanctum::actingAs($user);

        $this->putJson('/api/settings', ['calendar' => 'ad'])
            ->assertOk()
            ->assertJsonPath('ssf_contributor', true)
            ->assertJsonPath('payment_methods', User::PAYMENT_METHODS);
    }

    public function test_settings_are_validated(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->putJson('/api/settings', [
            'calendar' => 'nepali',
            'ssf_contributor' => 'maybe',
            'fiscal_year_view' => 'sometimes',
            'payment_methods' => ['cash', 'paypal', 'cash'],
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['calendar', 'ssf_contributor', 'fiscal_year_view', 'payment_methods.1', 'payment_methods.2']);
    }

    public function test_settings_need_login(): void
    {
        $this->putJson('/api/settings', ['calendar' => 'ad'])->assertUnauthorized();
    }
}
