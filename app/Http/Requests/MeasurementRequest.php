<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class MeasurementRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $required = $this->isMethod('POST') ? 'required' : 'sometimes';

        return [
            'programme_id' => [
                'sometimes', 'nullable', 'integer',
                Rule::exists('programmes', 'id')->where('customer_id', $this->route('customer')->id),
            ],
            'recorded_on' => [$required, 'date_format:Y-m-d'],
            'weight' => ['sometimes', 'nullable', 'numeric', 'between:1,400'],
            'fat_percent' => ['sometimes', 'nullable', 'numeric', 'between:0,80'],
            'bmi' => ['sometimes', 'nullable', 'numeric', 'between:5,100'],
            'muscle' => ['sometimes', 'nullable', 'numeric', 'between:0,200'],
            'visceral_fat' => ['sometimes', 'nullable', 'numeric', 'between:0,60'],
            'body_age' => ['sometimes', 'nullable', 'integer', 'between:1,120'],
            'chest' => ['sometimes', 'nullable', 'numeric', 'between:10,300'],
            'waist' => ['sometimes', 'nullable', 'numeric', 'between:10,300'],
            'hp' => ['sometimes', 'nullable', 'string', 'max:20'],
            'rm_24' => ['sometimes', 'nullable', 'string', 'max:20'],
            'total_points' => ['sometimes', 'nullable', 'integer', 'min:0'],
        ];
    }
}
