#!/usr/bin/env bash
# Скачивает бесплатные шрифты (Google Fonts, лицензия OFL) в assets/fonts.
# Запускать внутри Termux Ubuntu proot, в корне проекта onion_notes,
# где ЕСТЬ интернет (в песочнице, где писался код, интернета не было,
# поэтому сами файлы шрифтов сюда включить было нельзя).
#
# Использование:
#   chmod +x scripts/download_fonts.sh
#   ./scripts/download_fonts.sh

set -e
mkdir -p assets/fonts
cd assets/fonts

base="https://raw.githubusercontent.com/google/fonts/main"

# Poppins/Comfortaa/Quicksand/PlayfairDisplay/Caveat/SpaceMono уже лежат в
# assets/fonts/ и подключены в pubspec.yaml — их скачивать не нужно.
# Ниже — ДОПОЛНИТЕЛЬНЫЕ шрифты. После скачивания раскомментируйте
# соответствующий блок в pubspec.yaml (в самом низу секции fonts:).

curl -L -o Inter-Regular.ttf         "$base/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf"
curl -L -o Inter-Italic.ttf          "$base/ofl/inter/Inter-Italic%5Bopsz%2Cwght%5D.ttf"
curl -L -o JetBrainsMono-Regular.ttf "$base/ofl/jetbrainsmono/JetBrainsMono%5Bwght%5D.ttf"
curl -L -o Nunito-Regular.ttf        "$base/ofl/nunito/Nunito%5Bwght%5D.ttf"
curl -L -o Merriweather-Regular.ttf  "$base/ofl/merriweather/Merriweather%5Bopsz%2Cwdth%2Cwght%5D.ttf"
curl -L -o Pacifico-Regular.ttf      "$base/ofl/pacifico/Pacifico-Regular.ttf"
curl -L -o Manrope-Regular.ttf       "$base/ofl/manrope/Manrope%5Bwght%5D.ttf"

echo "Готово. Файлы шрифтов лежат в assets/fonts/"
echo "Не забудьте раскомментировать соответствующий блок в pubspec.yaml,"
echo "иначе шрифт скачается, но подключен не будет."
echo "Если какая-то ссылка изменится на GitHub — просто скачайте нужный .ttf"
echo "вручную с fonts.google.com и положите под тем же именем."
