# ==============================================================================
# SCRIPT FINAL: APLICAÇÃO SHINY (PARA PUBLICAÇÃO)
# Corrigido para evitar conflitos de JavaScript usando um iframe.
# ==============================================================================

library(shiny)
library(dplyr)
library(scales)

# --- Carregar os dados pré-calculados ---
PESOS_OTIMOS_GLOBAIS <- readRDS("pesos_otimizados.rds")
PRECOS_ATUAIS_GLOBAIS <- readRDS("precos_atuais.rds")


# ==============================================================================
# CONSTRUÇÃO DA INTERFACE MULTI-PÁGINA (UI) - Versão Corrigida
# ==============================================================================
ui <- navbarPage(
  "Análise e Otimização de Carteira",
  
  # --- PÁGINA 1: O RELATÓRIO ESTÁTICO (DENTRO DE UM IFRAME) ---
  tabPanel("Análise de Mercado",
           # O iframe isola o HTML, prevenindo conflitos de JavaScript.
           # O arquivo relatorio.html deve estar em uma subpasta chamada 'www'.
           tags$iframe(style="height:800px; width:100%; border:none;", 
                       src="relatorio.html")
  ),
  
  # --- PÁGINA 2: A CALCULADORA INTERATIVA ---
  tabPanel("Calculadora de Carteira",
           sidebarLayout(
             sidebarPanel(
               h4("Parâmetros de Investimento"),
               numericInput("valor_investimento", "Digite o valor total a ser investido (R$):", 100000, min = 1, step = 1000),
               actionButton("calcular", "Calcular Lista de Compras", class = "btn-primary")
             ),
             mainPanel(
               h3("Lista de Compras para o Investidor"),
               tableOutput("tabela_ordens")
             )
           )
  )
)


# ==============================================================================
# LÓGICA DO SERVIDOR (SERVER) - Sem alterações na lógica de cálculo
# ==============================================================================
server <- function(input, output, session) {
  
  resultados <- eventReactive(input$calcular, {
    valor_total_investimento <- input$valor_investimento
    
    df_ordens <- tibble(
      ativo = names(PESOS_OTIMOS_GLOBAIS),
      peso_otimizado = PESOS_OTIMOS_GLOBAIS
    ) %>%
      mutate(valor_alocado_ideal = peso_otimizado * valor_total_investimento) %>%
      left_join(PRECOS_ATUAIS_GLOBAIS, by = "ativo")
    
    df_ordens <- df_ordens %>%
      mutate(
        quantidade_a_comprar = case_when(
          ativo == "BTC" ~ valor_alocado_ideal / preco_atual,
          ativo != "CDI" ~ floor(valor_alocado_ideal / preco_atual),
          TRUE ~ NA_real_
        ),
        valor_real_alocado = case_when(
          ativo != "BTC" & ativo != "CDI" ~ quantidade_a_comprar * preco_atual,
          TRUE ~ valor_alocado_ideal
        )
      )
    
    total_gasto_nao_cdi <- df_ordens %>% filter(ativo != "CDI") %>% summarise(total = sum(valor_real_alocado)) %>% pull(total)
    valor_final_cdi <- valor_total_investimento - total_gasto_nao_cdi
    
    df_ordens <- df_ordens %>%
      mutate(valor_real_alocado = if_else(ativo == "CDI", valor_final_cdi, valor_real_alocado))
    
    return(df_ordens)
  })
  
  output$tabela_ordens <- renderTable({
    req(resultados())
    resultados() %>%
      select(Ativo=ativo, `Quantidade / Fração`=quantidade_a_comprar, `Preço Unitário (R$)`=preco_atual, `Valor a Investir (R$)`=valor_real_alocado) %>%
      mutate(
        `Quantidade / Fração` = case_when(
          Ativo == "BTC" ~ formatC(`Quantidade / Fração`, format="f", digits=8),
          Ativo == "CDI" ~ scales::dollar(`Valor a Investir (R$)`, prefix="R$"),
          TRUE ~ as.character(round(`Quantidade / Fração`, 0))
        ),
        `Preço Unitário (R$)` = if_else(Ativo == "CDI", NA_character_, as.character(round(`Preço Unitário (R$)`, 2))),
        `Valor a Investir (R$)` = scales::dollar(`Valor a Investir (R$)`, prefix="R$")
      )
  }, striped=TRUE, hover=TRUE, width="100%")
}

# --- Executar a Aplicação ---
shinyApp(ui = ui, server = server)