<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BudgetTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_set_a_budget(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->putJson('/api/budget', ['monthly_budget' => 20000])
            ->assertOk()
            ->assertJsonPath('id', $user->id)
            ->assertJsonPath('monthly_budget', 20000);

        $this->assertSame(20000, $user->fresh()->monthly_budget);
    }

    public function test_sending_null_clears_the_budget(): void
    {
        $user = User::factory()->create(['monthly_budget' => 20000]);
        Sanctum::actingAs($user);

        $this->putJson('/api/budget', ['monthly_budget' => null])
            ->assertOk()
            ->assertJsonPath('monthly_budget', null);

        $this->assertNull($user->fresh()->monthly_budget);
    }

    public function test_budget_only_changes_the_logged_in_user(): void
    {
        $other = User::factory()->create(['monthly_budget' => 5000]);
        Sanctum::actingAs(User::factory()->create());

        $this->putJson('/api/budget', ['monthly_budget' => 100])->assertOk();

        $this->assertSame(5000, $other->fresh()->monthly_budget);
    }

    public function test_budget_validates_input(): void
    {
        Sanctum::actingAs(User::factory()->create(['monthly_budget' => 20000]));

        foreach ([[], ['monthly_budget' => -1], ['monthly_budget' => 100000001], ['monthly_budget' => 12.5], ['monthly_budget' => 'lots']] as $body) {
            $this->putJson('/api/budget', $body)
                ->assertUnprocessable()
                ->assertJsonValidationErrors('monthly_budget');
        }
    }
}
