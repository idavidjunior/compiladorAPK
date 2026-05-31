import re
import sys
from pathlib import Path

def check_material3_dependency(build_gradle_path):
    with open(build_gradle_path, encoding='utf-8') as f:
        content = f.read()
    if 'com.google.android.material:material' not in content:
        print('[ERROR] Material3 dependency is missing in build.gradle')
        return False
    return True

def check_theme_in_styles(styles_path, theme_name):
    with open(styles_path, encoding='utf-8') as f:
        content = f.read()
    return theme_name in content

def main():
    # Caminhos padrões
    build_gradle = Path("app/build.gradle")
    styles_xml = Path("app/src/main/res/values/styles.xml")

    missing = False

    # 1. Verifica dependência do Material3
    if not build_gradle.exists():
        print(f'[WARN] {build_gradle} não encontrado.')
        missing = True
    elif not check_material3_dependency(build_gradle):
        print('Sugestão automática: Adicione a linha abaixo em dependencies:\n'
              'implementation \'com.google.android.material:material:1.9.0\'')
        missing = True

    # 2. Verifica existência do tema
    REQUIRED_THEME = "Theme.Material3.DayNight"
    if not styles_xml.exists():
        print(f'[WARN] {styles_xml} não encontrado.')
        missing = True
    elif not check_theme_in_styles(styles_xml, REQUIRED_THEME):
        print(f'[ERROR] Tema {REQUIRED_THEME} não encontrado em {styles_xml}')
        missing = True

    # 3. Futuros checks: atributos (windowActionBar/windowNoTitle)

    if missing:
        sys.exit(1)
    print('[SUCCESS] Todos os recursos essenciais estão presentes!')

if __name__ == "__main__":
    main()
