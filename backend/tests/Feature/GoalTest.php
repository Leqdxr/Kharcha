<?php

namespace Tests\Feature;

use App\Models\Goal;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class GoalTest extends TestCase
{
    use RefreshDatabase;

    private function goalFor(User $user, array $attributes = []): Goal
    {
        return $user->goals()->create($attributes + ['name' => 'Laptop', 'target' => 120000]);
    }

    public function test_user_can_create_a_goal(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/goals', [
            'name' => 'Dashain trip',
            'target' => 40000,
            'target_date' => '2027-10-01',
            'note' => 'Pokhara',
        ])->assertCreated()
            ->assertJsonPath('name', 'Dashain trip')
            ->assertJsonPath('saved', 0)
            ->assertJsonPath('target_date', '2027-10-01');
    }

    public function test_list_update_and_delete_own_goals(): void
    {
        $user = User::factory()->create();
        $goal = $this->goalFor($user);
        $this->goalFor(User::factory()->create());
        Sanctum::actingAs($user);

        $this->getJson('/api/goals')->assertOk()->assertJsonCount(1)->assertJsonPath('0.id', $goal->id);

        $this->putJson("/api/goals/{$goal->id}", [
            'name' => 'New laptop',
            'target' => 150000,
            'saved' => 20000,
            'target_date' => null,
        ])->assertOk()->assertJsonPath('target', 150000)->assertJsonPath('saved', 20000);

        $this->deleteJson("/api/goals/{$goal->id}")->assertNoContent();
        $this->assertDatabaseMissing('goals', ['id' => $goal->id]);
    }

    public function test_deposit_adds_to_saved_and_is_not_an_expense(): void
    {
        $user = User::factory()->create();
        $goal = $this->goalFor($user, ['saved' => 1000]);
        Sanctum::actingAs($user);

        $this->postJson("/api/goals/{$goal->id}/deposit", ['amount' => 500])->assertOk()->assertJsonPath('saved', 1500);
        $this->postJson("/api/goals/{$goal->id}/deposit", ['amount' => 250.5])->assertOk()->assertJsonPath('saved', 1750.5);

        $this->assertSame(0, $user->expenses()->count());
    }

    public function test_user_cannot_touch_someone_elses_goal(): void
    {
        $goal = $this->goalFor(User::factory()->create());
        Sanctum::actingAs(User::factory()->create());

        $this->putJson("/api/goals/{$goal->id}", ['name' => 'X', 'target' => 1])->assertForbidden();
        $this->postJson("/api/goals/{$goal->id}/deposit", ['amount' => 500])->assertForbidden();
        $this->deleteJson("/api/goals/{$goal->id}")->assertForbidden();
        $this->assertEquals(0, $goal->fresh()->saved);
    }

    public function test_goal_and_deposit_are_validated(): void
    {
        $user = User::factory()->create();
        $goal = $this->goalFor($user);
        Sanctum::actingAs($user);

        $this->postJson('/api/goals', [
            'name' => '',
            'target' => 0,
            'saved' => -1,
            'target_date' => 'someday',
        ])->assertUnprocessable()->assertJsonValidationErrors(['name', 'target', 'saved', 'target_date']);

        $this->postJson("/api/goals/{$goal->id}/deposit", ['amount' => 0])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('amount');
    }
}
