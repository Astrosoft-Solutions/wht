<?php

namespace App\Http\Requests\Admin;

use App\Models\Plan;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class PlanRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('price')) {
            $this->merge(['price_paise' => (int) round(((float) $this->input('price')) * 100)]);
        }
    }

    public function rules(): array
    {
        $creating = $this->isMethod('POST');
        $plan = $this->route('plan');
        $coachType = $this->input('coach_type', $plan?->coach_type);

        return [
            'coach_type' => [$creating ? 'required' : 'sometimes', Rule::in(Plan::COACH_TYPES)],
            'tier' => [
                $creating ? 'required' : 'sometimes',
                Rule::in(Plan::TIERS),
                Rule::unique('plans', 'tier')->where('coach_type', $coachType)->ignore($plan?->id),
            ],
            'name' => [$creating ? 'required' : 'sometimes', 'string', 'max:100'],
            'description' => ['sometimes', 'nullable', 'string', 'max:1000'],
            'price_paise' => [$creating ? 'required' : 'sometimes', 'integer', 'min:100'],
            'duration_days' => ['sometimes', 'integer', 'between:1,3650'],
            'max_customers' => ['sometimes', 'nullable', 'integer', 'min:1'],
            'features' => ['sometimes', 'nullable', 'array'],
            'features.*' => ['string', 'max:150'],
            'is_active' => ['sometimes', 'boolean'],
            'sort_order' => ['sometimes', 'integer', 'min:0'],
        ];
    }

    public function messages(): array
    {
        return ['tier.unique' => 'A plan for this coach type and tier already exists.'];
    }

    public function attributesToSave(): array
    {
        return collect($this->validated())->except('price')->all();
    }
}
