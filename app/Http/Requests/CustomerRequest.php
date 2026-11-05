<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CustomerRequest extends FormRequest
{
    /**
     * Fields stored on the baseline measurement rather than the customer row.
     */
    public const MEASUREMENT_FIELDS = [
        'weight', 'fat_percent', 'bmi', 'muscle', 'visceral_fat', 'body_age', 'chest', 'waist',
    ];

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $required = $this->isMethod('POST') ? 'required' : 'sometimes';
        $customerId = $this->route('customer')?->id;

        return [
            'customer_code' => [
                'sometimes', 'nullable', 'string', 'max:20',
                Rule::unique('customers', 'customer_code')
                    ->where('user_id', $this->user()->id)
                    ->ignore($customerId),
            ],
            'name' => [$required, 'string', 'max:255'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:20'],
            'email' => ['sometimes', 'nullable', 'email', 'max:255'],
            'height_cm' => ['sometimes', 'nullable', 'numeric', 'between:50,250'],
            'status' => ['sometimes', 'in:active,inactive'],
            'health_condition_before' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'remarks' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'weight' => ['sometimes', 'nullable', 'numeric', 'between:1,400'],
            'fat_percent' => ['sometimes', 'nullable', 'numeric', 'between:0,80'],
            'bmi' => ['sometimes', 'nullable', 'numeric', 'between:5,100'],
            'muscle' => ['sometimes', 'nullable', 'numeric', 'between:0,200'],
            'visceral_fat' => ['sometimes', 'nullable', 'numeric', 'between:0,60'],
            'body_age' => ['sometimes', 'nullable', 'integer', 'between:1,120'],
            'chest' => ['sometimes', 'nullable', 'numeric', 'between:10,300'],
            'waist' => ['sometimes', 'nullable', 'numeric', 'between:10,300'],
        ];
    }

    public function customerData(): array
    {
        return collect($this->validated())->except(self::MEASUREMENT_FIELDS)->all();
    }

    public function measurementData(): array
    {
        return collect($this->validated())->only(self::MEASUREMENT_FIELDS)->all();
    }
}
