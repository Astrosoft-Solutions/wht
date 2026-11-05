<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ProgrammeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $required = $this->isMethod('POST') ? 'required' : 'sometimes';

        return [
            'name' => [$required, 'string', 'max:100'],
            'goal' => ['sometimes', 'nullable', 'string', 'max:100'],
            'total_weeks' => ['sometimes', 'integer', 'between:1,104'],
            'weeks_completed' => ['sometimes', 'integer', 'min:0', 'max:104'],
            'start_date' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
        ];
    }
}
