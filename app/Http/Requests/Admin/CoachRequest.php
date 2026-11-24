<?php

namespace App\Http\Requests\Admin;

use App\Models\Plan;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class CoachRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $creating = $this->isMethod('POST');
        $id = $this->route('coach')?->id;

        return [
            'name' => [$creating ? 'required' : 'sometimes', 'string', 'max:255'],
            'email' => [$creating ? 'required' : 'sometimes', 'email', 'max:255', Rule::unique('users', 'email')->ignore($id)],
            'mobile' => ['sometimes', 'nullable', 'string', 'max:20', Rule::unique('users', 'mobile')->ignore($id)],
            'password' => [$creating ? 'required' : 'sometimes', 'nullable', Password::min(8)],
            'coach_type' => [$creating ? 'required' : 'sometimes', Rule::in(Plan::COACH_TYPES)],
            'status' => ['sometimes', 'in:active,inactive'],
        ];
    }

    public function attributesToSave(): array
    {
        return collect($this->validated())
            ->reject(fn ($value, $key) => $key === 'password' && blank($value))
            ->all();
    }
}
