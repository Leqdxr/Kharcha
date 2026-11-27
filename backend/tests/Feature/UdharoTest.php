<?php

namespace Tests\Feature;

use App\Models\Udharo;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UdharoTest extends TestCase
{
    use RefreshDatabase;

    private function udharoFor(User $user, array $attributes = []): Udharo
    {
        return $user->udharos()->create($attributes + [
            'person' => 'Sujan',
            'amount' => 500,
            'direction' => 'lent',
            'date' => '2026-11-20',
        ]);
    }

    public function test_user_can_add_an_udharo(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/udharos', [
            'person' => 'Priya',
            'amount' => 300,
            'direction' => 'borrowed',
            'note' => 'Movie ticket',
            'date' => '2026-11-21',
        ])->assertCreated()
            ->assertJsonPath('person', 'Priya')
            ->assertJsonPath('direction', 'borrowed')
            ->assertJsonPath('settled_at', null);

        $this->assertDatabaseHas('udharos', ['user_id' => $user->id, 'person' => 'Priya']);
    }

    public function test_list_shows_only_own_unsettled_entries(): void
    {
        $user = User::factory()->create();
        $open = $this->udharoFor($user);
        $this->udharoFor($user, ['settled_at' => now()]);
        $this->udharoFor(User::factory()->create());
        Sanctum::actingAs($user);

        $this->getJson('/api/udharos')->assertOk()->assertJsonCount(1)->assertJsonPath('0.id', $open->id);
    }

    public function test_update_and_delete(): void
    {
        $user = User::factory()->create();
        $udharo = $this->udharoFor($user);
        Sanctum::actingAs($user);

        $this->putJson("/api/udharos/{$udharo->id}", [
            'person' => 'Sujan K',
            'amount' => 650,
            'direction' => 'lent',
            'date' => '2026-11-20',
        ])->assertOk()->assertJsonPath('amount', 650);

        $this->deleteJson("/api/udharos/{$udharo->id}")->assertNoContent();
        $this->assertDatabaseMissing('udharos', ['id' => $udharo->id]);
    }

    public function test_settle_and_unsettle(): void
    {
        $this->travelTo('2026-11-27 10:00:00');
        $user = User::factory()->create();
        $udharo = $this->udharoFor($user);
        Sanctum::actingAs($user);

        $this->postJson("/api/udharos/{$udharo->id}/settle")->assertOk();
        $this->assertNotNull($udharo->fresh()->settled_at);
        $this->getJson('/api/udharos')->assertJsonCount(0);

        $this->postJson("/api/udharos/{$udharo->id}/unsettle")->assertOk()->assertJsonPath('settled_at', null);
        $this->assertNull($udharo->fresh()->settled_at);
        $this->getJson('/api/udharos')->assertJsonCount(1);
    }

    public function test_user_cannot_touch_someone_elses_udharo(): void
    {
        $udharo = $this->udharoFor(User::factory()->create());
        Sanctum::actingAs(User::factory()->create());

        $this->putJson("/api/udharos/{$udharo->id}", [
            'person' => 'X', 'amount' => 1, 'direction' => 'lent', 'date' => '2026-11-20',
        ])->assertForbidden();
        $this->postJson("/api/udharos/{$udharo->id}/settle")->assertForbidden();
        $this->postJson("/api/udharos/{$udharo->id}/unsettle")->assertForbidden();
        $this->deleteJson("/api/udharos/{$udharo->id}")->assertForbidden();
        $this->assertNull($udharo->fresh()->settled_at);
    }

    public function test_udharo_is_validated(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/udharos', [
            'person' => '',
            'amount' => 0,
            'direction' => 'gifted',
            'date' => 'yesterday-ish',
        ])->assertUnprocessable()->assertJsonValidationErrors(['person', 'amount', 'direction', 'date']);
    }

    public function test_split_gives_the_remainder_to_you(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/udharos/split', [
            'title' => 'Khaja set',
            'total' => 1000,
            'friends' => ['Sujan', 'Priya', 'Anish'],
            'category' => 'Food',
            'payment_method' => 'esewa',
            'date' => '2026-11-26',
        ])->assertCreated();

        // 1000 / 4 = 250 each; no remainder.
        $this->assertEquals([250, 250, 250], $response->json('udharos.*.amount'));
        $this->assertEquals(250, $response->json('expense.amount'));

        $response = $this->postJson('/api/udharos/split', [
            'title' => 'Pizza',
            'total' => 1001.5,
            'friends' => ['Sujan', 'Priya'],
        ])->assertCreated();

        // 1001.5 / 3 = 333 each for friends; you pay 335.5.
        $this->assertEquals([333, 333], $response->json('udharos.*.amount'));
        $this->assertEquals(335.5, $response->json('expense.amount'));
        $this->assertSame('Food', $response->json('expense.category'));
        $this->assertSame(['lent', 'lent'], $response->json('udharos.*.direction'));
        $this->assertSame(['Sujan', 'Priya'], $response->json('udharos.*.person'));

        $this->assertSame(5, $user->udharos()->count());
        $this->assertSame(2, $user->expenses()->count());
    }

    public function test_split_is_validated_and_saves_nothing_on_error(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/udharos/split', [
            'title' => '',
            'total' => -5,
            'friends' => [],
            'category' => 'Shopping',
        ])->assertUnprocessable()->assertJsonValidationErrors(['title', 'total', 'friends', 'category']);

        $this->postJson('/api/udharos/split', [
            'title' => 'Tea',
            'total' => 2,
            'friends' => ['A', 'B'],
        ])->assertUnprocessable()->assertJsonValidationErrors('total');

        $this->postJson('/api/udharos/split', [
            'title' => 'Tea',
            'total' => 100,
            'friends' => ['A', 'A'],
        ])->assertUnprocessable()->assertJsonValidationErrors('friends.0');

        $this->assertSame(0, $user->udharos()->count());
        $this->assertSame(0, $user->expenses()->count());
    }
}
