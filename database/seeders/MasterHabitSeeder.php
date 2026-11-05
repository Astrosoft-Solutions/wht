<?php

namespace Database\Seeders;

use App\Models\MasterHabit;
use Illuminate\Database\Seeder;

class MasterHabitSeeder extends Seeder
{
    private const HABITS = [
        ['Wake Up Time', 'sunrise', '#F9A825', '04:00', null],
        ['Prayer Time', 'prayer', '#8D6E63', '04:20', '04:45'],
        ['Fitness Time', 'fitness', '#455A64', '05:00', '06:00'],
        ['Shake Time', 'shake', '#E91E63', '07:00', '07:30'],
        ['Education Time', 'book', '#1565C0', '07:30', '08:30'],
        ['Water Time - 1', 'water', '#1E88E5', '08:00', '10:00'],
        ['Afresh Time - 1', 'leaf', '#43A047', '10:30', '11:00'],
        ['Water Time - 2', 'water', '#1E88E5', '11:00', '12:30'],
        ['Lunch Time', 'lunch', '#EF6C00', '12:45', '13:15'],
        ['Water Time - 3', 'water', '#1E88E5', '13:30', '15:00'],
        ['Afresh Time - 2', 'leaf', '#43A047', '16:00', '16:15'],
        ['Water Time - 4', 'water', '#1E88E5', '16:30', '17:45'],
        ['Zumba Time', 'dance', '#7B1FA2', '18:00', '19:00'],
        ['Shake Time - 2', 'shake', '#E91E63', '19:00', '19:30'],
        ['Bed Time', 'bed', '#3949AB', '21:00', '21:30'],
    ];

    public function run(): void
    {
        foreach (self::HABITS as $i => [$name, $icon, $color, $start, $end]) {
            MasterHabit::updateOrCreate(
                ['name' => $name],
                ['icon' => $icon, 'color' => $color, 'start_time' => $start, 'end_time' => $end, 'sort_order' => $i, 'is_active' => true],
            );
        }
    }
}
