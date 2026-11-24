<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class GalleryItemRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $creating = $this->isMethod('POST') && ! $this->route('gallery');
        $item = $this->route('gallery');
        $type = $this->input('type', $item?->type);
        $hasExistingFile = (bool) $item?->path;

        $fileRules = $type === 'image'
            ? ['image', 'mimes:jpg,jpeg,png,webp,gif', 'max:5120']
            : ['file', 'mimetypes:video/mp4,video/webm,video/quicktime', 'max:102400'];

        $fileRequired = match (true) {
            $type === 'image' && ($creating || ! $hasExistingFile) => 'required',
            $type === 'video' && ($creating || ! $hasExistingFile) => 'required_without:video_url',
            default => 'nullable',
        };

        return [
            'type' => [$creating ? 'required' : 'sometimes', 'in:image,video'],
            'title' => [$creating ? 'required' : 'sometimes', 'string', 'max:150'],
            'description' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'file' => [$fileRequired, ...$fileRules],
            'video_url' => [
                'nullable',
                'url',
                'max:255',
                $type === 'video' && ($creating || ! $hasExistingFile) ? 'required_without:file' : 'nullable',
                'regex:~^https?://(www\.|m\.)?(youtube\.com|youtu\.be)/~i',
            ],
            'thumbnail' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
            'is_published' => ['sometimes', 'boolean'],
            'sort_order' => ['sometimes', 'integer', 'min:0'],
        ];
    }

    public function messages(): array
    {
        return [
            'video_url.regex' => 'Only YouTube links are supported.',
            'file.required_without' => 'Upload a video file or paste a YouTube link.',
            'video_url.required_without' => 'Upload a video file or paste a YouTube link.',
            'file.max' => 'The file is too large (images up to 5 MB, videos up to 100 MB).',
        ];
    }
}
