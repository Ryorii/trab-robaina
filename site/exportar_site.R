# ==============================================================================
# SCRIPT DE EXPORTAÇÃO ISOLADO
# Este script executa o processo de exportação do shinylive num ambiente limpo
# para evitar conflitos de dependência.
# ==============================================================================

# 1. Verifica se o pacote shinylive está instalado
if (!require("shinylive")) {
  install.packages("shinylive")
}

# 2. Executa a função de exportação
#    appdir = "." significa que ele vai procurar o app.R na pasta atual.
#    destdir = "docs" é a pasta de saída para o GitHub Pages.
shinylive::export(appdir = ".", destdir = "docs")

# 3. Mensagem de sucesso
message("\nProcesso de exportação concluído! A pasta 'docs' foi criada ou atualizada. \nVocê já pode enviar as alterações para o GitHub.")