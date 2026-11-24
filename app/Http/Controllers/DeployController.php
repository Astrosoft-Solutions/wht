<?php

namespace App\Http\Controllers;

use App\Models\Plan;
use Database\Seeders\ProductionSeeder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Finishes a deploy on hosting that only offers FTP: the GitHub workflow uploads the files,
 * then calls this endpoint to run the artisan commands it cannot run over FTP.
 */
class DeployController extends Controller
{
    /** @var list<array{command: string, ok: bool, output: string}> */
    private array $steps = [];

    public function __invoke(Request $request): JsonResponse
    {
        $token = (string) config('services.deploy.token');
        abort_if($token === '' || ! hash_equals($token, (string) $request->bearerToken()), 404);

        try {
            // Cached config and routes from the previous release would hide the new files.
            $this->run('optimize:clear');
            $this->run('migrate', ['--force' => true]);

            if (Plan::query()->doesntExist()) {
                $this->run('db:seed', ['--class' => ProductionSeeder::class, '--force' => true]);
            }

            if (! file_exists(public_path('storage'))) {
                // Some shared hosts disable symlink(); uploads still work, only their public URLs break.
                $this->run('storage:link', required: false);
            }

            $this->run('optimize');
        } catch (Throwable $e) {
            Log::error('Deploy hook failed', ['exception' => $e]);

            return response()->json(['ok' => false, 'error' => $e->getMessage(), 'steps' => $this->steps], 500);
        }

        return response()->json(['ok' => true, 'steps' => $this->steps]);
    }

    private function run(string $command, array $arguments = [], bool $required = true): void
    {
        try {
            $ok = Artisan::call($command, $arguments) === 0;
            $output = trim(Artisan::output());
        } catch (Throwable $e) {
            $ok = false;
            $output = $e->getMessage();
        }

        $this->steps[] = ['command' => $command, 'ok' => $ok, 'output' => $output];

        if (! $ok && $required) {
            throw new \RuntimeException("php artisan {$command} failed: {$output}");
        }
    }
}
