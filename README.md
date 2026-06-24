# LibreAlchemy

Аддон для помощи в Алхимии. Аллоды Онлайн.

Addon to assist with Alchemy. Allods Online.

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