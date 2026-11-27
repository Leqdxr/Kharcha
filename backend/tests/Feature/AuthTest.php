<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Asha',
            'email' => 'asha@example.com',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
        ]);

        $response->assertCreated()
            ->assertJsonStructure(['user' => ['id', 'name', 'email', 'monthly_budget'], 'token'])
            ->assertJsonPath('user.email', 'asha@example.com')
            ->assertJsonPath('user.monthly_budget', null)
            ->assertJsonMissingPath('user.password');

        $this->assertDatabaseHas('users', ['email' => 'asha@example.com']);
    }

    public function test_register_validates_input(): void
    {
        User::factory()->create(['email' => 'taken@example.com']);

        $this->postJson('/api/register', [
            'name' => '',
            'email' => 'taken@example.com',
            'password' => 'short',
            'password_confirmation' => 'different',
        ])->assertUnprocessable()->assertJsonValidationErrors(['name', 'email', 'password']);
    }

    public function test_user_can_log_in(): void
    {
        $user = User::factory()->create(['email' => 'asha@example.com', 'monthly_budget' => 20000]);

        $this->postJson('/api/login', ['email' => 'asha@example.com', 'password' => 'password'])
            ->assertOk()
            ->assertJsonStructure(['user', 'token'])
            ->assertJsonPath('user.id', $user->id)
            ->assertJsonPath('user.monthly_budget', 20000);
    }

    public function test_login_fails_with_wrong_password(): void
    {
        User::factory()->create(['email' => 'asha@example.com']);

        $this->postJson('/api/login', ['email' => 'asha@example.com', 'password' => 'wrong-password'])
            ->assertUnauthorized()
            ->assertJsonPath('message', 'Wrong email or password.');
    }

    public function test_login_validates_input(): void
    {
        $this->postJson('/api/login', ['email' => 'not-an-email'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email', 'password']);
    }

    public function test_get_user_returns_monthly_budget(): void
    {
        Sanctum::actingAs(User::factory()->create(['monthly_budget' => 15000]));

        $this->getJson('/api/user')->assertOk()->assertJsonPath('monthly_budget', 15000);
    }

    public function test_protected_routes_need_a_token(): void
    {
        $this->getJson('/api/user')->assertUnauthorized();
        $this->getJson('/api/expenses')->assertUnauthorized();
        $this->getJson('/api/summary')->assertUnauthorized();
        $this->putJson('/api/budget', ['monthly_budget' => 100])->assertUnauthorized();
    }

    public function test_guest_gets_401_even_without_json_accept_header(): void
    {
        $this->get('/api/user')->assertUnauthorized()->assertJsonPath('message', 'Unauthenticated.');
    }
}
