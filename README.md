# LibreAlchemy

Аддон для помощи в Алхимии. Аллоды Онлайн.

Addon to assist with Alchemy. Allods Online.

---

### [v2.1.0](https://github.com/Alfa-ao/LibreAlchemy/releases/tag/v2.1.0)
<p align="center">
  <img src="https://raw.githubusercontent.com/Alfa-ao/LibreAlchemy/refs/heads/main/LibreAlchemyV2.png" width="300px">
</p>

+ **Главное дополнение**: Изменение интерфейса и расположение кнопок.
  + Для возврата стандартного расположения кнопок, нужно:
  + Открыть скрипт `LibreAlchemy\Scripts\Core\AlchemyConfig.lua`
  + Изменить атрибут `ENABLE_CUSTOM_LAYOUT = true` на `ENABLE_CUSTOM_LAYOUT = false` и перезагрузить игру.
+ Lua:
  + Абсолютно вся скриптовая часть была переписана с нуля.
  + Использовано Объектно-Ориентированное Программирование (**ООП**), **SOLID** по возможности.
  + Контракты `EventClassInterface.lua`, `SearchAlgorithmClassInterface.lua`, `WidgetClassInterface.lua`
  + И многого другого, не нужного обычному игроку слов.

+ **Известные ошибки**:
  1) При изменении масштаба интерфейса игры с минимального на стандартный после перезагрузки игры текст подсказки исчезает.
  + Причина: координаты подсказки становятся отрицательными, и при следующем входе в игру текст прячется за экраном. Лечится удалением `Configs\LibreAlchemy\user.cfg`. 
  + Ответственность за это несет библиотека `LibDnD.lua`. Она должна обнулять (или корректировать) отрицательные координаты.

<details>
<summary>(English)</summary>

+ **Main addition**: UI changes and button layout.
  + To revert to the default button layout:
  + Open the `LibreAlchemy\Scripts\Core\AlchemyConfig.lua` script.
  + Change `ENABLE_CUSTOM_LAYOUT = true` to `ENABLE_CUSTOM_LAYOUT = false` and restart the game.
+ Lua:
  + The entire scripting codebase has been completely rewritten from scratch.
  + Object-Oriented Programming (**OOP**) and **SOLID** principles were applied where possible.
  + Contracts: `EventClassInterface.lua`, `SearchAlgorithmClassInterface.lua`, `WidgetClassInterface.lua`.
  + And plenty of other technical jargon unnecessary for the average player.

+ **Known issues**:
  1) When changing the game UI scale from minimum to default, the tooltip text disappears after restarting the game.
  + Cause: The tooltip coordinates become negative, hiding the text off-screen on the next launch. Fix: Delete `Configs\LibreAlchemy\user.cfg`. 
  + The `LibDnD.lua` library is responsible for this. It should reset (or correct) negative coordinates.

</details>

---

### [v1.2.1](https://github.com/Alfa-ao/LibreAlchemy/releases/tag/v1.2.1)
+ Добавлена локализация: `ENG`, `RUS`. Все текстовые сообщения из lua перенесены.
+ Скриптовая часть переведена в кодировку `UTF-8 no BOM`.
<details>
<summary>(English)</summary>

+ Added localization: `ENG`, `RUS`. All text messages from Lua have been migrated.
+ Script part converted to `UTF-8 without BOM` encoding.

</details>

---

### [v1.2.0](https://github.com/Alfa-ao/LibreAlchemy/releases/tag/v1.2.0)
+ Добавлена библиотека (Drag&Drop) [LibDnD.lua](https://alloder.pro/files/file/248-libdnd/). Текст с подсказкой можно перемещать по всей области экрана (`MainForm`).
+ Lua:
  + Чистка неиспользуемых участков кода / функций.
  + `SetBackgroundColor`, `SetPriority`, метод `OnSize` частично, атрибуты перенесены в ответственные виджеты.
  + `Init` - переписана точка иницилизации аддона. Функция удалена.
  + Переделана логика сообщений. Текст отрабатывает один раз, вместо наложения друг на друга.
  + Состояние сообщений:
    + `Приветствие` - при первом открытии окна Алхимии.
    + `С возвращением` - при повторном открытии окна Алхимии.
    + `Возможно, имеются N рецептов` - при полном заполнении требуемых слотов.
    + `Компоненты не готовы` - при недостаточном заполнении компонентами слоты.
    + `Тут нет рецептов` - слоты все пусты.
    + `Поздравляю! Вы получаете: [ имя зелья ] x Nшт` - в сумку попал предмет из результата алхимических реакций.
  + Множество логических исправлений.
  + Добавлен `Debug` событий.
+ Widgets:
  + `MainForm`
    + `Priority` - увеличено положение позиционирования Родителя для текста с подсказкой на `10000`. При любых маштабах интерфейса игры, текст не будет скрываться под окно алхимии.
    + `Placement` - Исправлен размер окна на `WIDGET_ALIGN_BOTH`.
  + `ouText` - `Placement` - Исправлен. Размер на основании содержимого текста.
  + `BackBlack` - `Color` - `0xe61a1a0d`, вместо `SetBackgroundColor`.
<details>
<summary>(English)</summary>

+ Added library (Drag&Drop) [LibDnD.lua](https://alloder.pro/files/file/248-libdnd/). The hint text can now be moved anywhere within the screen area (`MainForm`).
+ Lua:
  + Cleanup of unused code sections/functions.
  + `SetBackgroundColor`, `SetPriority`, and partially the `OnSize` method, along with attributes, have been moved to their respective widgets.
  + `Init` – the addon initialization entry point has been rewritten; the function was removed.
  + Message logic reworked. Text now displays once instead of overlapping.
  + Message states:
    + `Greetings` – upon first opening the Alchemy window.
    + `Welcome back` – upon reopening the Alchemy window.
    + `Possibly N recipes available` – when all required slots are fully filled.
    + `Components not ready` – when component slots are insufficiently filled.
    + `No recipes here` – when all slots are empty.
    + `Congratulations! You receive: [Potion Name] x N pcs` – when an item from alchemical reactions appears in your bag.
  + Numerous logical fixes.
  + Added event `Debug`.
+ Widgets:
  + `MainForm`
    + `Priority` – increased parent positioning priority for the hint text by `10000`. At any game interface scale, the text will not be hidden behind the alchemy window.
    + `Placement` – fixed window size to `WIDGET_ALIGN_BOTH`.
  + `ouText` – `Placement` - fixed. Size based on text content.
  + `BackBlack` – `Color` - `0xe61a1a0d` instead of using `SetBackgroundColor`.

</details>

---

### [v1.1.4](https://github.com/Alfa-ao/LibreAlchemy/releases/tag/v1.1.4)
+ Бэкап. Старая версия.
+ Last update: 2 июля, 2025
<details>
<summary>(English)</summary>

+ Backup. Old version.
+ Last update: July 2, 2025

</details>