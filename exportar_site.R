# Ficheiro: exportar_site.R

# Verifica se o pacote shinylive está instalado
if (!require("shinylive")) {
  install.packages("shinylive")
}

# Executa a função de exportação, apontando para a pasta limpa da aplicação
shinylive::export(appdir = "app_para_publicar", destdir = "docs")

message("\nProcesso de exportação concluído! A pasta 'docs' foi criada ou atualizada a partir de 'app_para_publicar'.")