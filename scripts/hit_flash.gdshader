shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.15, 0.62, 0.74, 1.0);
uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.0;

// Математическая функция скругленного хрусталя
float sd_round_box(vec2 p, vec2 b, vec4 r) {
    vec2 q = abs(p) - b + vec2(r.x);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

void fragment() {
    vec2 center_uv = UV - vec2(0.5);
    
    // Скругление углов плитки
    float dist = sd_round_box(center_uv, vec2(0.5), vec4(0.14));
    float alpha = 1.0 - smoothstep(-0.01, 0.01, dist);
    
    // Внутреннее преломление света (эффект стеклянной грани)
    float edge = smoothstep(-0.05, -0.01, dist) * smoothstep(0.0, -0.04, dist);
    
    // Динамический бегущий глянцевый блик (зависит от времени TIME)
    float highlight = sin((UV.x + UV.y) * 2.5 + TIME * 1.5);
    highlight = smoothstep(0.8, 0.95, highlight) * 0.4;
    
    // Создаем глубокий хрустальный градиент
    vec3 glass_grad = mix(base_color.rgb * 0.4, base_color.rgb * 1.4, UV.y);
    
    // Накладываем неоновую внутреннюю подсветку граней
    vec3 final_rgb = glass_grad + (base_color.rgb * edge * 0.8);
    
    // Добавляем яркий скользящий блик на стекло
    final_rgb += vec3(highlight);
    
    // Пульсация для редких золотых блоков
    if (pulse_intensity > 0.0) {
        float p = (cos(TIME * 5.0) + 1.0) * 0.5;
        final_rgb += flash_color.rgb * p * pulse_intensity * 0.4;
    }
    
    // Вспышка поглощения кинетической энергии (Hit Flash)
    final_rgb = mix(final_rgb, flash_color.rgb, flash_modifier);
    
    COLOR = vec4(final_rgb, base_color.a * alpha);
}