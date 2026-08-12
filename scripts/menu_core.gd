extends Node2D

func _ready():
    # Задний фон в цвет древней глины
    var bg = ColorRect.new()
    bg.size = Vector2(540, 960)
    bg.color = Color(0.18, 0.15, 0.12)
    add_child(bg)
    
    # Контейнер для центрирования элементов UI
    var center_container = CenterContainer.new()
    center_container.size = Vector2(540, 960)
    add_child(center_container)
    
    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 40) # Отступы между кнопками
    center_container.add_child(vbox)
    
    # Название игры
    var title = Label.new()
    title.text = "MESO ARKANOID"
    title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(title)
    
    # Подзаголовок сеттинга
    var subtitle = Label.new()
    subtitle.text = "Раскопки Древнего Междуречья"
    subtitle.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(subtitle)
    
    # Кнопка "Начать раскопки"
    var play_button = Button.new()
    play_button.text = " НАЧАТЬ РАСКОПКИ "
    play_button.custom_minimum_size = Vector2(250, 60)
    vbox.add_child(play_button)
    
    # Кнопка "Сбросить прогресс" (полезно для тестов коллекции)
    var reset_button = Button.new()
    reset_button.text = " СБРОСИТЬ ПРОГРЕСС "
    reset_button.custom_minimum_size = Vector2(250, 40)
    vbox.add_child(reset_button)
    
    # Подключаем сигналы нажатия к функциям кода
    play_button.pressed.connect(_on_play_pressed)
    reset_button.pressed.connect(_on_reset_pressed)

func _on_play_pressed():
    # Плавно переходим на основную игровую сцену
    get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_reset_pressed():
    # Стираем файл сохранений
    var save_path = "user://save_game.dat"
    if FileAccess.file_exists(save_path):
        DirAccess.remove_absolute(save_path)
    
    # Перезапускаем меню, чтобы обновить состояние (если нужно)
    get_tree().reload_current_scene()