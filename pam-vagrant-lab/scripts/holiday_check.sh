#!/bin/bash
# Расширенная проверка праздничных дней

TODAY=$(date +%m%d)
YEAR=$(date +%Y)

# Список фиксированных праздников
FIXED_HOLIDAYS="0101 0308 0501 0509 0612 1104"

# Функция для вычисления Пасхи (пример)
calculate_easter() {
    local year=$1
    # Упрощенный расчет (алгоритм Гаусса)
    local a=$((year % 19))
    local b=$((year % 4))
    local c=$((year % 7))
    local d=$(( (19*a + 15) % 30 ))
    local e=$(( (2*b + 4*c + 6*d + 6) % 7 ))
    local day=$((d + e + 13))
    
    if [ $day -gt 30 ]; then
        echo "05$((day-30))"
    else
        echo "04$day"
    fi
}

# Проверка фиксированных праздников
for holiday in $FIXED_HOLIDAYS; do
    if [ "$TODAY" == "$holiday" ]; then
        echo "Сегодня праздничный день: $holiday"
        exit 1
    fi
done

# Проверка выходных (суббота и воскресенье)
DAY_OF_WEEK=$(date +%u)
if [ $DAY_OF_WEEK -eq 6 ] || [ $DAY_OF_WEEK -eq 7 ]; then
    echo "Сегодня выходной день"
    exit 1
fi

echo "Сегодня рабочий день"
exit 0
