# کاتالوگ تعاملات بومی (`docs/INTERACTION_CATALOG.md`)

| کد تعامل (`interaction_type`) | کامپوننت Compose | روش تعامل کودک | منطق ارزیابی و کدهای خطا (`InteractionValidator`) |
|---|---|---|---|
| `drag_and_drop_count` | `DragAndDropCountView` | کشیدن و رها کردن (Drag & Drop) یا لمس سیب‌ها به داخل سبد شمارش | `OVERCOUNT_BY_ONE`, `UNDERCOUNT_BY_ONE`, `COUNT_MISMATCH`, `INVALID_INPUT` |
| `number_line_jump` | `NumberLineJumpView` | پرش مهره روی محور اعداد ۰ تا ۲۰ به راست و چپ | `COUNTING_START_NODE`, `WRONG_DIRECTION`, `OUT_OF_RANGE` |
| `tally_mark_builder` | `TallyMarkBuilderView` | ساخت دسته‌های ۵تایی استاندارد (۴ خط عمودی + ۱ خط مورب) و چوب‌خط تکی | `UNBUNDLED_FIVE` (بیش از ۴ خط تکی)، `BUNDLE_COUNTED_AS_ONE`, `TALLY_MISMATCH` |
| `pattern_completer` | `PatternCompleterView` | تشخیص رابطه الگو و انتخاب شکل بعدی از آرایه `options` واقعی JSON | `PATTERN_MISMATCH`, `INVALID_INPUT` |
| `balance_scale_equation` | `BalanceScaleView` | ترازوی دوکفه‌ای واقعی با تکیه‌گاه، دو کفه، بلوک‌های وزنه ۱، ۲ و ۵ و نمایش تعادل | `OFF_BY_ONE_BALANCE`, `EQUILIBRIUM_ERROR`, `INVALID_INPUT` |
| `visual_multiple_choice` | `VisualMultipleChoiceView` | انتخاب گزینه تصویری/عددی از آرایه `options` واقعی JSON | `DISTRACTOR_SELECTED`, `INVALID_INPUT` |
