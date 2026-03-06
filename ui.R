source("help.R", local=TRUE)
library(bsplus)
library(shinymanager)


ui <- dashboardPage(
  title="SCALA",
  skin = "blue",
  #------------------------------------------------------------Header
  dashboardHeader(disable = TRUE),

  #------------------------------------------------------------Sidebar
  dashboardSidebar(
    width = "285px",
    # Toggle button at the top of sidebar
    tags$div(
      class = "sidebar-toggle-container",
      tags$a(
        href = "javascript:void(0)",
        class = "sidebar-toggle-btn",
        onclick = "$('body').toggleClass('sidebar-collapse'); event.preventDefault();",
        tags$i(class = "fa fa-bars"),
        tags$span("Hide Menu", class = "toggle-text")
      )
    ),
    # Color theme switch
    tags$div(
      class = "color-theme-container",
      tags$div(
        class = "color-theme-switch",
        tags$button(
          type = "button",
          id = "theme-cool",
          class = "theme-btn theme-btn-active",
          onclick = "switchTheme('cool'); return false;",
          "❄️ Cool"
        ),
        tags$button(
          type = "button",
          id = "theme-warm",
          class = "theme-btn",
          onclick = "switchTheme('warm'); return false;",
          "🔥 Warm"
        )
      )
    ),
    sidebarMenu(id = "sidebarMenu",
      menuItem(text = "HOME", tabName = "home", icon = icon("home")),
      tags$hr(),
      menuItem(text = "DATA INPUT", tabName = "upload", icon = icon("upload")),
      menuItem(text = "FILE", tabName = "file", icon = icon("download")),
            tags$hr(),
      menuItem(text = "QUALITY CONTROL", tabName = "qc", icon = icon("check-circle")),
      menuItem(tags$div("DATA NORMALIZATION",
                        tags$br(),
                        "& SCALING", class = "menu_item_div"), tabName = "normalize", icon = icon("balance-scale")),
      menuItem(text = "PCA/LSI", tabName = "pca", icon = icon("chart-line")),
      menuItem(text = "CLUSTERING", tabName = "clustering", icon = icon("project-diagram")),
      menuItem(text = "UMAP etc", tabName = "umap", icon = icon("object-ungroup")),
    tags$hr(),
      menuItem(text = "UTILITY IDENTITY & ASSAY", tabName = "utilities", icon = icon("table")),
      menuItem(text = "UTILITY CLUSTER", tabName = "utilities2", icon = icon("circle-nodes")),
      menuItem(text = "UTILITY DATA MANIPULATION", tabName = "utilities3", icon = icon("file-pen")),
      menuItem(text = "SEURAT OBJECT STRUCTURE", tabName = "utilities4", icon = icon("magnifying-glass-chart")),
            tags$hr(),
      menuItem(text = "FEATURE INSPECTION", tabName = "features", icon = icon("braille")),
      menuItem(text = "MARKERS' IDENTIFICATION", tabName = "findMarkers", icon = icon("map-marker-alt")),
    menuItem(text = "DEG ANALYSIS", tabName = "findDEG", icon = icon("up-down")),
        menuItem(text = "GENE SET SCORE", tabName = "genesetscore", icon = icon("temperature-half")),
    tags$hr(),
    menuItem(text = "SPATIAL", tabName = "spatial", icon = icon("map")),
        menuItem(text = "PSEUDOBULK", tabName = "pseudobulk", icon = icon("bucket")),
      menuItem(text = "DOUBLETS' DETECTION", tabName = "doubletDetection", icon = icon("check-double")),
      menuItem(text = "CELL CYCLE PHASE ANALYSIS", tabName = "cellCycle", icon = icon("circle-notch")),
      tags$hr(),
      menuItem(tags$div("FUNCTIONAL/MOTIF",
                        tags$br(),
                        "ENRICHMENT ANALYSIS", class = "menu_item_div"), tabName = "gProfiler", icon=icon("chart-bar")),
      menuItem(text = "CLUSTERS' ANNOTATION", tabName = "annotateClusters", icon = icon("id-card")),

      menuItem(text = "TRAJECTORY ANALYSIS", tabName = "trajectory", icon = icon("route")),
      menuItem(tags$div("LIGAND - RECEPTOR",
                        tags$br(),
                        "ANALYSIS", class = "menu_item_div"), tabName = "ligandReceptor", icon = icon("satellite-dish")), #icon("satellite-dish")),
      menuItem(tags$div("GENE REGULATORY NETWORK",
                        tags$br(),
                        "ANALYSIS", class = "menu_item_div"), tabName = "grn", icon = icon("network-wired")),
      menuItem(text = "TRACKS", tabName = "visualizeTracks", icon = icon("compact-disc")),
      tags$hr(),
      menuItem(text = "Help", tabName = "help", icon = icon("question")),
      menuItem(text = "About", tabName = "about", icon = icon("info"))
    )
  ),
  #------------------------------------------------------------Body
  dashboardBody(
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "main.css")),
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href="loading-bar.css")), # loading bar CSS
    tags$head(tags$script(src = "rshiny_handlers.js")), # R to JS
    tags$head(tags$script(src = "loading-bar.js")), # loading bar JS
    #tags$head(tags$script(src = "sliderfix.js")),


  
  # 自動再接続機能とテーマスイッチのための JavaScript
  tags$head(
    tags$script(HTML('
      // Color theme switching function
      function switchTheme(theme) {
        console.log("Switching theme to:", theme);
        var body = document.body;
        var coolBtn = document.getElementById("theme-cool");
        var warmBtn = document.getElementById("theme-warm");

        if (!coolBtn || !warmBtn) {
          console.error("Theme buttons not found!");
          return;
        }

        if (theme === "warm") {
          body.classList.add("warm-theme");
          coolBtn.classList.remove("theme-btn-active");
          warmBtn.classList.add("theme-btn-active");
          console.log("Warm theme activated");
        } else {
          body.classList.remove("warm-theme");
          warmBtn.classList.remove("theme-btn-active");
          coolBtn.classList.add("theme-btn-active");
          console.log("Cool theme activated");
        }
      }

      $(document).on("shiny:disconnected", function(event) {
        $("#disconnect-overlay").show();
      });

      $(document).on("shiny:connected", function(event) {
        $("#disconnect-overlay").hide();
      });
    ')),
    tags$style(HTML('
      #disconnect-overlay {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-color: rgba(0, 0, 0, 0.5);
        display: none;
        z-index: 9999;
      }
      #disconnect-message {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        color: white;
        font-size: 24px;
      }
    '))
  ),
  
  # 切断オーバーレイを追加
  div(id = "disconnect-overlay",
      div(id = "disconnect-message", "接続が切断されました。再接続中...")
  ),

  # サイドバーが閉じた時のみ表示されるトグルボタン
  tags$div(
    id = "sidebar-reopen-btn",
    class = "sidebar-reopen-toggle",
    onclick = "$('body').toggleClass('sidebar-collapse'); event.preventDefault();",
    tags$i(class = "fa fa-bars")
  ),


    useShinyjs(),
    extendShinyjs(text = js.enrich, functions = c("Enrich")),
    tabItems(
      #home tab
      tabItem(tabName = "home",
              div(id = "home_div", class = "div_container",
                  h1(class = "container_title", "Welcome to SCALA"),
                  HTML("<p class=container_text> SCALA is a web application and stand-alone toolkit, that handles the analysis of scRNA-seq and scATAC-seq datasets,
                  from quality control and normalization, to dimensionality reduction, differential expression/accessibility analysis, cell clustering, functional enrichment analysis,
                  trajectory inference, ligand – receptor analysis, gene regulatory network inference, and visualization. Try out our sample data and visit the Help pages for guidance. </p>"
                  ),
              )
      ),

      #Upload tab
      tabItem(tabName = "upload",
              fluidRow(
                box(
                  width = 5, status = "info", solidHeader = TRUE,
                  title = "Data Input",
                  tabsetPanel(type = "tabs", id = "mainUploadTabs",
                              # Tab 1: Upload
                              tabPanel("Upload",
                                       tabsetPanel(type = "pills",
                                                   tabPanel("Gene-count matrix (scRNA-seq)",
                                       #tags$h3("Load PBMC 10x dataset (example scRNA-seq)", class="h3-example"),
                                       #tags$hr(class="hr-example"),
                                       #actionButton(inputId = "upload10xExampleRNACountMatrixConfirm", label = "Load example", class="btn-example"),
                                       tags$h3("Upload your file"),
                                       #tags$hr(),
                                       textInput(inputId = "uploadCountMatrixprojectID", label = "Project name (!!Needs unique name!!) : ", value = "Project1"),
                                       fileInput(inputId = "countMatrix", label = "Genes-Cells count matrix", accept = c(".txt","tsv",'csv')),
                                        tags$h5("Extension of count matrix file must be txt, tsv, rds or gz."),
                                      tags$h4("OR use a count matrix file on the server"),
                                        shinyFilesButton('localMatrix', label='Choose count matrix file on server', title='Select count matrix file', multiple=FALSE, value = NULL, class="btn btn-warning"),
                                        tags$hr(),
                                        tags$br(),
                                       sliderInput(inputId = "uploadCountMatrixminCells", label = "Include features detected in at least this many cells :", min = 0, max = 20, value = 3, step = 1),

                                       sliderInput(inputId = "uploadCountMatrixminFeatures", label = "Include cells where at least this many features are detected :", min = 0, max = 1000, value = 200, step = 1),
                                       radioButtons("uploadCountMatrixRadioSpecies", label = h3("Select organism : "),
                                                    choices = list("Mus musculus (Mouse)" = "mouse",
                                                                   "Homo sapiens (Human)" = "human"
                                                    ),
                                                    selected = "mouse"),
                                       radioButtons("uploadCountMatrixAssayVersion", label = "Seurat Assay version:",
                                                    choices = list("v5 (recommended)" = "v5",
                                                                   "v4 (legacy)" = "v4"),
                                                    selected = "v5", inline = TRUE),
                                       actionButton(inputId = "uploadCountMatrixConfirm", label = "Submit",class="btn btn-warning"),


                                       ),
                              tabPanel("10x input files (scRNA-seq)",
                                       #tags$h3("Load PBMC 10x dataset (example scRNA-seq)", class="h3-example"),
                                       #tags$hr(class="hr-example"),
                                       #actionButton(inputId = "upload10xExampleRNA10xFilesConfirm", label = "Load example", class="btn-example"),
                                       tags$h3("Upload your files"),
                                       #tags$hr(),
                                       textInput(inputId = "upload10xRNAprojectID", label = "Project name (!!Needs unique name!!) : ", value = "Project1"),
                                       fileInput(inputId = "barcodes", label = "1. Choose barcodes.tsv.gz file", accept = ".gz"),
                                       fileInput(inputId = "genes", label = "2. Choose features.tsv.gz file", accept = ".gz"),
                                       fileInput(inputId = "matrix", label = "3. Choose matrix.mtx.gz file", accept = ".gz"),
                                       sliderInput(inputId = "upload10xRNAminCells", label = "Include features detected in at least this many cells :", min = 0, max = 20, value = 3, step = 1),
                                       sliderInput(inputId = "upload10xRNAminFeatures", label = "Include cells where at least this many features are detected :", min = 0, max = 1000, value = 200, step = 1),
                                       radioButtons("upload10xRNARadioSpecies", label = h3("Select organism : "),
                                                                 choices = list("Mus musculus (Mouse)" = "mouse",
                                                                                "Homo sapiens (Human)" = "human"
                                                                 ), selected = "mouse"),
                                       radioButtons("upload10xRNAAssayVersion", label = "Seurat Assay version:",
                                                    choices = list("v5 (recommended)" = "v5",
                                                                   "v4 (legacy)" = "v4"),
                                                    selected = "v5", inline = TRUE),
                                       actionButton(inputId = "upload10xRNAConfirm", label = "Submit",class="btn btn-warning"),
                                       tags$hr(),
                                       tags$h3("OR use 10x files on the server"),

                                        shinyDirButton('local10XFolder', label='Choose 10X folder on server', title='Select 10X file folder', multiple=FALSE),

                                            tags$hr(),
                                       actionButton(inputId = "uploadLocal10xFolderConfirm", label = "Load from server 10x folder",class="btn btn-warning"),

                                           tags$br(),
                                       tags$h4("OR select each 10x file on the server"),

                                       shinyFilesButton('locaBarcodesfile', label='Choose barcodes file on server', title='Select barcodes file', multiple=FALSE),
                                       shinyFilesButton('locaFeaturesfile', label='Choose features file on server', title='Select features file', multiple=FALSE),
                                       shinyFilesButton('locaMatrixfile', label='Choose matrix file on server', title='Select matrix file', multiple=FALSE),
                                          tags$br(),

                                            tags$hr(),
                                       actionButton(inputId = "uploadLocal10xConfirm", label = "Load server 10x files",class="btn btn-warning"),

                                       tags$hr(),
                                       tags$h3("OR select multiple folders containing 10x files on the server"),
                                        shinyDirButton('Multiple10XFolder', label='Choose a parent folder on server', title='Select the folder', multiple=TRUE),
                                        tags$br(),

                                        actionButton(inputId = "upload10xMultiAdd", label = "Add the selected folder", class="btn-info"),
                                        actionButton(inputId = "upload10xMultiConfirm", label = "Add the folder and RUN",class="btn btn-warning"),
                                        tags$br(),
                                         tags$hr(),
                                       tags$div(
                                         style = "background-color: #d1ecf1; padding: 15px; border-radius: 5px; margin: 15px 0; border-left: 4px solid #17a2b8;",
                                         tags$p(
                                           style = "margin: 0; color: #0c5460;",
                                           tags$b("Note:"), " If you are using ", tags$b("raw_feature_bc_matrix"), " data:",
                                           tags$br(),
                                           "1. Set 'Include cells where at least this many features are detected' to ", tags$b("0"), " when loading the data.",
                                           tags$br(),
                                           "2. After loading, go to ", tags$b("QUALITY CONTROL"), " tab and use the ", tags$b("emptyDrops"), " filter to remove empty droplets."
                                         )
                                       ),
                                       ),

                             tabPanel("10x feature_bc_matrix.h5, cellbender output_filtered.h5",
                                       textInput(inputId = "CellBenderProjectID", label = "Project name (!!Needs unique name!!) : ", value = "Project1"),
                                       tags$h3("Upload your h5 file"),
                                       fileInput(inputId = "CellBenderFile", label = "output_filtered.h5 file", accept = ".h5"),
                                       sliderInput(inputId = "uploadCellBenderminCells", label = "Include features detected in at least this many cells :", min = 0, max = 20, value = 3, step = 1),
                                       sliderInput(inputId = "uploadCellBenderminFeatures", label = "Include cells where at least this many features are detected :", min = 0, max = 1000, value = 200, step = 1),
                                       radioButtons("uploadCellBenderSpecies", label = h3("Select organism : "),
                                                                 choices = list("Mus musculus (Mouse)" = "mouse",
                                                                                "Homo sapiens (Human)" = "human"
                                                                 ), selected = "mouse"),
                                       radioButtons("uploadCellBenderAssayVersion", label = "Seurat Assay version:",
                                                    choices = list("v5 (recommended)" = "v5",
                                                                   "v4 (legacy)" = "v4"),
                                                    selected = "v5", inline = TRUE),
                                       actionButton(inputId = "uploadCellBenderConfirm", label = "Submit",class="btn btn-warning"),

                                       tags$hr(),
                                       tags$h3("OR use server h5 files"),
                                       shinyFilesButton('localh5file', label='Choose h5 files on server', title='Select H5AD file', multiple=TRUE),
                                       actionButton(inputId = "uploadLocalCellBenderConfirm", label = "Load server h5",class="btn btn-warning"),
                                       ),

                              tabPanel("Seurat/SCE object RDS, qs/qs2, RData, h5Seurat (scRNA-seq)",
                                       tags$h3("Upload your RDS, qs/qs2, or RData file"),
                                     radioButtons("uploadRdsRadioSpecies", label = h3("Select organism : "),
                                                    choices = list("Mus musculus (Mouse)" = "mouse",
                                                                   "Homo sapiens (Human)" = "human"   ),
                                                    selected = "mouse"),
                                       fileInput(inputId = "uploadRdsFile", label = "Choose a Seurat object in RDS, qs/qs2, RData, rda, Robj, or H5Seurat format", accept = c(".RDS",".RDATA",".rda",".Rda",".Robj",".robj",".h5SEURAT",".qs", ".qs2")),
                                      actionButton(inputId = "uploadSeuratRdsConfirm", label = "Load Seurat object",class="btn btn-warning"),

                                       tags$hr(),
                                       tags$h3("OR use a server RDS/qs file"),
                                       shinyFilesButton('localRDSfile', label='Choose an RDS/qs/RData/rda/Robj file on server', title='Select RDS/qs/RData/rda/Robj file', multiple=FALSE, class="btn btn-info"),
                                       actionButton(inputId = "uploadLocalRdsConfirm", label = "Load server RDS/qs/qs2",class="btn btn-warning"),
                                      checkboxInput("seuratdecimal", strong("Counts include decimals"), FALSE),
                                       ),
                              tabPanel("h5ad file (anndata)　　　　　　　　",
                       tags$h3("Upload your h5ad file"),
                                               radioButtons("uploadAnndataRadioSpecies", label = h3("Select organism : "),
                            choices = list("Mus musculus (Mouse)" = "mouse",
                                           "Homo sapiens (Human)" = "human"
                            ),
                            selected = "mouse"),

                                        radioButtons("slotinh5ad", label = h4("Choose the data stored in main h5ad data slot (.X):"),
                                                    choices = list("Normalized data" = "data",
                                                                   "Raw counts" = "counts" ),                            selected = "data"),
                                       tags$h5("Usually data. Raw counts are integers."),
                                       fileInput(inputId = "uploadAnndataFile", label = "Choose an anndata/scanpy object saved in .h5ad format", accept = ".h5ad"),

                                       actionButton(inputId = "uploadSeuratAnndataConfirm", label = "Load Anndata object",class="btn btn-warning"),
                                       tags$hr(),
                                       tags$h3("OR use a server H5AD file"),
                                       shinyFilesButton('localH5ADfile', label='Choose an H5AD file on server', title='Select H5AD file', multiple=FALSE),
                                       actionButton(inputId = "uploadLocalAnndataConfirm", label = "Load server H5AD",class="btn btn-warning"),

                                       tags$hr(),
                                       # ============================================================
                                       # H5AD File Structure Options
                                       # h5adファイルの構造に関するオプション
                                       # ============================================================
                                       tags$h4(
                                         tags$strong("H5AD File Structure Options"),
                                         actionLink("h5adStructureHelp", icon("question-circle"), style = "margin-left: 8px;")
                                       ),
                                       checkboxInput("h5adXtoCounts", strong("Load X as counts"), FALSE),

                                       tags$hr(),
                                       # ============================================================
                                       # COMPASS metabolic analysis data
                                       # COMPASSデータの読み込みについて
                                       # ============================================================
                                       checkboxInput("h5adCompassData", tags$strong("COMPASS metabolic analysis data"), FALSE),
                                       conditionalPanel(
                                         condition = "input.h5adCompassData == true",
                                         tags$div(
                                           style = "background-color: #f0f7ff; padding: 10px; border-radius: 5px; margin-bottom: 10px;",
                                           tags$p(tags$strong("metisでCOMPASS解析を行った場合:")),
                                           tags$ul(
                                             tags$li("COMPASS h5adファイルを通常のh5adとして読み込み可能"),
                                             tags$li("反応(reactions)が「遺伝子」として扱われる"),
                                             tags$li("COMPASSスコアはdata slotに格納される"),
                                             tags$li(tags$em("「Load X as counts」は自動的にOFFになります"), "（スコアは正規化済み）"),
                                             tags$li("FeaturePlot, VlnPlot, FindMarkers等で解析可能")
                                           ),
                                           tags$p(tags$small("Reference: Wagner et al. (2021) Cell"))
                                         )
                                       ),

                                       tags$hr(),
                                       tags$h3("Convert gene names"),
                                       tags$h5("If gene rownames are Ensembl IDs (ENSMUSG...), convert them to gene symbols."),
                                       selectInput("h5adGeneNameColumn", "Select gene name column from meta.features:",
                                                   choices = c("-" = "none"), multiple = FALSE),
                                       actionButton(inputId = "convertH5adGeneNames", label = "Convert to gene symbols", class="btn btn-info"),

                                       tags$hr(),
                                       tags$h3("Aggregate duplicate genes"),
                                       tags$h5("Aggregate genes with duplicate symbols using the 'gene.symbol' column."),
                                       tags$p("This function uses the 'gene.symbol' column in meta.features (original gene names before make.unique) to identify and aggregate duplicates. Rownames will be updated to unique gene symbols."),
                                       radioButtons("aggregateDuplicatesMethod",
                                                   label = "Aggregation method:",
                                                   choices = list("Mean counts/data" = "mean",
                                                                  "Sum counts/data" = "sum"),
                                                   selected = "mean"),
                                       actionButton(inputId = "aggregateDuplicateGenes",
                                                   label = "Aggregate duplicate genes",
                                                   class="btn btn-warning"),

                                       ),
                                  # https://stackoverflow.com/questions/36850114/uploading-many-files-in-shiny

                              tabPanel("Merge multiple RDS/qs/qs2 files　　　　　　　　",
                                tags$h3("Upload your RDS files"),
                                       radioButtons("uploadMultiRdsRadioSpecies", label = h3("Select organism : "),
                                                    choices = list("Mus musculus (Mouse)" = "mouse",
                                                                   "Homo sapiens (Human)" = "human"
                                                    ), selected = "mouse"),
                                       fileInput(inputId = "uploadMultiRdsFile", label = "Choose Seurat objects RDS/qs/qs2 files", accept = c(".RDS",".qs", ".qs2"), multiple = TRUE),
                                       actionButton(inputId = "addMultiRdsFiles", label = "Add Files to List", class="btn btn-primary"),
                                       tags$br(),
                                       tags$br(),
                                       tags$h4("Accumulated files:"),
                                       verbatimTextOutput("uploadedFilesList"),
                                       tags$br(),
                                       fluidRow(
                                         column(6, actionButton(inputId = "clearMultiRdsFiles", label = "Clear All Files", class="btn btn-danger")),
                                         column(6,
                                           numericInput(inputId = "removeFileIndex", label = "Remove file # (enter number):", value = NULL, min = 1),
                                           tags$style(type="text/css", "#removeFileIndex { margin-top: 0px; }")
                                         )
                                       ),
                                       tags$br(),
                                       actionButton(inputId = "uploadMultiSeuratRdsConfirm", label = "Load Seurat objects",class="btn btn-warning"),
                                       tags$hr(),
                                       tags$h3("OR use server RDS/qs/qs2 files"),
                                       shinyFilesButton('MultiLocalRdsfile', label='Choose RDS/qs/qs2 files on server', title='Select RDS files', multiple=TRUE,class="btn btn-info"),
                                       tags$br(),
                                       tags$br(),
                                       actionButton(inputId = "addMultiServerFiles", label = "Add Server Files to List", class="btn btn-primary"),
                                       tags$br(),
                                       tags$br(),
                                       tags$h4("Accumulated server files:"),
                                       verbatimTextOutput("serverFilesList"),
                                       tags$br(),
                                       fluidRow(
                                         column(6, actionButton(inputId = "clearMultiServerFiles", label = "Clear All Server Files", class="btn btn-danger")),
                                         column(6,
                                           numericInput(inputId = "removeServerFileIndex", label = "Remove server file # (enter number):", value = NULL, min = 1),
                                           tags$style(type="text/css", "#removeServerFileIndex { margin-top: 0px; }")
                                         )
                                       ),
                                       tags$br(),
                                       actionButton(inputId = "uploadMultiLocalRdsConfirm", label = "Load server RDS/qs/qs2",class="btn btn-warning"),
                                       tags$br(),
                                      tags$br(),
                                       tags$h2("Data integration:"),
                                      tags$hr(),
                                       tags$h4("Just merge Seurat objects as are."),
                                       tags$h5("You can skip to batch correction without simple merge"),
                                       actionButton(inputId = "SimpleMerge", label = "Run normalization, scaling and PCA on the merged data"),
                                      tags$h4("OR you can perform each step individually."),
                                       ),
                             tabPanel("10x spatial on v5",
                                       textInput(inputId = "visium_id", label = "Project name (!!Needs unique name!!) : ", value = "Project1"),
                                       radioButtons("uploadVisiumSpecies", label = h3("Select organism : "),
                                                                 choices = list("Mus musculus (Mouse)" = "mouse",
                                                                                "Homo sapiens (Human)" = "human"
                                                                 ), selected = "mouse"),
                                       tags$h3("Select visium outs folder"),
                                       tags$h4("'outs' forlder to load multiple bins as layers or individual binned_outputs folder containing filtered_feature_bc_matrix.h5."),

                                        shinyDirButton('SpatialFolder', label='Choose visium output folder', title='Select the folder', multiple=FALSE),
                                        tags$h5("フォルダーの選択は左側のカラムで"),
                                        tags$br(),
                                        checkboxInput("Load2um", "Load 2 um data? This takes a very long time.", FALSE),

                                        actionButton(inputId = "uploadVisium", label = "Upload visium", class="btn-info"),
                                       ),
                              tabPanel("Arrow input files (scATAC-seq)",
                                       tags$h3("PBMC 10x dataset (example scATAC-seq)", class="h3-example"),
                                       tags$hr(class="hr-example"),
                                       actionButton(inputId = "upload10xExampleATACConfirm", label = "Load example", class="btn-example"),
                                       tags$h3("Upload your file"),
                                       tags$hr(),
                                       textInput(inputId = "uploadATACprojectID", label = "Project name : ", value = "Project1"),
                                       fileInput(inputId = "uploadATACArrow", label = "Please upload an .arrow file", accept = ".arrow"),
                                       radioButtons("upload10xATACRadioSpecies", label = h3("Select organism and genome version: "),
                                                    choices = list("Mus musculus (Mouse) - mm10" = "mm10",
                                                                   "Homo sapiens (Human) - hg19" = "hg19",
                                                                   "Homo sapiens (Human) - hg38" = "hg38"
                                                    ),
                                                    selected = "mm10"),
                                       sliderInput(inputId = "upload10xATACThreads", label = "Threads to be used:", min = 1, max = 2, value = 2, step = 1),
                                       actionButton(inputId = "upload10xATACConfirm", label = "Submit")
                              )
                                       ) # End of Upload tabsetPanel
                              ), # End of Upload tabPanel

                              # Tab 2: Batch Correction
                              tabPanel("Batch",
                                      tags$h2("Data integration with batch effect correction"),
                                       tags$br(),
                                      selectInput(inputId = "BatchIdent", label = "Choose identity upon which data are integrated:",
                                          c("Cluster" = "orig.ident")),

                                       checkboxInput("fastMNNAutoMerge", "Estimate best matching order for fastMNN?", TRUE),
                                       tags$hr(),
                                        tags$h4("SCTransform:"),
                                      checkboxInput("SCTfastMNN", "Use SCT", FALSE),
                                      tags$h4("Regress out covariables. For fastMNN only works with SCT."),
                                       # checkboxInput("SCTmito", "Regress out percent.mt?", FALSE),
                                  radioButtons("Fastmnncellcycleregress", label = "Regress out cell cycle scores?",
                                choices = list("No" = "none", "All cell cycle" = "all", "Difference in G2M/S only (for hematopoisis)" = 'g2m'), selected = 'none'),
                                 tags$br(),
                                 selectInput("FastmnnnormalizeRegressColumns", "Select variables to regress out for SCT (ex, percent.mt)", list(), selected = NULL, multiple = TRUE, selectize = TRUE, width = NULL, size = NULL),

                                               checkboxInput("KeepReduct", "Keep reducton data (PCA etc)", TRUE),
                                               checkboxInput("UseData", "Use existing data slot (If counts slot is empty, check this)", FALSE),
                                    actionButton(inputId = "fastMNNintegration", label = "fastMNN-integration",class="btn btn-warning"),
                                    tags$br(),
                                    tags$h3(' '),
                                    actionButton(inputId = "harmonyintegration", label = "Harmony-integration",class="btn btn-warning"),
                                                                        tags$br(),
                                    tags$h3(' '),
                                actionButton(inputId = "scanoramaintegration", label = "scanorama-integration",class="btn btn-warning"),
                                  tags$h3(' '),
                                  tags$h5("scVI uses count data. SCT normalization and covariates will be ignored."),
                                actionButton(inputId = "scVIintegration", label = "scVI-integration",class="btn btn-warning"),
                                tags$h5("scVI: ~10 min/20000 cells"),
                                 tags$hr(),
                                    tags$br(),
                                    actionButton(inputId = "iRECODE", label = "iRECODE-integration",class="btn btn-warning"),
                                    tags$h5("iRECODE tutorial uses unfiltered (non-QCed) data."),
                                          tags$hr(),
                                    tags$br(),
                                       tags$h4("Integration with Seurat."),
                                       actionButton(inputId = "Seuratintegration", label = "Seurat-integration",class="btn btn-warning"),

                                tags$hr(),
                                tags$h3('Integration methods:'),
                                tags$h5('PCAならびにUMAP等でバッチによる影響が見られない場合はbatch correctionは不要'),
                                tags$h5('fastMNN, Harmony, ScanoramaはRNA(normalized counts)あるいはSCTのデータを用いて解析可能'),
                                tags$h6('SCTではpercent.mtをregress outしてもよいかもしれない'),
                                tags$h5('CLUSTERINGではAssayとReductionの正しい組み合わせを選ぶ。eg, RNA-mnn, SCT-mnn'),
                                tags$h5('ClusteringとUMAPに用いたReductionも一致する必要がある'),
                                tags$h4('これらの手法は基本的にクラスタリングのための手法でDEG等には使用できない'),
                                tags$h4('Vln PlotやDEG解析等ではactive assayをRNAに戻すこと→UTILITY IDENTITY & ASSAY'),
tags$h5('https://genomebiology.biomedcentral.com/articles/10.1186/s13059-019-1850-9, https://www.nature.com/articles/s41592-021-01336-8 ')
                              ), # End of Batch tabPanel

                              # Tab 3: CellBender
                              tabPanel("CellBender",
                                       tags$h2("CellBender remove-background"),
                                       tags$br(),
                                       tags$h4("Run CellBender to remove ambient RNA contamination from raw 10x data"),
                                       tags$hr(),

                                       # Input file section
                                       tags$h3("1. Input raw data"),
                                       tags$h5("Select raw_feature_bc_matrix.h5 file from 10x CellRanger output"),
                                       fileInput(inputId = "CellBenderRawFile", label = "Upload raw_feature_bc_matrix.h5", accept = ".h5"),

                                       tags$h4("OR select raw h5 file on server"),
                                       shinyFilesButton('CellBenderRawFileServer', label='Choose raw h5 file on server', title='Select raw_feature_bc_matrix.h5', multiple=FALSE, class="btn btn-info"),
                                       tags$br(),
                                       tags$br(),

                                       tags$hr(),

                                       # Output directory section
                                       tags$h3("2. Output directory"),
                                       tags$h5("Specify where to save CellBender output files"),
                                       shinyDirButton('CellBenderOutputDir', label='Choose output folder', title='Select output directory', multiple=FALSE, class="btn btn-info"),
                                       tags$br(),
                                       tags$br(),
                                       textInput(inputId = "CellBenderOutputName", label = "Output file prefix:", value = "cellbender_output"),

                                       tags$hr(),

                                       # Parameters section
                                       tags$h3("3. CellBender parameters"),

                                       numericInput(inputId = "CellBenderExpectedCells",
                                                    label = "Expected number of cells:",
                                                    value = 5000,
                                                    min = 100,
                                                    max = 50000,
                                                    step = 100),
                                       tags$h6("Estimated number of real cells in the dataset"),

                                       numericInput(inputId = "CellBenderTotalDroplets",
                                                    label = "Total droplets to include:",
                                                    value = 15000,
                                                    min = 1000,
                                                    max = 100000,
                                                    step = 1000),
                                       tags$h6("Total number of droplets to use (including empty droplets). Should be larger than expected cells."),

                                       numericInput(inputId = "CellBenderEpochs",
                                                    label = "Number of epochs:",
                                                    value = 150,
                                                    min = 50,
                                                    max = 500,
                                                    step = 10),
                                       tags$h6("Training epochs. Default 150 is usually sufficient."),

                                       numericInput(inputId = "CellBenderLearningRate",
                                                    label = "Learning rate:",
                                                    value = 0.0001,
                                                    min = 0.00001,
                                                    max = 0.001,
                                                    step = 0.00001),
                                       tags$h6("Learning rate for training. Default 1e-4."),

                                       checkboxInput(inputId = "CellBenderUseCUDA",
                                                     label = "Use GPU (CUDA) if available",
                                                     value = TRUE),
                                       tags$h6("Requires CUDA-enabled GPU and proper installation."),

                                       numericInput(inputId = "CellBenderFPR",
                                                    label = "FPR threshold (False Positive Rate):",
                                                    value = 0.01,
                                                    min = 0.001,
                                                    max = 0.1,
                                                    step = 0.001),
                                       tags$h6("Target false positive rate for removing empty droplets. Lower = more stringent."),

                                       tags$hr(),

                                       # Run button
                                       tags$h3("4. Run CellBender"),
                                       actionButton(inputId = "RunCellBender",
                                                    label = "Run CellBender remove-background",
                                                    class = "btn btn-warning",
                                                    icon = icon("play")),
                                       tags$br(),
                                       tags$br(),
                                       tags$h5("Note: CellBender may take 30-60 minutes depending on data size and hardware."),

                                       tags$hr(),

                                       # Progress and log section
                                       tags$h3("Progress"),
                                       div(class="ldBar", id="cellbender_loader", "data-preset"="circle"),
                                       textOutput("CellBenderStatus"),
                                       tags$br(),
                                       tags$h4("CellBender Output (last 10 lines):"),
                                       tags$div(
                                         style = "max-height: 250px; overflow-y: auto; background-color: #f5f5f5; border: 1px solid #ddd; border-radius: 4px; padding: 10px; font-family: monospace; font-size: 12px;",
                                         verbatimTextOutput("CellBenderLog", placeholder = TRUE)
                                       ),

                                       tags$hr(),

                                       # Info
                                       tags$h4("Output files:"),
                                       tags$h5("CellBender will generate:"),
                                       tags$ul(
                                         tags$li("output_filtered.h5 - cleaned count matrix (use this for downstream analysis)"),
                                         tags$li("output.h5 - full output including all droplets"),
                                         tags$li("output_cell_barcodes.csv - list of cell barcodes"),
                                         tags$li("output.pdf - diagnostic plots")
                                       ),
                                       tags$br(),
                                       downloadButton(outputId = "downloadCellBenderResults",
                                                     label = "Download Results (filtered.h5, log, pdf)",
                                                     class = "btn btn-info",
                                                     icon = icon("download")),
                                       tags$hr(),
                                       tags$h5("Reference: https://github.com/broadinstitute/CellBender"),
                                       tags$h5("After completion, load the output_filtered.h5 file using the Upload tab.")
                              ), # End of CellBender tabPanel

                              # Tab 4: Velocyto
                              tabPanel("Velocyto",
                                       tags$h2("Velocyto - RNA Velocity Analysis"),
                                       tags$hr(),

                                       tags$h4("Generate spliced/unspliced count matrices for RNA velocity analysis"),

                                       # Workflow explanation
                                       tags$div(
                                         style = "background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 15px; border-left: 4px solid #6c757d;",
                                         tags$h4("Workflow:", style = "margin-top: 0;"),
                                         tags$ol(
                                           style = "margin-bottom: 0;",
                                           tags$li(tags$b("Select BAM file(s):"), " Provide BAM file(s) from Cell Ranger to calculate spliced/unspliced counts."),
                                           tags$li(tags$b("Integration with Seurat:"), " Cell name matching and integration with Seurat object should be performed in ", tags$b("metis"), " or other downstream tools."),
                                           tags$li(tags$b("For hashtag multiplexing:"), " You can either process BAM files individually or process multiple files together (from ", tags$code("per_sample_outs/"), " directory)."),
                                           tags$li(
                                             tags$span(style = "color: #dc3545;", tags$b("IMPORTANT:")),
                                             " ", tags$b("Do NOT process BAM files from different libraries together."), " Run velocyto separately for each library."
                                           )
                                         )
                                       ),

                                       tags$hr(),

                                       # BAM File Input Section
                                       tags$h4("1. Select BAM File(s)"),
                                       tags$div(
                                         style = "background-color: #e7f3ff; padding: 10px; border-radius: 5px; margin-bottom: 10px; border-left: 4px solid #2196F3;",
                                         tags$p(
                                           style = "margin: 0; font-size: 0.9em;",
                                           tags$b("Typical Cell Ranger BAM files:"),
                                           tags$br(),
                                           "• ", tags$code("possorted_genome_bam.bam"), " (cellranger count output)",
                                           tags$br(),
                                           "• ", tags$code("gex_possorted_bam.bam"), " (cellranger multi GEX library)",
                                           tags$br(),
                                           "• ", tags$code("per_sample_outs/[sample]/count/sample_alignments.bam"), " (cellranger multi with hashtag, demultiplexed)"
                                         )
                                       ),
                                       fluidRow(
                                         column(6,
                                                tags$h5("Upload from PC:"),
                                                fileInput(inputId = "velocytoBAMupload",
                                                          label = "Select BAM file(s)",
                                                          multiple = TRUE,
                                                          accept = c(".bam"))
                                         ),
                                         column(6,
                                                tags$h5("Or select from server:"),
                                                shinyFilesButton(id = "velocytoBAMfiles",
                                                              label = "Select BAM file(s)",
                                                              title = "Select BAM files (multiple selection allowed)",
                                                              multiple = TRUE,
                                                              class = "btn btn-default"),
                                                tags$br(), tags$br(),
                                                verbatimTextOutput("velocytoBAMfilesPath")
                                         )
                                       ),

                                       tags$hr(),

                                       # GTF File Selection
                                       tags$h4("2. Select GTF Annotation File"),
                                       tags$div(
                                         style = "background-color: #fff3cd; padding: 10px; border-radius: 5px; margin-bottom: 10px; border-left: 4px solid #ffc107;",
                                         tags$p(
                                           style = "margin: 0; font-size: 0.9em;",
                                           tags$b("Tip:"), " You can check which genome version was used in Cell Ranger by viewing the ",
                                           tags$b("web_summary.html"), " file in your Cell Ranger output directory."
                                         )
                                       ),
                                       selectInput("velocytoGTFsource",
                                                  label = "Select reference genome:",
                                                  choices = list(
                                                    "Human GRCh38 (2024-A)" = "GRCh38-2024",
                                                    "Human GRCh38 (2020-A)" = "GRCh38-2020",
                                                    "Mouse GRCm39 (2024-A)" = "GRCm39-2024",
                                                    "Mouse mm10 (2020-A)" = "mm10-2020",
                                                    "Custom GTF file" = "custom"
                                                  ),
                                                  selected = "mm10-2020"),
                                       conditionalPanel(
                                         condition = "input.velocytoGTFsource == 'custom'",
                                         shinyFilesButton(id = "velocytoGTFfile",
                                                         label = "Select GTF file",
                                                         title = "Select GTF annotation file",
                                                         multiple = FALSE,
                                                         class = "btn btn-default"),
                                         tags$br(), tags$br(),
                                         verbatimTextOutput("velocytoGTFfilePath")
                                       ),
                                       verbatimTextOutput("velocytoSelectedGTF"),

                                       tags$hr(),

                                       # Advanced Options
                                       tags$h4("3. Advanced Options"),
                                       checkboxInput("velocytoUseMask", "Use mask GTF (recommended for repeat regions)", value = FALSE),
                                       conditionalPanel(
                                         condition = "input.velocytoUseMask == true",
                                         shinyFilesButton(id = "velocytoMaskGTF",
                                                         label = "Select mask GTF file",
                                                         title = "Select mask GTF file",
                                                         multiple = FALSE,
                                                         class = "btn btn-default"),
                                         tags$br(), tags$br(),
                                         verbatimTextOutput("velocytoMaskGTFPath")
                                       ),

                                       numericInput("velocytoThreads", "Number of threads:", value = 24, min = 1, max = 32, step = 1),

                                       tags$hr(),

                                       # Run Button
                                       actionButton(inputId = "RunVelocyto",
                                                   label = "Run Velocyto",
                                                   class = "btn btn-warning btn-lg",
                                                   icon = icon("rocket")),
                                       tags$br(), tags$br(),

                                       # Status and Progress
                                       tags$h3("Progress"),
                                       verbatimTextOutput("velocytoStatus"),
                                       tags$br(),
                                       tags$h4("Velocyto Output (last 10 lines):"),
                                       tags$div(
                                         style = "max-height: 250px; overflow-y: auto; background-color: #f5f5f5; border: 1px solid #ddd; border-radius: 4px; padding: 10px; font-family: monospace; font-size: 12px;",
                                         verbatimTextOutput("velocytoLogOutput", placeholder = TRUE)
                                       ),

                                       tags$hr(),

                                       # Download Section
                                       tags$h4("4. Download Results"),
                                       tags$p("After velocyto completes, download the .loom file(s) as ZIP archive for downstream analysis:"),
                                       downloadButton(outputId = "downloadVelocytoOriginal",
                                                     label = "Download .loom files (ZIP)",
                                                     class = "btn btn-success"),
                                       tags$br(), tags$br(),
                                       tags$p("Use this file with scVelo (Python) or Seurat velocity workflow for RNA velocity analysis."),

                                       tags$hr(),

                                       tags$div(
                                         style = "background-color: #d1ecf1; padding: 15px; border-radius: 5px; margin: 15px 0; border-left: 4px solid #17a2b8;",
                                         tags$p(
                                           style = "margin: 0; color: #0c5460;",
                                           tags$b("Note:"), " Velocyto processing can take a long time (hours) depending on BAM file size.",
                                           tags$br(),
                                           "The analysis will run in the background. You cannot use other SCALA functions during processing.",
                                           tags$br(),
                                           "Required: BAM files must have CB (cell barcode) and UB (UMI barcode) tags.",
                                           tags$br(),
                                           tags$b("Reference:"), " ", tags$a(href="http://velocyto.org/", "velocyto.org", target="_blank")
                                         )
                                       )
                              ) # End of Velocyto tabPanel
                  ) # End of mainUploadTabs tabsetPanel
                ),
                box(
                  width = 7, solidHeader = TRUE, status = "info",
                  title = uiOutput("data_input_box_title"),
                  div(class="ldBar", id="input_loader", "data-preset"="circle"),

                  # Show CellBender info when CellBender tab is selected
                  conditionalPanel(
                    condition = "input.mainUploadTabs == 'CellBender'",
                    tags$div(
                      style = "padding: 20px;",
                      tags$h5("Ambient RNA除去方法の比較:"),
                      tags$div(
                        style = "background-color: #e7f3ff; padding: 15px; border-radius: 5px; margin: 15px 0; border-left: 4px solid #2196F3;",
                        tags$p(tags$b(style = "color: #2196F3; font-size: 1.1em;", "CellBender - 標準的な第一選択")),
                        tags$ul(
                          tags$li("最も正確なバックグラウンドノイズレベルの推定を提供し、細胞間変動も適切に捉える"),
                          tags$li("細胞タイプ構成と汚染源に対して最も堅牢な性能"),
                          tags$li("深層学習ベースで全遺伝子を補正")
                        )
                      ),
                      tags$div(
                        style = "background-color: #f0f0f0; padding: 15px; border-radius: 5px; margin: 15px 0; border-left: 4px solid #9E9E9E;",
                        tags$p(tags$b(style = "color: #666; font-size: 1.1em;", "SoupX - 高速スクリーニング用")),
                        tags$ul(
                          tags$li("細胞間変動を捉えられず、全体レベルを過小評価する傾向"),
                          tags$li("事前の細胞クラスタリングが必要"),
                          tags$li(tags$span(style = "color: #666;", "※ UTILITY DATA MANIPULATION メニューで利用可能"))
                        )
                      ),
                      tags$div(
                        style = "background-color: #f0f0f0; padding: 15px; border-radius: 5px; margin: 15px 0; border-left: 4px solid #9E9E9E;",
                        tags$p(tags$b(style = "color: #666; font-size: 1.1em;", "scCDC - 高汚染マーカー遺伝子対策")),
                        tags$ul(
                          tags$li("汚染原因遺伝子(GCGs)のみを検出・補正し、他の遺伝子を改変しない"),
                          tags$li("高汚染遺伝子に効果的で、ハウスキーピング遺伝子の過剰補正を回避"),
                          tags$li("事前の細胞クラスタリングが必要"),
                          tags$li("空ドロップレットデータ不要"),
                          tags$li(tags$span(style = "color: #666;", "※ UTILITY DATA MANIPULATION メニューで利用可能"))
                        )
                      ),

                      tags$h5("CellBenderについて"),
                      tags$p("CellBenderは、シングルセルRNA-seqデータから技術的アーティファクト(ambient RNAなど)を除去するツールです。"),

                      tags$h5("処理手順:"),
                      tags$ol(
                        tags$li(tags$b("10x結果の確認:"), " Cell Ranger等の出力ファイル(web_summary.html または metrics_summary.csv)を確認します。"),
                        tags$li(tags$b("Expected number of cells の決定:"), " 「Estimated Number of Cells」の値を確認し、その値を入力します。正確である必要はなく、2倍程度の誤差は許容されます。"),
                        tags$li(tags$b("Total droplets to include の決定:"), " 一般的には Expected cells の 2〜3倍の値を設定します。例: Expected cells が 5,000 の場合、Total droplets は 10,000〜15,000 程度。"),
                        tags$li(tags$b("raw_feature_bc_matrix.h5 の選択:"), " Cell Ranger の出力フォルダから raw_feature_bc_matrix.h5 ファイル(filtered ではない)を選択します。"),
                        tags$li(tags$b("実行:"), " Run CellBender ボタンをクリックして処理を開始します。処理時間は20〜60分程度です。")
                      ),

                      tags$h5("重要なパラメータ:"),
                      tags$div(
                        style = "background-color: #fff3cd; padding: 10px; border-radius: 5px; margin: 10px 0;",
                        tags$p(
                          style = "margin: 0;",
                          tags$b("注意:"), " Expected number of cells と Total droplets to include は",
                          tags$span(style = "color: #d9534f; font-weight: bold;", "データセットごとに必ず調整する必要があります。"),
                          " デフォルト値をそのまま使用しないでください。"
                        )
                      ),

                      tags$h5("10x結果からのパラメータ読み取り方法:"),
                      tags$div(
                        style = "background-color: #f8f9fa; padding: 10px; border-radius: 5px; margin: 10px 0;",
                        tags$p(tags$b("Cell Ranger web_summary.html の場合:")),
                        tags$ul(
                          tags$li(tags$b("Expected number of cells:"), " 「Estimated Number of Cells」の値を使用(2倍程度の誤差は許容)"),
                          tags$li(tags$b("Total droplets to include:"), " Expected cells の 2〜3倍の値を設定"),
                          tags$li("例: Estimated Number of Cells = 5,247 の場合 → Expected cells = 5000〜5500, Total droplets = 10000〜15000")
                        ),
                        tags$p(tags$b("その他のパラメータ(通常は変更不要):")),
                        tags$ul(
                          tags$li(tags$b("FPR:"), " False Positive Rate = 0.01 (デフォルト)"),
                          tags$li(tags$b("Epochs:"), " 学習の反復回数 = 150 (デフォルト)"),
                          tags$li(tags$b("Learning rate:"), " 最適化のステップサイズ = 0.0001 (デフォルト)")
                        )
                      ),

                      tags$h5("UMI curve の読み方:"),
                      tags$div(
                        style = "text-align: center; margin: 15px 0;",
                        tags$img(src = "https://cellbender.readthedocs.io/en/latest/_images/UMI_curve_defs.png",
                                 style = "max-width: 333px; width: 100%; border: 1px solid #ddd; border-radius: 5px;",
                                 alt = "UMI curve example",
                                 onerror = "this.style.display='none'; this.nextSibling.style.display='block';"),
                        tags$p(
                          style = "display: none; color: #666; font-style: italic;",
                          "※ UMI curveの図: X軸はドロップレットID(カウント順)、Y軸はUMI count。急な下降部分が実際の細胞、平坦部分が空のドロップレット。"
                        )
                      ),
                      tags$ul(
                        tags$li(tags$b("Probable cells (急な下降部分):"), " 実際の細胞を含むドロップレット。高いUMI countを持つ。"),
                        tags$li(tags$b("Empty droplet plateau (平坦部分):"), " 空のドロップレットまたはambient RNAのみを含むドロップレット。"),
                        tags$li(tags$b("Expected cells の設定:"), " 急な下降が終わる付近のドロップレット数(図の例: 約5,000)。"),
                        tags$li(tags$b("Total droplets の設定:"), " Empty droplet plateauを十分に含む範囲(図の例: 15,000〜20,000)。")
                      ),

                      tags$h5("出力ファイル:"),
                      tags$p("CellBenderは .h5 形式のフィルタリング済みカウントマトリクスを生成します。処理完了後、Upload タブで cellbender_output_filtered.h5 ファイルを読み込んでください。"),
                      tags$p(tags$b("注意:"), " 処理時間はデータセットサイズとエポック数により20〜60分程度かかります。progress circle が表示されている間は他のメニューに移動できません。")
                    )
                  ),

                  # Show metadata table when Upload/Batch tabs are selected
                  conditionalPanel(
                    condition = "input.mainUploadTabs != 'CellBender'",
                    tabsetPanel(type = "tabs", id = "uploadTabPanel",
                                tabPanel("scRNA-seq",
                                         dataTableOutput("metadataTable"),
                                         downloadButton(outputId = "uploadMetadataExportRNA", label = "Save table"),
                                         imageOutput("iRECODE_plot")
                                ),
                                tabPanel("scATAC-seq",
                                         dataTableOutput("metadataTableATAC"),
                                         downloadButton(outputId = "uploadMetadataExport", label = "Save table")
                                )
                    )
                  )
                )
              ),
      ),

     #file tab
      tabItem(tabName = "file",
              fluidRow(
                box(width =6,
                tags$h3("Download working object as .RDS/.qs/.qs2 file"),
               tags$hr(),
               downloadButton(outputId = "utilitiesConfirmQS2Export", label = "Download .qs2", class="btn btn-warning"),
               downloadButton(outputId = "utilitiesConfirmExport", label = "Download .RDS"),
              downloadButton(outputId = "utilitiesConfirmQSExport", label = "Download .qs"),         
               tags$h3("Save working object as RDS/qs/qs2 file on the server"),
                                             tags$hr(),
             shinySaveButton("saveQS2file", "Name qs2 file", "Save as...", filetype = list(rds = "qs2"), viewtype = "icon",  class="btn btn-info"),
                actionButton(inputId = "confirmSaveQS2", label = "Save qs2 file", class="btn btn-warning"),
                tags$br(),
                tags$h5("   "),
               shinySaveButton("saveRDSfile", "Name RDS file", "Save as...", filetype = list(rds = "rds"), viewtype = "icon"),
                actionButton(inputId = "confirmSaveRds", label = "Save RDS file"),
                shinySaveButton("saveQSfile", "Name qs file", "Save as...", filetype = list(rds = "qs"), viewtype = "icon"),
                actionButton(inputId = "confirmSaveQS", label = "Save qs file"),

               tags$br(),
               tags$br(),
              tags$h3("Export as .h5ad anndata file"),
               tags$hr(),
                tags$h4("Data of the selected assay will be exported."),
                  selectInput("h5adActiveAssay", "Select assay to export:", c("Assay" = "RNA")),
               downloadButton(outputId = "utilitiesConfirmExportCellxgene", label = "Download .h5ad", class="btn btn-warning"),
               checkboxInput("h5adForCellxgene",
                             tags$span(style="font-size: 115%; font-weight: bold;",
                                      "For cellxgene viewer only? (Please uncheck for downstream analyses)"),
                             TRUE),
               checkboxInput("h5adNA", strong("Preserve meta data column with NA? (May cause problems in cellxgene)"), FALSE),
                tags$h5("Can change the assay to be exported in the field below"),
              tags$h4("Save .h5ad file on the server"),
               tags$hr(),
               shinySaveButton("saveH5ADfile", "Name H5AD file", "Save as...", filetype = list(rds = "h5ad"), viewtype = "icon", class="btn btn-info"),
               actionButton(inputId = "confirmSaveH5AD", label = "Save H5AD", class="btn btn-warning"),

                tags$br(),
                tags$br(),
              tags$h3("Download a file on server"),
                tags$hr(),
               shinyFilesButton('downloadlocaFile', label='Choose a file on server', title='Select a file', multiple=FALSE),
               downloadButton(outputId = "confirmDownLocal", label = "Download", class="btn btn-warning"),
                tags$br(),
                tags$br(),
              tags$h3("Download a folder on server"),
                tags$hr(),
               shinyDirButton('downloadlocaFolder', label='Choose a folder on server', title='Select a folder', multiple=FALSE),
               downloadButton(outputId = "confirmDownLocalFolder", label = "Download", class="btn btn-warning"),
                tags$br(),
                tags$br(),

              tags$h3("Delete a file"),
                   tags$hr(),
                   shinyFilesButton('locaFileDelete', label = 'Choose a file',title = 'Select a file to delete', multiple = TRUE),
                   actionButton(inputId = "confirmDeleteLocalFile", label = "Delete file",class="btn btn-danger"),
                tags$br(),
                 tags$h3("Delete a directory"),
                 tags$h4("The target directory must be empty."),
                                            tags$hr(),
       shinyDirButton('localFolderDelete', 'Select a folder', 'Please select a folder', viewtype='list'),
          actionButton(inputId = "confirmDeleteLocalDirectory", label = "Delete directory", class="btn btn-danger"),
                tags$br(),
                tags$br(),
            tags$hr(),
        tags$h3("Completely refresh the session"),
        actionButton(inputId = "confirmRefresh", label = "Refresh the session", class="btn btn-danger"),


                ),


            box(width = 6,
            tags$h4("qs2形式が標準。\n"),
            tags$br(),
            tags$h4("Anndata (h5ad) ファイルへの変換ではactive assayのdataが出力される。\n"),
            tags$h4("通常RNAを選択。\n"),
                                             ),

              )
      ),

      #utilities tab
      tabItem(tabName = "utilities",
              fluidRow(
                box(
                  width = 12, status = "info", solidHeader = TRUE,
                  title = "Inspect/Manipulate cluster identity",
                  tags$h3("Set active cluster identity"),
                  tags$h5("The selected identity will be copied to seurat_clusters"),
                  tags$hr(),
                  selectInput("utilitiesActiveClusters", "Select the cluster identity to use as the active seurat_clusters:",
                              c("Cluster" = "seurat_clusters")),
                  actionButton(inputId = "utilitiesConfirmChangeCluster", label = "Change identity",class = "btn btn-info"),

                  tags$h3("Copy a cluster identity"),
                                                      tags$hr(),
                  selectInput("utilitiesActiveClusters2", "Copy cluster identity:",
                              c("Cluster" = "seurat_clusters")),
                  textInput(inputId = "NewIdent", label = "To:", value = "new.ident"),
                  actionButton(inputId = "CopyActiveCluster", label = "Commit copy", class = "btn btn-info"),

                 tags$h3("Rename a cluster identity"),
                 tags$hr(),
                  selectInput(inputId = "utilitiesOldIdent", label = "Choose a cluster identity to rename:",
                                 c("Cluster" = "orig.ident")),
                  textInput(inputId = "NewIdentName", label = "New cluster ident name:", value = "new.ident"),
                  actionButton(inputId = "utilitiesConfirmRenameCluster", label = "Commit rename",class = "btn btn-info"),

                  tags$h3("Delete cluster identities"),
                                    tags$hr(),
                  selectInput(inputId = "utilitiesDeleteIdent", label = "Choose clustering identity:",
                                 choices = "", multiple = T),
                  actionButton(inputId = "utilitiesConfirmDeleteIdent", label = "Delete the identity",class="btn btn-danger"),

                   tags$h3("Combine two cluster identities (A x B)"),
                    tags$hr(),
                  selectInput(inputId = "utilitiesFirstIdent", label = "Choose first identity:",
                                 c("Cluster" = "orig.ident")),
                  selectInput(inputId = "utilitiesSecondIdent", label = "Choose second identity:",
                     c("Cluster" = "seurat_clusters")),
                  actionButton(inputId = "utilitiesConfirmCombineIdents", label = "Combine the identities",class = "btn btn-info"),

                  tags$h3("Set active assay"),
                  tags$hr(),
                  selectInput("utilitiesActiveAssay", "Set active assay:", c("Assay" = "RNA")),
                  actionButton(inputId = "utilitiesConfirmChangeAssay", label = "Change assay",class = "btn btn-info"),

                tags$h3("Rename an assay"),
                 tags$hr(),
                  selectInput(inputId = "old_assay", label = "Choose an assay to rename:", c("Assay" = "RNA")),
                  textInput(inputId = "new_assay", label = "New assay name:", value = "new.assay"),
                  actionButton(inputId = "utilitiesConfirmRenameAssay", label = "Commit rename",class = "btn btn-info"),

              tags$h3("Delete an assay"),
                 tags$hr(),
                  selectInput(inputId = "AassayDelete", label = "Choose an assay to delete:", c("Assay" = NULL)),
                  actionButton(inputId = "utilitiesConfirmDeleteAssay", label = "Delet!",class = "btn btn-danger"),

                  tags$h3("Convert v5 RNA assay to v3 RNA assay"),
                  tags$hr(),
                  actionButton(inputId = "utilitiesConfirmConvertAssay", label = "Convert assay",class = "btn btn-info"),

                tags$h3("Joint layers in v5 assay"),
                  tags$hr(),
                  actionButton(inputId = "utilitiesConfirmJointLayer", label = "Joint layers",class = "btn btn-info"),

                tags$h3("Rename project"),
                  tags$hr(),
                  textInput(inputId = "new_project_name", label = "New project name:", value = "new.project"),
                  actionButton(inputId = "utilitiesConfirmRenameProject", label = "Commit rename",class = "btn btn-info"),
                )
              )
      ),

      #utilities2 tab
      tabItem(tabName = "utilities2",
              fluidRow(
                box(
                  width = 12, status = "info", solidHeader = TRUE,
                  title = "Inspect/Manipulate clusters",
                  tags$h3("Set active cluster identity"),
                    tags$h5("The selected identity will be copied to seurat_clusters"),
                 tags$hr(),
                  selectInput("utilitiesActiveClusters3", "Select the cluster identity to use as the active seurat_clusters:",
                              c("Cluster" = "seurat_clusters")),
                  actionButton(inputId = "utilitiesConfirmChangeCluster2", label = "Change identity",class = "btn btn-info"),

                  tags$h3("Show distribution of clusters"),
                  tags$hr(),
                  selectInput(inputId = "utilitiesDist", label = "Choose cluster identity:",
                                 c("Cluster" = "seurat_clusters")),
                  actionButton(inputId = "utilitiesConfirmDist", label = "Show dist",class = "btn btn-info"),
                  tags$h5("You can draw a graph and download table at CLUSTERING/Cluster output/Clustering barplot panel."),
                  tableOutput("distTable1"),
                  tableOutput("distTable2"),

                  tags$h3("Rename a single cluster in seurat_clusters"),
                  tags$hr(),
                  selectInput(inputId = "utilitiesRenameOldName", label = "Cluster to be renamed (old name):", choices = "-", multiple = F),
                  textInput(inputId = "utilitiesRenameNewName", label = "New name of the cluster:", value = "New_name_1"),
                  actionButton(inputId = "utilitiesConfirmRename", label = "Rename",class = "btn btn-info"),


                  tags$h3("Rename clusters"),
                  tags$hr(),
                  selectInput("utilitiesChangeCluster", "Choose a cluster identity to modify:",
                              c("Cluster" = "seurat_clusters")),
                  actionButton(inputId = "utilitiesConfirmShowRenameTable", label = "Show table",class = "btn btn-secondary"),
                  DT::dataTableOutput("my_datatable"),
                  actionButton(inputId = "utilitiesConfirmRenameTable", label = "Comit rename",class = "btn btn-info"),

                  tags$h3("Rename NaN in an identity"),
                  tags$hr(),
                  selectInput("utilitiesChangeClusterNan", "Choose identity containing NaN:",
                              c("Cluster" = "seurat_clusters")),
                  textInput(inputId = "utilitiesRenameNewNameNan", label = "New name for NaN:", value = "NoName"),
                  actionButton(inputId = "utilitiesConfirmRenameNan", label = "Rename",class = "btn btn-info"),


                  tags$h3("Reorder clusters"),
                  tags$hr(),
                  selectInput(inputId = "utilitiesReorderIdent", label = "Choose identity:", c("Cluster" = "seurat_clusters")),
                 actionButton(inputId = "utilitiesConfirmReorderIdent", label = "Set the idenity to reorder",class = "btn btn-info"),
                 tags$br(),
                  orderInput(inputId = 'utilitiesClusterReorder', label = 'Clusters:', items = ""),
                  actionButton(inputId = "utilitiesConfirmClusterReorder", label = "Comit reorder",class = "btn btn-info"),

                  tags$h3("Delete clusters"),
                  tags$hr(),
                  selectInput(inputId = "utilitiesDeleteCluster", label = "Clusters to be deleted:", choices = "", multiple = T),
                  actionButton(inputId = "utilitiesConfirmDelete", label = "Delete",class="btn btn-danger"),

                  tags$h3("Extract a subset of clusters"),
                  tags$hr(),
                  selectInput(inputId = "utilitiesSubsetCluster", label = "Select clusters:", choices = "", multiple = T),
                  actionButton(inputId = "utilitiesConfirmSubset", label = "Subsetting",class = "btn btn-info"),

                  tags$h3("Downsample so that each cluster has the same number of cells."),
                  tags$h4("最小細胞数を0にした場合はactive identityの最小クラスターの細胞数に合わせる"),
               numericInput(inputId = "DownSampleCells",  label = "Number of cells from each cluster", min = 0, value = 0),
                  tags$hr(),
                  actionButton(inputId = "utilitiesConfirmDownsample", label = "Subsetting",class = "btn btn-danger"),

                )
              )
      ),


     #utilities3 tab
      tabItem(tabName = "utilities3",
        tabsetPanel(type = "tabs",
              tabPanel("Data manipulation", fluidRow(
                box(
                  width = 12, status = "info", solidHeader = TRUE,height = "2000px",
                  title = "Data cleanup",

                tags$h3("Update Seurat object"),
                                    tags$hr(),
                  actionButton(inputId = "confirmUpdate", label = "Update",class = "btn btn-info"),
                tags$h3("Update metadata"),
                tags$h5("Fixes metadata column types. Use this if dropdown menus don't show expected grouping variables."),
                                    tags$hr(),
                  actionButton(inputId = "confirmUpdateMeta", label = "Update",class = "btn btn-info"),
                tags$h3("Remove metadata"),
                tags$hr(),
                selectInput(inputId = "deletemeta", label = "Metadata names to deleted:", choices = "", multiple = T),
                actionButton(inputId = "confirmDeleteMeta", label = "Remove metadata",class="btn btn-danger"),

                tags$h3("Delete reduction"),
                tags$hr(),
                selectInput(inputId = "deleteReduc", label = "Reductions to deleted:", choices = "", multiple = T),
                actionButton(inputId = "confirmDeleteReduc", label = "Delete reductions",class="btn btn-danger"),

                tags$h3("Remove mitochondrial genes"),
                                    tags$hr(),
                actionButton(inputId = "confirmDelMito", label = "Delete mito-gnes"),

                tags$h3("Remove ribosomal genes"),
                tags$hr(),
                actionButton(inputId = "confirmDelRibo", label = "Delete ribo-genes"),

                tags$h3("Remove mito/ribo genes"),
                tags$hr(),
                actionButton(inputId = "confirmDelMitoRibo", label = "Delete mito/ribo"),

                tags$h3("Subset cells by the reduction dimension ranges"),
                tags$hr(),
                selectInput(inputId = "umapType2", label = "Choose reduction:",  c("reduction" = "umap") , width = '200px'),
                  textInput("Dim1min", "Dim_1 min:", value = '-Inf', width = '200px'),
                  textInput("Dim1max", "Dim_1 max:", value = '+Inf', width = '200px'),
                  textInput("Dim2min", "Dim_2 min:", value = '-Inf', width = '200px'),
                  textInput("Dim2max", "Dim_2 max:", value = '+Inf', width = '200px'),
                actionButton(inputId = "confirmSubsetDim", label = "Subsetting by dim ranges"),

                tags$h3("Subset cells by the expression level of a gene"),
                tags$hr(),
                selectizeInput(inputId = 'findMarkersGeneSelect3', label = 'Select a gene:', choices = NULL, selected = NULL, multiple = FALSE, width = '200px'),
                selectInput("subsetGeneCount", "Count or data?", choices=c("Counts"="counts","Data"="data"), selected = "Counts", multiple = FALSE, selectize = TRUE, size = NULL, width = '200px'),
                textInput(inputId = "subsetGeneMin", label = "Min level >= ", value = '0', width = '200px'),
                textInput(inputId = "subsetGeneMax", label = "Max level <= ",  value = '+Inf', width = '200px'),
                actionButton(inputId = "confirmSubsetGene", label = "Commit subsetting by expression"),

                  tags$h3("Slim down the Seurat object"),
                                    tags$hr(),
                  actionButton(inputId = "confirmDiet", label = "Commit DietSeurat func"),

                  
                  tags$h3("Make an assay with a subset of genes"),
                  tags$hr(),
                  textAreaInput(inputId = "subsetGenes", label = "List the genes to subset", cols = 80, rows = 5, placeholder = "Prg4\nTspan15\nCol22a1\nHtra4"),
                  actionButton(inputId = "confirmSubsetAssay", label = "Commit subsetting"),

                ))),

                tabPanel("Demultiplexing", fluidRow(
                  box(status = "info", solidHeader = TRUE, title = "Demultiplexing",width = 12,
                  tags$h4("Should perform demultiplexing prior to QC filtering, but after emptyDrops or CellBender."),
                  actionButton(inputId = "confirmDemultiplex", label = "Commit demultiplexing",class = "btn btn-info"),
                  tags$h4(" "),
                  tags$h4("Major classifications:"),
                  tags$h4("アルゴリズム選択 / Algorithm Selection"),
                  tags$div(style="background-color: #f0f8ff; padding: 10px; border-radius: 5px; margin-bottom: 10px;",
                    tags$h5(tags$b("運用方針："), "Primary + Sensitivity + Baseline の役割分担"),
                    tags$p(tags$b("Primary（主解析候補）"), " - データ条件で選択"),
                    tags$p("・", tags$b("demuxmix"), " - 混合モデル。割当のerror probabilityを定量的に評価可能（Galembert et al., Bioinformatics 2023）"),
                    tags$p("・", tags$b("hashDemux"), " - クラスタリング型。独立ベンチマークで頑健性が報告（BFG 2025）"),
                    tags$p(tags$b("Sensitivity（回収重視・追加検証）")),
                    tags$p("・", tags$b("deMULTIplex2"), " - タグcross-contaminationをEM-GLMでモデル化。",
                           "他手法でNegativeになる細胞を救済し得るが、追加回収分はdiagnostic plotで要検証（Zeng et al., Genome Biology 2024）"),
                    tags$p(tags$b("Baseline（比較用）")),
                    tags$p("・", tags$b("MULTIseqDemux / HTODemux"), " - Seurat標準手法。比較ベースラインとして使用"),
                    tags$p(style="color: #666; font-size: 0.9em;",
                           "複数手法の併用目的：discordant cells（手法間で不一致の細胞）をフラグ付けし、",
                           "保留・除外・感度分析の対象とすること。自動的に精度が上がるわけではない。")
                  ),
                  checkboxInput(inputId = "run_demuxmix", label = "demuxmix (mixture model) - primary候補", value = TRUE),
                  checkboxInput(inputId = "run_hashDemux", label = "hashDemux (clustering-based) - primary候補", value = TRUE),
                  checkboxInput(inputId = "run_deMULTIplex2", label = "deMULTIplex2 (EM-GLM) - sensitivity / 回収重視", value = FALSE),
                  checkboxInput(inputId = "run_MULTIseqDemux", label = "MULTIseqDemux (Seurat) - baseline", value = FALSE),
                  checkboxInput(inputId = "run_HTODemux", label = "HTODemux (Seurat) - baseline", value = FALSE),
                  tags$hr(),
                  tags$h4("Algorithm Details and Output Columns"),
                  tags$h5(tags$b("HTODemux (Seurat):")),
                  tags$ul(
                    tags$li("Metadata: HTO_classification, HTO_classification.global"),
                    tags$li("Method: CLR normalization + outlier detection"),
                    tags$li("HTO_maxID: highest hashtag, HTO_secondID: second hashtag"),
                    tags$li("HTO_margin: difference between 1st and 2nd (higher = better classification)")
                  ),
                  tags$h5(tags$b("MULTIseqDemux (Seurat):")),
                  tags$ul(
                    tags$li("Metadata: MULTI_ID, MULTI_classification"),
                    tags$li("Method: Quantile-based thresholding for doublet detection")
                  ),
                  tags$h5(tags$b("demuxmix:")),
                  tags$ul(
                    tags$li("Metadata: demuxmix_hash_re"),
                    tags$li("Method: Mixture model with naive Bayes classifier"),
                    tags$li("Robust to tag swapping and ambient RNA")
                  ),
                  tags$h5(tags$b("hashDemux:")),
                  tags$ul(
                    tags$li("Metadata: sampleBC, classification, confidence_score"),
                    tags$li("Method: Clustering-based approach with confidence scoring"),
                    tags$li("classification: Singlet/Doublet/Negative"),
                    tags$li("confidence_score: 0-1 score for assignment confidence")
                  ),
                  tags$h5(tags$b("deMULTIplex2:")),
                  tags$ul(
                    tags$li("Metadata: deMULTIplex2_assign, deMULTIplex2_type"),
                    tags$li("Method: EM algorithm with GLM-based modeling of tag cross-contamination"),
                    tags$li("deMULTIplex2_type: singlet/multiplet/negative"),
                    tags$li("Diagnostic plots: tagHist, tagCallHeatmap, posterior probability distribution, UMAP by posterior"),
                    tags$li("追加回収分の品質評価: posterior が0.5付近に集中 → 不確実な分類、UMAP上で散在 → 背景ノイズの疑い")
                  ),
                  tags$hr(),
                  tags$h5(tags$b("Note:"), "These algorithms may give differential classifications. Compare results to choose the most appropriate for your data."),
                  tags$hr(),
                  tags$h4("For surface tag reads including non-multiplexing tags"),
                   tags$h5("Delete non-multiplexing tag reads for demultiplexing (e.g., remove biotin tag)."),
                   tags$h5("Original HTO assay will be copied to HTO2. For expression analysis of biotin tag etc, use HTO2 and normalize the data."),
                  actionButton(inputId = "updateHTO", label = "Update hashtag list"),
                  selectInput(inputId = "DeleteHTO", label = "Choose hashtags to remove:",
                                 choices = "", multiple = T),
                  actionButton(inputId = "utilitiesConfirmDeletehash", label = "Delete the hashtags",class="btn btn-danger"),
                  tags$hr(),
                  tags$h4("Demultiplexing Results"),
                            plotOutput(outputId = "HTOdemuxPlot", height="100%"),
                            plotOutput(outputId = "demuxmixPlot",height="100%"),
                            textOutput(outputId = "hashDemuxText"),
                            plotOutput(outputId = "hashDemuxUMAP", height = "500px"),
                            plotOutput(outputId = "hashDemuxHeatmap", height = "400px"),
                            plotOutput(outputId = "hashDemuxConfidence", height = "300px"),
                            hr(),
                            h4("deMULTIplex2 Results"),
                            textOutput(outputId = "deMULTIplex2Text"),
                            plotOutput(outputId = "deMULTIplex2_tagHist", height="600px"),
                            plotOutput(outputId = "deMULTIplex2_heatmap", height="600px"),
                            plotOutput(outputId = "deMULTIplex2_posterior", height = "500px"),
                            plotOutput(outputId = "deMULTIplex2_umapPosterior", height = "600px"),
                            hr(),
                            h4("Algorithm Comparison Visualizations"),
                            tags$p("Compare results across multiple demultiplexing algorithms (shown only if 2+ algorithms were run):"),
                            h5("1. Agreement Heatmap"),
                            tags$p("Shows pairwise agreement between algorithms with hierarchical clustering"),
                            plotOutput(outputId = "demuxAgreementHeatmap", height="600px"),
                            h5("2. UpSet Plot"),
                            tags$p("Shows which algorithm combinations agree on singlet classification"),
                            plotOutput(outputId = "demuxUpsetPlot", height="600px"),
                            h5("3. Alluvial Diagram"),
                            tags$p("Shows classification flow across algorithms"),
                            plotOutput(outputId = "demuxAlluvialPlot", height="600px")
                      )
               )),

                tabPanel("SoupX", fluidRow(
                  box(status = "info", solidHeader = TRUE, title = "Removal of cell free mRNA contamination",width = 12,

                  shinyDirButton('Multiple10XFolderSoup', label='Choose a parent folder containing all filtered_feature_bc_matrix folders', title='Select the folder', multiple=FALSE,class = "btn btn-info"),
                  tags$h4(" "),
                 shinyDirButton('SoupUnfiltered', label='Choose raw_feature_bc_matrix folder', title='Select the folder', multiple=FALSE,class = "btn btn-info"),
                                        tags$br(),
                  selectInput(inputId = "SoupIdent", label = "Choose identity for clusters", c("Cluster" = "seurat_clusters")),

                  actionButton(inputId = "confirmSoupFolder", label = "Set directories and run",class = "btn btn-warning"),


                            plotOutput(outputId = "HTOdemuxPlot", height="100%"),
                            plotOutput(outputId = "demuxmixPlot",height="100%")
                      )
               )),

                tabPanel("scCDC", fluidRow(
                  box(status = "info", solidHeader = TRUE, title = "Gene-specific contamination detection and correction (scCDC)", width = 12,

                  tags$h4("scCDC: Detect and correct contamination-causing genes"),
                  tags$p("scCDC detects global contamination-causing genes (GCGs) and performs targeted decontamination only on these genes, avoiding over-correction of housekeeping genes."),

                  # Warning for separate batch data
                  tags$div(
                    style = "background-color: #fff3cd; padding: 15px; border-radius: 5px; margin: 15px 0; border-left: 4px solid #ffc107;",
                    tags$p(style = "margin: 0; font-weight: bold;", "別バッチ/別ライブラリからマージしたデータの場合:"),
                    tags$p(style = "margin: 5px 0;",
                      "各サンプルは独自のambient RNAプールを持つため、",
                      tags$span(style = "color: #d9534f; font-weight: bold;", "マージ前に各サンプルで個別にscCDCを実行してください。")
                    )
                  ),

                  # Info for multiplexed data
                  tags$div(
                    style = "background-color: #d4edda; padding: 15px; border-radius: 5px; margin: 15px 0; border-left: 4px solid #28a745;",
                    tags$p(style = "margin: 0; font-weight: bold;", "Multiplexedデータ（単一ライブラリ）の場合:"),
                    tags$p(style = "margin: 5px 0;",
                      "Hashtag/MULTI-seqなどでmultiplexingされたサンプルは",
                      tags$b("同じambient RNAプールを共有"),
                      "しているため、demultiplex後のデータでそのままscCDCを実行できます。"
                    ),
                    tags$p(style = "margin: 5px 0; color: #155724;",
                      "→ ", tags$b("orig.ident"), "をidentityとして使用し、サンプル間の汚染を検出"
                    )
                  ),
                  tags$hr(),

                  tags$h5("How scCDC uses cluster information:"),
                  tags$ul(
                    tags$li("Clustering information must exist in the Seurat object"),
                    tags$li("scCDC detects genes that are highly expressed in some clusters but show low 'contamination' expression in other clusters"),
                    tags$li(tags$b("orig.ident:"), " Detects sample-specific contamination (e.g., Xist from female to male samples)"),
                    tags$li(tags$b("cell type:"), " Detects cell type-specific contamination (e.g., Hbb from RBCs to other cells)")
                  ),
                  tags$hr(),

                  tags$h3("1. Select cluster identity"),
                  selectInput(inputId = "scCDCIdent",
                             label = "Choose identity for clusters",
                             c("Cluster" = "seurat_clusters")),
                  tags$p(style = "color: #666; font-size: 0.9em;",
                         "Multiplexedデータの場合: orig.ident（サンプル単位）推奨。同一ライブラリ内のサンプル間汚染を検出。"),
                  tags$p(style = "color: #666; font-size: 0.9em;",
                         "細胞タイプ間汚染を検出したい場合: cell typeクラスターを使用。"),
                  tags$hr(),

                  tags$h3("2. Advanced parameters (optional)"),
                  tags$div(
                    style = "background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0;",

                    tags$h5("ContaminationDetection parameters:"),
                    fluidRow(
                      column(4,
                        numericInput(inputId = "scCDC_restriction_factor",
                                    label = "restriction_factor",
                                    value = 0.5, min = 0.1, max = 1.0, step = 0.1),
                        tags$p(style = "color: #666; font-size: 0.8em;",
                               "汚染遺伝子と判定する閾値。この割合以上のクラスターで汚染と認識された遺伝子を検出。",
                               tags$b("下げると検出数↑"), "（デフォルト: 0.5 = 50%）")
                      ),
                      column(4,
                        numericInput(inputId = "scCDC_min_cell_detection",
                                    label = "min.cell (Detection)",
                                    value = 100, min = 10, max = 500, step = 10),
                        tags$p(style = "color: #666; font-size: 0.8em;",
                               "この細胞数未満のクラスターは解析から除外。",
                               tags$b("下げると小クラスターも含む"), "（デフォルト: 100）")
                      ),
                      column(4,
                        numericInput(inputId = "scCDC_percent_cutoff",
                                    label = "percent.cutoff",
                                    value = 0.2, min = 0.05, max = 0.5, step = 0.05),
                        tags$p(style = "color: #666; font-size: 0.8em;",
                               "各クラスターでの発現率閾値。これ未満の候補遺伝子を除外。",
                               tags$b("下げると低発現も検出"), "（デフォルト: 0.2 = 20%）")
                      )
                    ),

                    tags$hr(),
                    tags$h5("ContaminationCorrection parameters:"),
                    fluidRow(
                      column(6,
                        numericInput(inputId = "scCDC_auc_thres",
                                    label = "auc_thres",
                                    value = 0.9, min = 0.5, max = 1.0, step = 0.05),
                        tags$p(style = "color: #666; font-size: 0.8em;",
                               "GCG陽性/陰性クラスターの境界を決めるAUROC閾値。",
                               tags$b("下げると補正対象が増える"), "（デフォルト: 0.9 = 90%）")
                      ),
                      column(6,
                        numericInput(inputId = "scCDC_min_cell_correction",
                                    label = "min.cell (Correction)",
                                    value = 50, min = 10, max = 200, step = 10),
                        tags$p(style = "color: #666; font-size: 0.8em;",
                               "補正時にこの細胞数未満のクラスターを除外。（デフォルト: 50）")
                      )
                    ),
                    tags$hr(),
                    tags$p(style = "color: #856404; font-size: 0.9em;",
                           tags$b("Tip:"), " 検出数が少ない場合は restriction_factor を 0.3、min.cell を 50 に下げてみてください。")
                  ),
                  tags$hr(),

                  tags$h3("3. Exclude genes from correction (optional)"),
                  tags$div(
                    style = "background-color: #f8d7da; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #dc3545;",
                    tags$p(style = "margin: 0; font-weight: bold; color: #721c24;", "生物学的に重要な遺伝子を除外:"),
                    tags$p(style = "margin: 5px 0; color: #721c24; font-size: 0.9em;",
                      "scCDCは細胞タイプ特異的遺伝子を「汚染」と誤認することがあります。",
                      "例: Nr2f2（静脈マーカー）、Gja4（動脈マーカー）など"
                    )
                  ),
                  textAreaInput(inputId = "scCDC_exclude_genes",
                               label = "Genes to exclude from correction (comma or newline separated):",
                               value = "",
                               placeholder = "Nr2f2, Gja4, Vegfc\nor one gene per line",
                               rows = 3),
                  tags$p(style = "color: #666; font-size: 0.85em;",
                         "これらの遺伝子はGCGリストから除外され、補正されません。"),
                  tags$hr(),

                  tags$h3("4. Run scCDC analysis"),
                  actionButton(inputId = "runScCDC",
                              label = "Run scCDC (Detection → Quantification → Correction)",
                              class = "btn btn-warning",
                              icon = icon("play")),
                  tags$br(),
                  tags$br(),

                  tags$h5("Processing steps:"),
                  tags$ol(
                    tags$li("ContaminationDetection: Identifies contamination-causing genes (GCGs)"),
                    tags$li("ContaminationQuantification: Calculates contamination ratio"),
                    tags$li("ContaminationCorrection: Corrects expression of GCGs")
                  ),
                  tags$hr(),

                  tags$h3("Results"),
                  verbatimTextOutput("scCDCResults"),
                  tags$hr(),

                  tags$h5("Output:"),
                  tags$ul(
                    tags$li("Corrected count matrix is stored in 'Corrected' assay"),
                    tags$li("List of detected GCGs is displayed below"),
                    tags$li("Switch to 'Corrected' assay in UTILITY IDENTITY & ASSAY tab to use corrected data")
                  ),
                  tags$hr(),

                  tags$h5("Reference: "),
                  tags$a(href = "https://github.com/ZJU-UoE-CCW-LAB/scCDC",
                        "scCDC GitHub", target = "_blank"),
                  tags$br(),
                  tags$a(href = "https://genomebiology.biomedcentral.com/articles/10.1186/s13059-024-03284-w",
                        "scCDC: a computational method for gene-specific contamination detection and correction (Genome Biology, 2024)",
                        target = "_blank")
                  )
                )),

                tabPanel("Imputation", fluidRow(
                  box(status = "info", solidHeader = TRUE, title = "Data imputation",width = 12,

                  tags$h3("ALRA"),
                                    tags$hr(),
                  actionButton(inputId = "runALRA", label = "Run ALRA",class = "btn btn-info"),
                  tags$h4("Imputed data are stored in the data slot of 'alra' assay."),
                tags$h5("https://www.biorxiv.org/content/10.1101/397588v1"),
                                                    tags$hr(),
                 checkboxInput("ALRAIndividual", label= "Run ALRA on each sample individually for merged data.", value = FALSE, width = NULL),
                selectInput(inputId = "BatchIdent3", label = "Choose identity for samples if you RUN ALRA separetely", c("Cluster" = "orig.ident")),
                tags$details(
                  tags$summary(tags$b("ALRAバッチ分割の判断ガイド（クリックで展開）")),
                  tags$ul(
                    tags$li(tags$b("一般則は未確立"), "：merge後ALRA vs バッチ別ALRAの体系的比較研究は存在しない"),
                    tags$li(tags$b("原著はmerge後ALRA"), "：Linderman et al. 2022の全例が「merge→正規化→ALRA」の手順"),
                    tags$li(tags$b("異質な集団にはsplit有効"), "：Valyaeva et al. 2026が細胞タイプ別ALRA戦略を提示（non-zero fraction目的）"),
                    tags$li(tags$b("条件差マスクの報告あり"), "：GitHub Issue #5で「treatment/control差が潰れる」との観察（ただし単一ユーザー、未検証）"),
                    tags$li(tags$b("実務的結論"), "：条件×バッチが交絡していなければmerge後ALRAで開始、交絡がある or 条件差が最重要なら両方試して比較（logFC、擬似バルク整合性等で判定）")
                  )
                ),
                tags$hr(),
                tags$h3("MAGIC"),
                    tags$hr(),
                numericInput(inputId = "MAGICknn", label = "Knn:", min = 1, value = 5),
                numericInput(inputId = "MAGICt", label = "t:", min = 1, value = 3),
                  actionButton(inputId = "runMAGIC", label = "Run MAGIC",class = "btn btn-info"),
                  tags$h4("Imputed data are stored in the data slot of 'MAGIC_RNA' assay."),
               tags$h3("deepImpute"),
                    tags$hr(),
                  actionButton(inputId = "runDIP", label = "Run DeepImpute",class = "btn btn-info"),
                  tags$h4("Imputed data are stored in the count slot of 'DIP' assay."),
                  tags$h3("RECODE"),
                    tags$hr(),
                  actionButton(inputId = "runRECODE", label = "Run RECODE",class = "btn btn-info"),
                  tags$h4("Imputed data are stored in the count slot of 'RECODE' assay."),
                  tags$h5("RECODE tutorial uses unfiltered (non-QCed) data."),
                  imageOutput("matplotlib_plot")
                      )
               )),

                tabPanel("Data to reducition", fluidRow(
                  box(status = "info", solidHeader = TRUE, title = "Copy data slot to reduction",width = 12,
                  actionButton(inputId = "copyGSET2Red", label = "Copy",class = "btn btn-info"),
                  tags$h4("Data are stored in GSET reduction."),
                  tags$h4("Gene set等のデータそのものをUMAPの計算に使う"),
                  tags$h5("UMAP関数はPCA等の次元圧縮データをもとに計算する。データから直接UMAPを計算するため、GSETという次元圧縮のスロットにデータをコピー。"),
                  tags$h5("GSETの全データを用いてUMAP等の解析を行う場合は、Use all dimensions to calculate?をチェックする。"),

                      )
               )),
                  tabPanel("Manipulate metadata", fluidRow(
                  box(status = "info", solidHeader = TRUE, title = "Download/Add metadata",width = 12,
                  downloadButton(outputId = "DownloadMeta", label = "Download metadata",class = "btn btn-info"),

                  tags$hr(),
                  tags$h3("Add metadata"),

                  fileInput(inputId = "metaUploadFile", label = "Upload meta data file to add", accept = c(".tsv",'.txt','.gz','.rds','.csv')),
                  checkboxInput(inputId = "ignoreOrderMeta", label = "細胞名に関係なく順番通りにメタデータを追加する", value = FALSE),
                  actionButton(inputId = "uploadMeta", label = "Upload and add to the current object",class = "btn btn-warning"),
                  tags$h5("tsv, csv, rds or gz"),
                  tags$h5("細胞名が一致する必要がある。ダウンロードしたメタデータの細胞名を修正するのが比較的容易。既存のmetadataの上書きはしません。"),
                  tags$h5("順番通りオプション：細胞名を無視して行番号順にメタデータを追加します。細胞数が異なる場合はエラーになります。"),

                  tags$hr(),
                  tags$h3("Convert metadata to reduction"),
                  tags$h5("Select metadata columns to use as reduction coordinates. The common prefix of selected columns will be used as the reduction key and name."),
                  tags$h5("Example: Selecting 'tsne_1' and 'tsne_2' will create a reduction named 'tsne' with key 'tsne_'."),
                  selectInput(inputId = "metaToReductionCols", 
                             label = "Select metadata columns:", 
                             choices = "", 
                             multiple = TRUE),
                  textInput(inputId = "reductionName", 
                           label = "Reduction name (auto-detected if empty):", 
                           value = "",
                           placeholder = "Leave empty for auto-detection"),
                  textInput(inputId = "reductionKey", 
                           label = "Reduction key (auto-detected if empty):", 
                           value = "",
                           placeholder = "Leave empty for auto-detection"),
                  actionButton(inputId = "previewReduction", 
                              label = "Preview", 
                              class = "btn btn-info"),
                  tags$hr(),
                  verbatimTextOutput("reductionPreview"),
                  tags$hr(),
                  actionButton(inputId = "confirmMetaToReduction", 
                              label = "Convert to reduction", 
                              class = "btn btn-warning")
                  )
                )),
                  tabPanel("Change cell names", fluidRow(
                  box(status = "info", solidHeader = TRUE, title = "Download/Replace cell names",width = 12,
                  downloadButton(outputId = "DownloadCell", label = "Download cell_name",class = "btn btn-info"),
                  tags$hr(),

                  fileInput(inputId = "cellUploadFile", label = "Upload cell name file to add", accept = c('.txt')),
                  actionButton(inputId = "uploadCell", label = "Upload and replace cell name",class = "btn btn-warning"),
                  tags$h5("ファイル名をダウンロードして、同じフォーマットで修正してください。"),

                      )
               )),
                 tabPanel("Download expression matrix", fluidRow(
                  box(status = "info", solidHeader = TRUE, title = "Download expression matrix",width = 12,

               radioButtons("selectExp", label = h3("Slot to download: "),
                                                    choices = list("counts",'data'), selected = "counts"),
               radioButtons("typeExp", label = h3("File type: "),
                                                    choices = list("csv",'tsv'), selected = "csv"),
                checkboxInput("Exprtranspose", label= "Transpose matrix (row: sample, column: gene)?", value = FALSE, width = NULL),
                  downloadButton(outputId = "DownloadExp", label = "Download expression matrix",class = "btn btn-info"),

                      )
               )),
               
               tabPanel("Ensembl to Gene Symbol", fluidRow(
                 box(status = "info", solidHeader = TRUE, title = "Convert Gene Names", width = 12,

                     # Option 1: Use column from meta.features
                     tags$h4("Option 1: Use column from meta.features"),
                     p("Select a column containing gene names (e.g., gene_short_name, gene_name) to set as rownames."),
                     selectInput(inputId = "geneNameColumnSelect",
                                label = "Select gene name column:",
                                choices = c("(none)" = "none"),
                                selected = "none"),
                     p(strong("Duplicate handling:"), "make.unique() is used. Original names stored in 'gene.symbol' column."),
                     actionButton(inputId = "confirmColumnToRownames",
                                 label = "Set column as rownames",
                                 class = "btn btn-info"),

                     tags$hr(),

                     # Option 2: Ensembl ID conversion
                     tags$h4("Option 2: Convert Ensembl IDs using database"),
                     p("Use this when rownames are Ensembl IDs (ENSG.../ENSMUSG...)."),
                     p(tags$small("Uses local database (db/human_genes.csv or db/mouse_genes.csv). Version numbers (.1, .2) are automatically removed.")),
                     selectInput(inputId = "conversionOrganism",
                                label = "Organism:",
                                choices = c("Mouse" = "mouse", "Human" = "human"),
                                selected = "mouse"),
                     checkboxInput("updateGeneNames",
                                  label = "Update gene names in expression matrix",
                                  value = TRUE),
                     actionButton(inputId = "confirmGeneConversion",
                                 label = "Convert Ensembl IDs to Gene Symbols",
                                 class = "btn btn-warning"),

                     tags$hr(),
                     tags$p(tags$small(tags$em("To aggregate duplicates after conversion, use 'Aggregate duplicate genes' in the H5AD/Anndata section.")))
                 )
               )),

               tabPanel("Species Gene Conversion", fluidRow(
                 box(status = "success", solidHeader = TRUE, title = "Species Gene Conversion (Mouse ↔ Human)", width = 12,
                     p("Convert gene symbols between mouse and human orthologs. Genes without conversion will be removed, and duplicate genes will be averaged."),
                     tags$hr(),
                     p(strong("Conversion Direction:"), "Based on current organism setting"),
                     selectInput(inputId = "speciesConversionMethod",
                                label = "Conversion Database:",
                                choices = c("NichenetR v1 (original)" = "nichenetr_v1_original",
                                           "NichenetR v1 (corrected)" = "nichenetr_v1_corrected",
                                           "NichenetR v2 (original)" = "nichenetr_v2_original",
                                           "NichenetR v2 (corrected)" = "nichenetr_v2_corrected",
                                           "Consensus (original)" = "consensus_original",
                                           "Consensus (corrected)" = "consensus_corrected"),
                                selected = "nichenetr_v1_corrected"),
                     tags$hr(),
                     p(strong("Database Information:")),
                     tags$ul(
                       tags$li("NichenetR v1: NCBI Entrez Gene database (18,985 entries, older symbols)"),
                       tags$li("NichenetR v2: NCBI Entrez Gene database (122,797 entries, 2022 version)"),
                       tags$li("Consensus: HomoloGene + Ensembl Compara consensus mapping"),
                       tags$li("Corrected: Functional corrections applied (Ccl2→CCL2, Ccl3→CCL3, Cxcl1→CXCL1)")
                     ),
                     tags$hr(),
                     actionButton(inputId = "confirmSpeciesConversion",
                                 label = "Convert Between Species",
                                 class = "btn btn-success"),
                     tags$hr()
                 )
               )),

               tabPanel("Augur", fluidRow(
                 box(status = "info", solidHeader = TRUE, title = "Cell Type Prioritization (Augur)", width = 12,
                     tags$h4("Augur: 実験条件に対する細胞タイプの応答性を評価"),
                     tags$p("機械学習（ランダムフォレスト分類器）を用いて、各細胞タイプが実験条件（刺激 vs コントロール）をどれだけ識別できるかをAUC値で評価します。"),
                     tags$p("AUCが高い細胞タイプほど、実験条件に強く応答していることを意味します。"),
                     tags$hr(),

                     tags$h5("Required settings:"),
                     selectInput(inputId = "augurCellTypeCol",
                                label = "Cell type column:",
                                choices = c("Cluster" = "seurat_clusters")),
                     selectInput(inputId = "augurLabelCol",
                                label = "Condition column (e.g., treatment vs control):",
                                choices = c("Sample" = "orig.ident")),

                     tags$hr(),
                     tags$h5("Advanced parameters:"),
                     fluidRow(
                       column(4,
                         numericInput("augurNsubsamples", "n_subsamples:", value = 50, min = 10, max = 200, step = 10),
                         tags$p(style = "color: #666; font-size: 0.8em;",
                                "サブサンプリング回数。多いほど安定するが時間がかかる（デフォルト: 50）")
                       ),
                       column(4,
                         numericInput("augurMinCells", "min_cells:", value = 20, min = 5, max = 100, step = 5),
                         tags$p(style = "color: #666; font-size: 0.8em;",
                                "各細胞タイプの最小細胞数。これ未満の細胞タイプはスキップ（デフォルト: 20）")
                       ),
                       column(4,
                         numericInput("augurVarQuantile", "var_quantile:", value = 0.5, min = 0.1, max = 1.0, step = 0.1),
                         tags$p(style = "color: #666; font-size: 0.8em;",
                                "使用する高変動遺伝子の割合（デフォルト: 0.5 = 上位50%）")
                       )
                     ),

                     tags$hr(),
                     actionButton("runAugur", "Run Augur", class = "btn btn-warning", icon = icon("play")),

                     tags$hr(),
                     tags$h4("Results"),
                     verbatimTextOutput("augurStatusText"),
                     tableOutput("augurResultsTable"),
                     tags$hr(),
                     tags$h5("Lollipop Plot (AUC by cell type):"),
                     plotOutput("augurLollipopPlot", height = "500px"),
                     downloadButton("downloadAugurResults", "Download AUC results (CSV)", class = "btn btn-info"),
                     downloadButton("downloadAugurPlot", "Download Plot (PDF)", class = "btn btn-info"),

                     tags$hr(),
                     tags$h5("Reference:"),
                     tags$a(href = "https://github.com/neurorestore/Augur", "Augur GitHub", target = "_blank"),
                     tags$span(" | "),
                     tags$a(href = "https://www.nature.com/articles/s41587-021-01171-4",
                           "Skinnider et al., Nature Biotechnology (2021)", target = "_blank")
                 )
               )),

#                tabPanel("Metacell", fluidRow(
#                  box(status = "info", solidHeader = TRUE, title = "Generate metacells",width = 12,
#
 #                 tags$h3("SuperCell"),
 #                 tags$hr(),
 #                 selectInput(inputId = "supercellident", label = "Identity for cell type", c("Cluster" = "orig.ident")),
#
#                  checkboxInput("supercellsplit_key", label= "Split the data by samples?", value = FALSE, width = NULL),
#                  selectInput(inputId = "supercellsplit", label = "Choose identity to split", c("Cluster" = "orig.ident")),
#
#                 actionButton(inputId = "runSuperCell", label = "Run SuperCell",class = "btn btn-info"),
#
 #                     )
#               )),

                )),


     #utilities4 tab
      tabItem(tabName = "utilities4",
              fluidRow(
                column(width =3,
                box(

                  width = 12, status = "info", solidHeader = TRUE,
                  title = "Inspect working object",
                  tags$h3("Inspect the current Seurat object"),
                  tags$hr(),
                  actionButton(inputId = "utilitiesConfirmstr", label = "Show the structure",class = "btn btn-info"),

                                             tags$hr(),
                  actionButton(inputId = "utilitiesConfirmmeta", label = "Show the meta data",class = "btn btn-info"),
                               tags$hr(),
                  actionButton(inputId = "utilitiesConfirmDim", label = HTML("Show the dimensions<br>used in clustering") ,class = "btn btn-info"),

                  tags$h3("R session information"),
                  tags$hr(),
                  actionButton(inputId = "sessionInfo", label = "Show R session info",class = "btn btn-info"),
                )
              ),
                column(width = 9,

tabsetPanel(
            tabPanel("Structure",
            verbatimTextOutput("seuratsum") ,
            verbatimTextOutput("seuratactive") ,
            verbatimTextOutput("strSeurat")),
            tabPanel("Metadata",
                tags$h4("Meta data head and tail"),
                verbatimTextOutput("head_meta"),
                tags$h4("Cluster names"),
             verbatimTextOutput("table_meta")   ),

            tabPanel("Dimension",verbatimTextOutput("ClusterDim")),

            tabPanel("Session",verbatimTextOutput("session"))
        ),

         )
      )),

      #QC tab
      tabItem(tabName = "qc",
          tabsetPanel(type = "tabs", id = "qcTabPanel",
              tabPanel("scRNA-seq",
                       fluidRow(
                         box(
                           width = 3, status = "info", solidHeader = TRUE,
                           title = "Quality control",

                            selectInput("MitoOrganism", "Change species", choices=c("human","mouse"), selected = NULL, multiple = FALSE,selectize = TRUE, width = NULL, size = NULL),
                           actionButton(inputId = "changeMitoOrganism", label = "Commit change species"),

                           tags$h3("1. Display quality control plots before filtering"),
                            selectInput("qcColorBy", "Color by:",
                                       c("orig.ident" = "orig.ident")),
                            checkboxInput("nopt", label= "Remove data points?", value = TRUE, width = NULL),
                           actionButton(inputId = "qcDisplay", label = "Display plots",class = "btn btn-warning"),
                           tags$hr(),
                           tags$h3("2. Filter out low quality cells"),
                           tags$h4("Instead, you can use miQC to mark cells of poor quality."),

                           tags$hr(),

                             numericInput(inputId = "minUniqueGenes",
                                         label = "Minimum features threshold:", min = 200, max = 2000, value = 300),
                             tags$h5("See web_summary to determine the UMI threshold for cells when starting with raw_feature_bc_matrix."),

                             numericInput(inputId = "maxUniqueGenes",
                                         label = "Maximum features threshold:", min = 2000, max = 7000, value = 5000),

                           numericInput(inputId = "maxMtReads", label = "Mitochondrial %", min = 0, max = 40, value = 10),


                           actionButton(inputId = "qcConfirm", label = "Perform filtering",class = "btn btn-warning"),
                         tags$h3("OR QC an idenitity"),

                            selectInput("QCCluster", "Select an identity: ",choices = "-", multiple = F ),
                            actionButton(inputId = "EachQCConfirm", label = "Filter the individual idenity",class = "btn btn-info"),
                                                       tags$hr(),                           tags$hr(),
                            actionButton(inputId = "RestoreQC", label = "Restore the pre-QC data"),

                         ),
                         box(
                           width = 9, status = "info", solidHeader = TRUE,
                           title = "Quality control plots",

                           div(class="ldBar", id="qc_loader", "data-preset"="circle"),
                           tabsetPanel(type="tabs", id = "qc_tabs_rna",
                                       tabPanel("Pre-filtering plots",
                                                column(
                                                  div(id="nFeatureViolin_loader",
                                                      shinycssloaders::withSpinner(
                                                        plotlyOutput(outputId = "nFeatureViolin", height = "100%")
                                                      )
                                                  ), width = 4),
                                                column(
                                                  div(id="totalCountsViolin_loader",
                                                      shinycssloaders::withSpinner(
                                                        plotlyOutput(outputId = "totalCountsViolin", height = "100%")
                                                      )
                                                  ), width = 4),
                                                column(
                                                  div(id="mitoViolin_loader",
                                                      shinycssloaders::withSpinner(
                                                        plotlyOutput(outputId = "mitoViolin", height = "100%")
                                                      )
                                                  ), width = 4),
                                                column(
                                                  div(id="genesCounts_loader",
                                                      shinycssloaders::withSpinner(
                                                        plotlyOutput(outputId = "genesCounts", height= "100%")
                                                      )
                                                  ), width = 6),
                                                column(
                                                  div(id="mtCounts_loader",
                                                      shinycssloaders::withSpinner(
                                                        plotlyOutput(outputId = "mtCounts", height= "100%")
                                                      )
                                                  ), width = 6),
                                                column(verbatimTextOutput(outputId = "cellStats"), width = 4)
                                       ),
                                       tabPanel("Post-filtering plots",
                                                column(
                                                  div(id="filteredNFeatureViolin_loader",
                                                      shinycssloaders::withSpinner(
                                                        plotlyOutput(outputId = "filteredNFeatureViolin", height = "100%")
                                                      )
                                                  ), width = 4),
                                                column(
                                                  div(id="filteredTotalCountsViolin_loader",
                                                      shinycssloaders::withSpinner(
                                                        plotlyOutput(outputId = "filteredTotalCountsViolin", height = "100%")
                                                      )
                                                  ), width = 4),
                                                column(
                                                  div(id="filteredMitoViolin_loader",
                                                      shinycssloaders::withSpinner(
                                                        plotlyOutput(outputId = "filteredMitoViolin", height = "100%")
                                                      )
                                                  ), width = 4),
                                                column(
                                                  div(id="filteredGenesCounts_loader",
                                                      shinycssloaders::withSpinner(
                                                        plotlyOutput(outputId = "filteredGenesCounts", height= "100%")
                                                      )
                                                  ), width = 6),
                                                column(
                                                  div(id="filteredMtCounts_loader",
                                                      shinycssloaders::withSpinner(
                                                        plotlyOutput(outputId = "filteredMtCounts", height= "100%")
                                                      )
                                                  ), width = 6),
                                                column(verbatimTextOutput(outputId = "filteredCellStats"), width = 4)
                                       )
                           )
                       )
                      )
              ),

              tabPanel("DropletQC", fluidRow(
                box(status = "info", solidHeader = TRUE, title = "DropletQC Settings", width = 4,
                  tags$h4("DropletQC - Detect empty droplets & damaged cells"),
                  tags$hr(),
                  tags$div(
                    style = "background-color: #d1ecf1; padding: 10px; border-radius: 5px; margin-bottom: 10px; border-left: 4px solid #17a2b8;",
                    tags$p(
                      style = "margin: 0; font-size: 0.9em;",
                      tags$b("Reference:"), " Muskovic & Powell (2021) Genome Biology",
                      tags$br(),
                      "DropletQC calculates the nuclear fraction (intronic reads / total reads) from BAM files to identify empty droplets and damaged cells."
                    )
                  ),

                  # Multi-sample warning
                  tags$div(
                    id = "dropletqc_multisample_warning",
                    style = "background-color: #fff3cd; padding: 10px; border-radius: 5px; margin-bottom: 10px; border-left: 4px solid #ffc107; display: none;",
                    tags$p(
                      style = "margin: 0; font-size: 0.9em;",
                      tags$b("Multi-sample object detected."),
                      " Please process one sample at a time. Select the sample column and sample name below, then provide the corresponding BAM file."
                    )
                  ),

                  # Sample selection for merged objects
                  tags$h5("Sample Selection (for merged objects)"),
                  selectInput("dropletqcSampleCol", "Sample column:",
                    choices = NULL, selected = NULL),
                  selectInput("dropletqcSampleName", "Sample to process:",
                    choices = NULL, selected = NULL),
                  tags$hr(),

                  # Step 1: BAM File(s)
                  tags$h5("Step 1: Select BAM File(s)"),
                  tags$p(style="color: #666; font-size: 0.85em;",
                    "Single BAM: possorted_genome_bam.bam (cellranger count output, all cells).",
                    tags$br(),
                    "Multiple BAMs: sample_alignments.bam (cellranger multi per-sample outputs)."),
                  shinyFilesButton(id = "dropletqcBAMfile",
                    label = "Select BAM file(s)",
                    title = "Select BAM file(s)",
                    multiple = TRUE,
                    class = "btn btn-default"),
                  tags$br(), tags$br(),
                  verbatimTextOutput("dropletqcBAMpath"),
                  tags$hr(),

                  # Step 2: Method
                  tags$h5("Step 2: NF Calculation Method"),
                  radioButtons("dropletqcMethod", "Method:",
                    choices = list(
                      "RE tags (Cell Ranger BAM)" = "tags",
                      "GTF annotation" = "annotation"
                    ),
                    selected = "tags"),
                  conditionalPanel(
                    condition = "input.dropletqcMethod == 'annotation'",
                    selectInput("dropletqcGTFsource",
                      label = "Select reference genome:",
                      choices = list(
                        "Human GRCh38 (2024-A)" = "GRCh38-2024",
                        "Human GRCh38 (2020-A)" = "GRCh38-2020",
                        "Mouse GRCm39 (2024-A)" = "GRCm39-2024",
                        "Mouse mm10 (2020-A)" = "mm10-2020",
                        "Custom GTF file" = "custom"
                      ),
                      selected = "mm10-2020"),
                    conditionalPanel(
                      condition = "input.dropletqcGTFsource == 'custom'",
                      shinyFilesButton(id = "dropletqcGTFfile",
                        label = "Select GTF file",
                        title = "Select GTF annotation file",
                        multiple = FALSE,
                        class = "btn btn-default"),
                      tags$br(), tags$br(),
                      verbatimTextOutput("dropletqcGTFpath")
                    )
                  ),
                  tags$hr(),

                  # Step 3: Parameters
                  tags$h5("Step 3: Parameters"),
                  numericInput("dropletqcCores", "Number of cores:", value = 8, min = 1, max = 32, step = 1),
                  numericInput("dropletqcTiles", "Number of tiles:", value = 100, min = 1, max = 1000, step = 10),
                  tags$hr(),

                  # Step 4: Run NF
                  tags$h5("Step 4: Calculate Nuclear Fraction"),
                  actionButton(inputId = "RunDropletQCnf",
                    label = "Calculate Nuclear Fraction",
                    class = "btn btn-warning",
                    icon = icon("calculator")),
                  tags$br(), tags$br(),
                  verbatimTextOutput("dropletqcNFstatus"),
                  tags$hr(),

                  # Step 5: Identify empty drops
                  tags$h5("Step 5: Identify Empty Droplets"),
                  numericInput("dropletqcNFrescue", "nf_rescue (NF threshold for rescue):", value = 0, min = 0, max = 1, step = 0.01),
                  numericInput("dropletqcUMIrescue", "umi_rescue (UMI threshold for rescue):", value = 0, min = 0, step = 100),
                  actionButton(inputId = "RunDropletQCempty",
                    label = "Identify Empty Droplets",
                    class = "btn btn-info",
                    icon = icon("search")),
                  tags$hr(),

                  # Step 6: Identify damaged cells
                  tags$h5("Step 6: Identify Damaged Cells"),
                  selectInput("dropletqcCelltypeCol", "Cell type column:",
                    choices = NULL, selected = NULL),
                  numericInput("dropletqcNFsep", "nf_sep (NF separation threshold):", value = 0.15, min = 0, max = 1, step = 0.01),
                  numericInput("dropletqcUMIsepPerc", "umi_sep_perc (UMI percentile):", value = 50, min = 0, max = 100, step = 5),
                  actionButton(inputId = "RunDropletQCdamaged",
                    label = "Identify Damaged Cells",
                    class = "btn btn-info",
                    icon = icon("search")),
                  tags$hr(),

                  # Filter action
                  tags$h5("Step 7: Filter Cells"),
                  actionButton(inputId = "DropletQCfilter",
                    label = "Remove empty droplets & damaged cells",
                    class = "btn btn-danger",
                    icon = icon("filter"))
                ),
                box(status = "info", solidHeader = TRUE, title = "DropletQC Results", width = 8,
                  tabsetPanel(
                    tabPanel("NF vs UMI Plot",
                      tags$br(),
                      plotly::plotlyOutput("dropletqcScatter", height = "600px") %>% withSpinner()
                    ),
                    tabPanel("NF Distribution",
                      tags$br(),
                      plotOutput("dropletqcNFhist", height = "500px") %>% withSpinner()
                    ),
                    tabPanel("Summary",
                      tags$br(),
                      verbatimTextOutput("dropletqcSummary"),
                      tags$br(),
                      DT::dataTableOutput("dropletqcTable")
                    )
                  )
                )
              )),

              tabPanel("emptyDrops", fluidRow(
                box(status = "info", solidHeader = TRUE, title = "Filter empty droplets by emptyDrops", width = 12,
                  tags$h3("emptyDrops - Filter empty droplets from raw count matrix"),
                  tags$hr(),
                  tags$div(
                    style = "background-color: #fff3cd; padding: 15px; border-radius: 5px; margin: 15px 0; border-left: 4px solid #ffc107;",
                    tags$p(
                      style = "margin: 0;",
                      tags$b("Important:"), " This filter is designed for ", tags$b("raw_feature_bc_matrix"), " data from 10x Genomics.",
                      tags$br(),
                      "When loading raw data, set 'Include cells where at least this many features are detected' to ", tags$b("0"), "."
                    )
                  ),
                  tags$br(),
                  tags$h4("emptyDrops uses the number of UMIs in each droplet to statistically test whether a droplet contains a cell or is empty."),
                  tags$h5("This method is more accurate than simple thresholding and can recover cells with low RNA content."),
                  tags$br(),
                  actionButton(inputId = 'RunEmptyDrops', label='Apply EmptyDrops to filter out empty droplets', class = "btn btn-warning", icon = icon("filter")),
                )
              )),

                tabPanel("miQC", fluidRow(
                  box(status = "info", solidHeader = TRUE, title = "QC using miQC",width = 12, height= 1200,

                  tags$h3("miQC"),
                  tags$hr(),
                  numericInput(inputId = "miQCposterior",
                                         label = "Posterior threshold:", min = 0.5, max = 0.99, value = 0.75),
                  tags$h4("Higher value means lesser stringency"),
                  actionButton(inputId = "runmiQC", label = "Run miQC",class = "btn btn-info"),
                  tags$h4("miQC keep/discard info are in miQC.keep"),
                  tags$h4("You can remove discard cells in UTILITY CLUSTERS - Delete clusters"),
                  tags$h4("Or use the button below"),
                  actionButton(inputId = "deleteQC", label = "Delete low quality cells",class = "btn btn-danger"),
                verbatimTextOutput("miqctable"),
                  plotOutput(outputId = "miqc"),

                      )
               )),



              tabPanel("scATAC-seq",
                       fluidRow(
                         box(
                           width = 3, status = "info", solidHeader = TRUE,
                           title = "Quality control",
                           tags$h3("Display soft filtered quality control plots"),
                           actionButton(inputId = "qcDisplayATAC", label = "OK"),
                         ),
                         box(
                           width = 9, status = "info", solidHeader = TRUE,
                           title = "Quality control plots",
                           div(class="ldBar", id="qc_loader3", "data-preset"="circle"),
                           div(
                             column(
                               div(id="TSS_plot_loader",
                                   shinycssloaders::withSpinner(
                                     plotlyOutput(outputId = "TSS_plot", height = "100%")
                                     )
                                   ), width = 4),
                             column(
                               div(id="nFrag_plot_loader",
                                   shinycssloaders::withSpinner(
                                     plotOutput(outputId = "nFrag_plot", height = "100%")
                                     )
                                   ), width = 4),
                             column(
                               div(id="TSS_nFrag_plot_loader",
                                   shinycssloaders::withSpinner(
                                     plotlyOutput(outputId = "TSS_nFrag_plot", height = "100%")
                                     )
                                   ), width = 4),
                             column(verbatimTextOutput(outputId = "CellStatsATAC"), width = 5)
                           )
                         )
                       )
                          )
              )
      ),

      #Normalization tab
      tabItem(tabName = "normalize",
              fluidRow(
                box(
                  width = 4, status = "info", solidHeader = TRUE,
                  title = "Normalize and scale the data",
                  tags$h3("1. Normalization method"),
                  tags$hr(),
                 radioButtons("logSCT", label = "",
                               choices = list("Log normalization" = "Log",
                                              "SC transform" = "SCT",
                                              "For TPM/CPM (log1P)" = 'log1p'), selected = "Log"),
                  sliderInput(inputId = "normScaleFactor", label = "Scale factor :", min = 1000, max = 1000000, value = 10000, step = 1000)%>%
                    shinyInput_label_embed(
                      shiny_iconlink() %>%
                        bs_embed_popover(
                          title = "It normalizes the count data per cell and transforms the result to log scale", placement = "left"
                        )
                    ),
                  tags$h3("2. Method for identification of highly variable features"),
                  tags$hr(),
                  radioButtons("radioHVG", label ="",
                               choices = list("Variance Stabilizing Transformation method" = "vst",
                                              "Mean-Variance method" = "mvp",
                                              "Dispersion method" = "disp"
                                              ),
                               selected = "vst")%>%
                    shinyInput_label_embed(
                      shiny_iconlink() %>%
                        bs_embed_popover(
                          title = paste0("- vst: First, fits a line to the relationship of log(variance) and log(mean) using local polynomial regression (loess). Then standardizes the feature values using the observed mean and expected variance (given by the fitted line). Feature variance is then calculated on the standardized values after clipping to a maximum (see clip.max parameter).\n\n",
                                         "- mean.var.plot (mvp): First, uses a function to calculate average expression (mean.function) and dispersion (dispersion.function) for each feature. Next, divides features into num.bin (deafult 20) bins based on their average expression, and calculates z-scores for dispersion within each bin. The purpose of this is to identify variable features while controlling for the strong relationship between variability and average expression.\n\n",
                                         "- dispersion (disp): selects the genes with the highest dispersion values"), placement = "left"
                        )
                    ),
                  sliderInput(inputId = "nHVGs", label = "Number of genes to select as top variable genes (applicable only to the first and third option) :", min = 200, max = 8000, value = 2000, step = 100),
                  checkboxInput("includeGenesOfInterest", label = "Include genes of interest in HVGs", value = FALSE),
                  conditionalPanel(
                    condition = "input.includeGenesOfInterest == true",
                    selectizeInput("genesOfInterest", "Select genes to include:",
                                   choices = NULL,
                                   selected = NULL,
                                   multiple = TRUE,
                                   options = list(placeholder = 'Type gene names...'))
                  ),

                  tags$h3("3. Scaling options"),
                  tags$hr(),
                  radioButtons("normalizeScaleGenes", label = h3("Genes to be scaled : "),
                               choices = list("All genes" = "all_genes",
                                              "Only most variable genes" = "mv_genes"),
                               selected = "mv_genes"),
                  tags$br(),
                  radioButtons("cellcycleregress", label = "Regress out cell cycle scores?",
                                choices = list("No" = "none", "All cell cycle" = "all", "Difference in G2M/S only (for hematopoisis)" = 'g2m'),
                                    selected = 'none'),
                  tags$br(),
                  selectInput("normalizeRegressColumns", "Select variables to regress out (ex, percent.mt)", list(), selected = NULL, multiple = TRUE, selectize = TRUE, width = NULL, size = NULL),
                    tags$h5("Should add percent.mt for SCT"),

                  checkboxInput("ScaleIndividual", label= "Scale data within each sample individually for merged data. Do not uncheck this option unless you want to scale data in whole merged data.", value = TRUE, width = NULL),
                  selectInput(inputId = "BatchIdent2", label = "Choose identity for samples:",
                                          c("Cluster" = "orig.ident")),
                  tags$br(),
                  actionButton(inputId = "normalizeConfirm", label = "Run normalization & scaling",class = "btn btn-warning"),
                  tags$br(),
                  tags$br(),

                tags$h4("For dataset without raw count data"),
                                  tags$hr(),
                actionButton(inputId = "OnlyScaling", label = "Run scaling only", class='btn btn-info'),
                ),
                box(
                  width = 8, status = "info", solidHeader = TRUE,
                  title = "Highly variable genes",
                  div(class="ldBar", id="normalize_loader", "data-preset"="circle"),
                  div(id="hvgScatter_loader",

                        plotlyOutput(outputId = "hvgScatter", height = "800px")

                  ),
                  column(verbatimTextOutput(outputId = "hvgTop10Stats"), width = 8)
                ),
              ),
      ),

      #PCA tab
      tabItem(tabName = "pca",
              tabsetPanel(type = "tabs", id = "pcaTabPanel",
          tabPanel("scRNA-seq: PCA",
                   fluidRow(
                     box(
                       width = 12, status = "info", solidHeader = TRUE,
                       title = "PCA results", height = "1200px",
                       tabsetPanel(type = "tabs",
                                   tabPanel("PCA run",
                                            column(radioButtons("pcaRadio", label = h3("Suggest optimal number of PCs Using 10-fold SVA-CV: "),
                                                                choices = list("Yes (slow operation)" = "yes",
                                                                               "No" = "no"),
                                                                selected = "no"), width = 12),
                                            column(actionButton(inputId = "PCrunPCA", label = "Run PCA",class = "btn btn-warning"), width = 12),
                                            column(   selectInput(inputId = "utilitiesActiveAssay3", label = "Choose assay for PCA:",  c("assay" = "RNA") ), width = 12),
                                            column(checkboxInput(inputId = "pca_use_all_features", label = "Use all scaled data (not just variable features)", value = FALSE), width = 12),
                                            div(class="ldBar", id="PCA1_loader", "data-preset"="circle"),
                                            div(
                                              column(
                                                div(id="elbowPlotPCA_loader",
                                                    shinycssloaders::withSpinner(
                                                      plotlyOutput(outputId = "elbowPlotPCA", height = "500px") # original 750
                                                    )
                                                ), width = 6),
                                              column(
                                                div(id="PCAscatter_loader",
                                                    shinycssloaders::withSpinner(
                                                      plotlyOutput(outputId = "PCAscatter", height = "500px") # 750
                                                    )
                                                ), width = 6)
                                            )
                                   ),
                                   tabPanel("PCA exploration",
                                            selectInput("PCin", "Select a principal component :", choices=1:100, selected = 1, multiple = FALSE,selectize = TRUE, width = NULL, size = NULL),
                                            column(actionButton(inputId = "PCconfirm", label = "OK"), width = 12),
                                            div(class="ldBar", id="PCA2_loader", "data-preset"="circle"),
                                            div(
                                              column(
                                                tags$h3("PCA loading scores (top-30 genes for this PC)"),
                                                div(id="PCAloadings_loader",
                                                    shinycssloaders::withSpinner(
                                                      plotlyOutput(outputId = "PCAloadings", height = "600px") # 700px
                                                    )
                                                ), width = 6),
                                              column(
                                                tags$h3("Heatmap of scaled expression (top-30 genes for this PC)"),
                                                div(id="PCAheatmap_loader",
                                                    shinycssloaders::withSpinner(
                                                      plotlyOutput(outputId = "PCAheatmap", height = "600px") # 700px
                                                    )
                                                ), width = 6)
                                            ),
                                            downloadButton(outputId = "pcaRNAExport", label = "Save table")
                                   ),
                                   tabPanel("PC Covariate Analysis",
                                            tags$h3("Analyze PC-Covariate Relationships"),
                                            tags$hr(),
                                            fluidRow(
                                              column(width = 4,
                                                box(width = 12, status = "info", solidHeader = TRUE,
                                                    title = "Analysis Parameters",
                                                    selectInput("pcCovReduction",
                                                               "Select reduction:",
                                                               choices = c("RNA.pca" = "RNA.pca"),
                                                               selected = "RNA.pca"),
                                                    sliderInput("pcCovNumPCs",
                                                               "Number of PCs to analyze:",
                                                               min = 3, max = 20, value = 5, step = 1),
                                                    tags$h4("Select Covariates (max 4):"),
                                                    selectInput("pcCovCovariate1",
                                                               "Covariate 1:",
                                                               choices = c("None" = ""),
                                                               selected = ""),
                                                    selectInput("pcCovCovariate2",
                                                               "Covariate 2:",
                                                               choices = c("None" = ""),
                                                               selected = ""),
                                                    selectInput("pcCovCovariate3",
                                                               "Covariate 3:",
                                                               choices = c("None" = ""),
                                                               selected = ""),
                                                    selectInput("pcCovCovariate4",
                                                               "Covariate 4:",
                                                               choices = c("None" = ""),
                                                               selected = ""),
                                                    tags$hr(),
                                                    selectInput("pcCovRandomEffect1",
                                                               "Random effect 1 (optional):",
                                                               choices = c("None" = ""),
                                                               selected = ""),
                                                    selectInput("pcCovRandomEffect2",
                                                               "Random effect 2 (optional):",
                                                               choices = c("None" = ""),
                                                               selected = ""),
                                                    tags$hr(),
                                                    checkboxInput("pcCovIncludeInteractions",
                                                                 "Include interaction: Covariate 1 × Covariate 2",
                                                                 value = FALSE),
                                                    tags$small("チェックするとCovariate 1とCovariate 2の交互作用項のみをモデルに追加します。他の共変量は主効果のみ含まれます。"),
                                                    tags$hr(),
                                                    actionButton(inputId = "pcCovReset",
                                                                label = "Reset All Selections",
                                                                class = "btn btn-default",
                                                                style = "margin-bottom: 10px;"),
                                                    tags$br(),
                                                    actionButton(inputId = "pcCovRun",
                                                                label = "Run Analysis",
                                                                class = "btn btn-warning"),
                                                    tags$br(),
                                                    tags$br(),
                                                    downloadButton(outputId = "pcCovDownload",
                                                                  label = "Download Results (ZIP)"),
                                                    tags$hr(),
                                                    tags$div(style="background-color: #fffacd; padding: 12px; margin-top: 15px; border-radius: 5px; border-left: 4px solid #ffa500;",
                                                      tags$h4("典型的な使用例（scRNA-seq解析）", style="margin-top: 0;"),
                                                      tags$p(tags$b("前提：")),
                                                      tags$ul(style="margin-bottom: 8px;",
                                                        tags$li(tags$b("sample"), ": マウス個体/ドナーID（同一sample由来の細胞は非独立）"),
                                                        tags$li(tags$b("sex"), ": 生物学的要因（オス/メス等）"),
                                                        tags$li(tags$b("cell.ident"), ": 細胞サブタイプ/クラスタ")
                                                      ),
                                                      tags$p(tags$b("モデルの立て方：")),
                                                      tags$ol(style="margin-bottom: 8px;",
                                                        tags$li(tags$b("サブタイプ効果のみ"), ": Covariate 1にcell.ident → PC1/PC2などサブタイプで説明される軸を同定"),
                                                        tags$li(tags$b("主効果モデル"), ": Covariate 1にsex、Covariate 2にcell.ident → サブタイプを調整した平均的な性差を評価"),
                                                        tags$li(tags$b("交互作用モデル"), ": 上記に加えて「Covariate 1 × 2」にチェック → サブタイプごとに性差の向きや大きさが異なるか（例：arterialでは♀>♂、venousでは♂>♀）を検定")
                                                      ),
                                                      tags$p(tags$b("必須事項："), style="color: #d9534f; margin-bottom: 5px;"),
                                                      tags$ul(style="margin-bottom: 5px;",
                                                        tags$li(tags$b("Random effect 1に必ずsampleを指定"), "（同一sample由来の細胞間相関を調整）"),
                                                        tags$li("交互作用の有無は", tags$b("Model Comparisonタブ"), "の", tags$b("lrt_pvalue"), "で判定（p < 0.05で有意）")
                                                      ),
                                                      tags$p(tags$small("※ Random effectを指定しない単純な線形モデル（lm）では、細胞の非独立性を無視するためp値が過度に有意になります。生物学的に妥当な結論を得るには、必ずランダム効果を含む混合効果モデル（lmer）を使用してください。"),
                                                            style="margin-top: 10px; color: #555;")
                                                    )
                                                )
                                              ),
                                              column(width = 8,
                                                box(width = 12, status = "info", solidHeader = TRUE,
                                                    title = "Results",
                                                    tabsetPanel(type = "tabs",
                                                      tabPanel("Summary Statistics",
                                                               div(class="ldBar", id="pcCov_loader", "data-preset"="circle"),
                                                               tags$br(),
                                                               tags$div(style="background-color: #f0f8ff; padding: 10px; margin-bottom: 10px; border-radius: 5px;",
                                                                 tags$h5("結果の見方："),
                                                                 tags$ul(
                                                                   tags$li(tags$b("fixed_coef_[共変量]"), ": 回帰係数（連続変数では傾き、カテゴリカル変数では1つの水準の効果）"),
                                                                   tags$li(tags$b("fixed_pval_[共変量]"), ": 個別係数のp値（", tags$i("カテゴリカル変数では全体の有意性ではない"), "）"),
                                                                   tags$li(tags$b("fixed_global_pval_[共変量]"), ": ", tags$span(style="color: #d9534f; font-weight: bold;", "因子全体のp値（F検定から計算、推奨）")),
                                                                   tags$li(tags$b("partial_r2_[共変量]"), ": Partial R²（そのPCの分散のうち、この共変量で説明される割合）"),
                                                                   tags$li(tags$b("fixed_r2"), ": 全共変量を含むモデルのR²（モデル全体の説明力）")
                                                                 ),
                                                                 tags$p(tags$b("統計的に重要な注意点："), style="margin-top: 10px; color: #d9534f;"),
                                                                 tags$ul(
                                                                   tags$li(tags$b("カテゴリカル変数（batch, cell_type等）"), "：fixed_pvalは1つの水準のp値のみ。", tags$b("fixed_global_pval"), "を使用すること"),
                                                                   tags$li(tags$b("Partial R²（交互作用あり）"), "：主効果のPartial R²には、その因子が関与する", tags$i("すべての交互作用も含む"), "（例：sexのPartial R² = sex主効果 + sex:cell.ident交互作用）"),
                                                                   tags$li(tags$b("ヒートマップとプロット"), "：カテゴリカル変数ではglobal p-valueを表示（因子全体の有意性）")
                                                                 ),
                                                                 tags$p(tags$b("解釈のポイント："), style="margin-top: 10px;"),
                                                                 tags$ul(
                                                                   tags$li("Partial R²が高い（0.1以上）+ global p値が小さい（< 0.05）= その共変量とPCの間に強い関連がある"),
                                                                   tags$li("例：PC_1のpartial_r2_cell_type = 0.35 → PC1の分散の35%が細胞タイプで説明される"),
                                                                   tags$li("Partial R²が高いPCは、その生物学的・技術的要因の影響を強く受けている")
                                                                 )
                                                               ),
                                                               dataTableOutput(outputId = "pcCovStatsTable"),
                                                               downloadButton(outputId = "pcCovStatsDownload",
                                                                            label = "Download Table")
                                                      ),
                                                      tabPanel("Model Comparison",
                                                               tags$h4("フルモデル vs 縮小モデル の比較"),
                                                               tags$p("各共変量を除いた場合のモデルの適合度を比較"),
                                                               tags$br(),
                                                               tags$div(style="background-color: #fff3cd; padding: 10px; margin-bottom: 10px; border-radius: 5px;",
                                                                 tags$h5("結果の見方（線形モデル）："),
                                                                 tags$ul(
                                                                   tags$li(tags$b("term_removed"), ": 除外した項（主効果または交互作用項）"),
                                                                   tags$li(tags$b("term_type"), ": 項のタイプ（main_effect: 主効果, interaction: 交互作用）"),
                                                                   tags$li(tags$b("full_model_r2"), ": すべての項を含むモデルのR²"),
                                                                   tags$li(tags$b("reduced_model_r2"), ": その項を除いたモデルのR²"),
                                                                   tags$li(tags$b("partial_r2"), ": その項が説明する分散の割合（full - reduced）"),
                                                                   tags$li(tags$b("delta_aic"), ": 線形モデルのAIC変化量（reduced - full）"),
                                                                   tags$li(tags$b("f_statistic"), ": F統計量（ANOVA F検定）"),
                                                                   tags$li(tags$b("f_test_pvalue"), ": F検定のp値（項追加がモデルを有意に改善するか）")
                                                                 ),
                                                                 tags$h5("結果の見方（混合効果モデル、ランダム効果指定時のみ）：", style="margin-top: 15px;"),
                                                                 tags$ul(
                                                                   tags$li(tags$b("mixed_r2m"), ": Marginal R²（固定効果のみで説明される分散）"),
                                                                   tags$li(tags$b("mixed_r2c"), ": Conditional R²（固定効果+ランダム効果で説明される分散）"),
                                                                   tags$li(tags$b("mixed_delta_aic"), ": 混合効果モデルのAIC変化量"),
                                                                   tags$li(tags$b("chisq_statistic"), ": χ²統計量（尤度比検定/LRT）"),
                                                                   tags$li(tags$b("lrt_pvalue"), ": LRTのp値（混合効果モデルで項追加が有意か）")
                                                                 ),
                                                                 tags$p(tags$b("解釈のポイント："), style="margin-top: 10px;"),
                                                                 tags$ul(
                                                                   tags$li(tags$b("主効果（main_effect）"), "→ 共変量の直接的な影響"),
                                                                   tags$li(tags$b("交互作用（interaction）"), "→ 2つの共変量の組み合わせによる効果"),
                                                                   tags$li(tags$b("線形モデル："), "全細胞を独立として扱う"),
                                                                   tags$ul(
                                                                     tags$li(tags$b("Partial R²が大きい"), "→ その項がPCを強く説明する（重要）"),
                                                                     tags$li(tags$b("F検定のp値が小さい（< 0.05）"), "→ 項を追加するとモデルが有意に改善（重要）")
                                                                   ),
                                                                   tags$li(tags$b("混合効果モデル："), "ドナー等のグルーピング構造を考慮"),
                                                                   tags$ul(
                                                                     tags$li(tags$b("LRTのp値が小さい（< 0.05）"), "→ ランダム効果を考慮しても項が有意に寄与（重要）"),
                                                                     tags$li(tags$b("mixed_r2m（周辺R²）"), "→ 固定効果のみの説明力"),
                                                                     tags$li(tags$b("mixed_r2c（条件付きR²）"), "→ 固定効果+ランダム効果の説明力"),
                                                                     tags$li("mixed_r2c - mixed_r2m → ランダム効果（ドナー等）の寄与度")
                                                                   ),
                                                                   tags$li("例：cell_type:batch交互作用でpartial_r2 = 0.15, lrt_pvalue < 0.001 → 細胞タイプによってバッチ効果が異なり、ドナー間変動を考慮しても有意")
                                                                 ),
                                                                 tags$p(tags$b("具体的な使い方："), style="margin-top: 10px;"),
                                                                 tags$ul(
                                                                   tags$li("バッチ効果の確認：Partial R²が高いPCはバッチ補正が必要かも"),
                                                                   tags$li("生物学的要因の特定：細胞タイプのPartial R²が高いPCは細胞の違いを捉えている"),
                                                                   tags$li("交互作用の評価：cell_type:treatmentのPartial R²が高い → 処置効果が細胞タイプ依存的"),
                                                                   tags$li("クラスタリングへの影響：不要な項（バッチなど）で説明されるPCは除外を検討")
                                                                 )
                                                               ),
                                                               dataTableOutput(outputId = "pcCovModelCompTable"),
                                                               downloadButton(outputId = "pcCovModelCompDownload",
                                                                            label = "Download Table")
                                                      ),
                                                      tabPanel("Partial R² Heatmap",
                                                               tags$div(style="background-color: #e7f3ff; padding: 10px; margin-bottom: 10px; border-radius: 5px;",
                                                                 tags$h5("ヒートマップの見方："),
                                                                 tags$ul(
                                                                   tags$li("色が濃い（赤）ほど、その共変量がそのPCを強く説明している"),
                                                                   tags$li("数値はPartial R²（0〜1の範囲、1に近いほど強い関連）"),
                                                                   tags$li("縦軸：主成分（PC）、横軸：共変量（細胞タイプ、バッチなど）")
                                                                 ),
                                                                 tags$p(tags$b("使い方："), style="margin-top: 10px;"),
                                                                 tags$ul(
                                                                   tags$li("赤い部分を探す → そのPC×共変量の組み合わせが重要"),
                                                                   tags$li("例：PC1がcell_typeで赤い → PC1は主に細胞タイプの違いを捉えている"),
                                                                   tags$li("例：PC3がbatchで赤い → PC3はバッチ効果の影響を受けている（要注意）")
                                                                 )
                                                               ),
                                                               div(id="pcCovHeatmap_loader",
                                                                   shinycssloaders::withSpinner(
                                                                     plotOutput(outputId = "pcCovR2Heatmap",
                                                                               height = "600px")
                                                                   )
                                                               ),
                                                               downloadButton(outputId = "pcCovR2HeatmapDownload",
                                                                            label = "Download Plot")
                                                      ),
                                                      tabPanel("P-value Heatmap",
                                                               tags$div(style="background-color: #ffe7e7; padding: 10px; margin-bottom: 10px; border-radius: 5px;",
                                                                 tags$h5("P値ヒートマップの見方："),
                                                                 tags$ul(
                                                                   tags$li("色が濃い（濃い赤）ほど、統計的に有意な関連がある"),
                                                                   tags$li("数値は-log10(p値)を表示（大きいほど有意）"),
                                                                   tags$li(tags$b("*マーク"), "がある = p < 0.05（統計的に有意）")
                                                                 ),
                                                                 tags$p(tags$b("解釈のガイド："), style="margin-top: 10px;"),
                                                                 tags$ul(
                                                                   tags$li("-log10(p) > 1.3（p < 0.05）→ 有意な関連あり"),
                                                                   tags$li("-log10(p) > 2（p < 0.01）→ 強い有意性"),
                                                                   tags$li("-log10(p) > 3（p < 0.001）→ 非常に強い有意性"),
                                                                   tags$li("*マークがあり、Partial R²ヒートマップでも赤い → 確実に重要な関連")
                                                                 ),
                                                                 tags$p(tags$b("注意点："), style="margin-top: 10px;"),
                                                                 tags$ul(
                                                                   tags$li("p値だけでなく、Partial R²（効果量）も確認すること"),
                                                                   tags$li("サンプル数が多いと、小さな効果でも有意になる可能性がある")
                                                                 )
                                                               ),
                                                               div(id="pcCovPvalHeatmap_loader",
                                                                   shinycssloaders::withSpinner(
                                                                     plotOutput(outputId = "pcCovPvalHeatmap",
                                                                               height = "600px")
                                                                   )
                                                               ),
                                                               downloadButton(outputId = "pcCovPvalHeatmapDownload",
                                                                            label = "Download Plot")
                                                      ),
                                                      tabPanel("Individual PC Plots",
                                                               selectInput("pcCovPlotPC",
                                                                          "Select PC:",
                                                                          choices = c("Run analysis first" = "")),
                                                               selectInput("pcCovPlotCovariate",
                                                                          "Select Covariate:",
                                                                          choices = c("")),
                                                               actionButton(inputId = "pcCovPlotGenerate",
                                                                           label = "Generate Plot"),
                                                               div(id="pcCovIndivPlot_loader",
                                                                   shinycssloaders::withSpinner(
                                                                     plotOutput(outputId = "pcCovIndividualPlot",
                                                                               height = "500px")
                                                                   )
                                                               ),
                                                               downloadButton(outputId = "pcCovIndivPlotDownload",
                                                                            label = "Download Plot")
                                                      )
                                                    )
                                                )
                                              )
                                            )
                                   )
                       )
                     )
                   )
                          ),
                          tabPanel("scATAC-seq: LSI",
                                   fluidRow(
                                     box(
                                       width = 6, status = "info", solidHeader = TRUE,
                                       title = "Latent Semantic Indexing", height = "1290px",
                                       tags$h3("Input parameters"),
                                       tags$hr(),
                                       sliderInput(inputId = "lsiVarFeatures", label = "Number of variable feures: ", min = 5000, max = 100000, value = 25000, step = 1000),#varFeatures
                                       sliderInput(inputId = "lsiDmensions", label = "Number of dimensions to use: ", min = 1, max = 100, value = 30, step = 1),#dimensions
                                       sliderInput(inputId = "lsiResolution", label = "Resolution :", min = 0.1, max = 5, value = 1, step = 0.1),#resolution
                                       sliderInput(inputId = "lsiIterations", label = "Number of iterations: ", min = 1, max = 10, value = 1, step = 1),#iterations
                                       actionButton(inputId = "lsiConfirm", label = "Run LSI"),
                                       tags$hr(),
                                       div(class="ldBar", id="lsi_loader", "data-preset"="circle"),
                                       verbatimTextOutput(outputId = "lsiOutput")
                                     )
                                   )
                          )
              )
      ),

      #Clustering tab
      tabItem(tabName = "clustering",
              tabsetPanel(type = "tabs", id = "clusteringTabPanel",
                  tabPanel("scRNA-seq",
                   fluidRow(
                     box(
                       width = 4, status = "info", solidHeader = TRUE,
                       title = "Clustering options",
                       tags$h3("1. Seurat"),
                       tags$hr(),
                       selectInput(inputId = "clusterAlg", label = "Choose clustering algorithm:",  c("original Louvain" = 1,
                          "Louvain with multilevel refinement" = 2, "SLM" = 3, "Leiden" = 4), selected = 4 ),
                       tags$h5("Seurat's default is Louvain. Leiden ensures that all nodes within a cluster are connected."),
                       numericInput(inputId = "snnK", label = "Number of neighbours for each cell [k]:", min = 1, max = 200, value = 20, step = 1),
                       sliderInput(inputId = "snnPCs", label = "Number of principal components to use :", min = 5, max = 50, value = 30, step = 1),

                      # FindNeighbors options
                      checkboxInput("showFindNeighborsOpt", "FindNeighbors options", value = FALSE),
                      conditionalPanel(
                        condition = "input.showFindNeighborsOpt",
                        selectInput(inputId = "nnMethod",
                                   label = "Nearest neighbor method (nn.method):",
                                   choices = c("annoy" = "annoy", "rann" = "rann"),
                                   selected = "annoy"),
                        conditionalPanel(
                          condition = "input.nnMethod == 'annoy'",
                          selectInput(inputId = "annoyMetric",
                                     label = "Annoy distance metric (annoy.metric):",
                                     choices = c("euclidean" = "euclidean",
                                               "cosine" = "cosine",
                                               "manhattan" = "manhattan",
                                               "hamming" = "hamming"),
                                     selected = "euclidean")
                        )
                      ),

                      conditionalPanel(
                        condition = "!input.smallerStep",
                        sliderInput("clusterRes",
                                    label = "Clustering resolution :",
                                    min = 0.1, max = 3, value = 0.5, step = 0.1)
                      ),
                      
                      conditionalPanel(
                        condition = "input.smallerStep",
                        sliderInput("clusterRes", 
                                    label = "Clustering resolution :", 
                                    min = 0.025, max = 1.5, value = 0.5, step = 0.025)
                      ),
                      
                      # checkboxInputを後に配置
                      checkboxInput("smallerStep", "Smaller step for resolution?", value = FALSE),

                       actionButton(inputId = "snnConfirm", label = "Perform clustering",class = "btn btn-warning"),

                       tags$h4("Option:"),
                       tags$h5("Clusters are calculated on the reduction below."),
             #        selectInput(inputId = "utilitiesActiveAssay2", label = "Choose assay:",  c("assay" = "RNA") ),
                       selectInput(inputId = "utilitiesActiveReduction", label = "Choose reduction:",  c("reduction" = "pca") ),
              #        tags$h5('eg, assay:RNA=reduction:RNA-pca, SCT=SCT-pca, RNA=RNA-mnn, SCT=SCT-mnn'),
                    #   actionButton(inputId = "changeReductionConfirm", label = "Change active reduction",class = "btn btn-info"),
                        tags$br(),
                       tags$hr(),
                        tags$h5("Show the dimensions used in previous clustering"),
                    actionButton(inputId = "utilitiesConfirmDim2", label = "Display"),
                    verbatimTextOutput("ClusterDim2"),

                        tags$h3(" "),
                       tags$h3("2. Monocle3 clustering"),
                       tags$br(),
                       tags$hr(),
                       selectInput(inputId = "mnclumapType", label = "Choose reduction:",  c("reduction" = "umap") ),
                       checkboxInput("mnclAuto", label= "Automatically determine resolution?", value = FALSE, width = NULL),
                       numericInput("mnclResolution", "Resolution:", min = 1e-10, max = 1, value = 1e-4),
                    actionButton(inputId = "mnclCondirm", label = "Perform Monocle3 clustering"),

                     ),
                     box(
                       width = 8, status = "info", solidHeader = TRUE, title = "Clustering output",
                       textOutput("reduction_use"),
                       tabsetPanel(type = "tabs",
                                   tabPanel("Clustering results",
                                            tabsetPanel(type = "tabs",
                                        tabPanel("Cluster table",
                                                 div(class="ldBar", id="clust1_loader", "data-preset"="circle"),
                                                 dataTableOutput(outputId="clusterTable"),
                                                 downloadButton(outputId = "clusterTableRNAExport", label = "Save table")
                                        ),
                                        tabPanel("Cluster barplot",
                                            selectInput("utilitiesActiveClusters4", "Select the cluster identity to use as the active seurat_clusters:",
                                              c("Cluster" = "seurat_clusters")),
                                              actionButton(inputId = "utilitiesConfirmChangeCluster4", label = "Change identity",class = "btn btn-info"),
                                          tags$hr(),
                                          tags$br(),
                                         selectInput("clusterGroupBy", "Grouping variable:", c("orig.ident" = "orig.ident")),
                                         selectInput("barplotColorPalette", "Color palette:", c( "Set1",
                                        "Set2", "Set3",  "Paired", "Dark2", "Accent", "Spectral",
                                        'stallion','stallion2','calm','kelly','bear','ironMan','circus','paired',
                                        'grove','summerNight','zissou','Zissou1Continuous', 'darjeeling','rushmore','captain'), selected = 'Set1'),

                                                 actionButton(inputId = "clusterBarplotConfirm", label = "Display barchart",class = "btn btn-warning" ),
                                                 tags$h4("This shows distribution of cells in seurat_clusters."),
                                                 tags$h5("If the grouping variable is set to anything other than seurat_clusters, the distribution of seurat_clusters in each cluster of the set grouping identity."),
                          numericInput("barplotWidth", "Plot width:", min = 100, max = 1200, value = 400, step = 50),
                         numericInput("barplotHeight", "Plot height:", min = 100, max = 1600, value = 300, step = 50),
                                   downloadButton(outputId = "barplotdownloaderPNG",label = "download as png"),
                                     downloadButton(outputId = "barplotdownloaderPDF",label = "download as pdf"),
                                     downloadButton(outputId = "clusterTableExport", label = "download table"),
                                                 div(class="ldBar", id="clust2_loader", "data-preset"="circle"),
                                                 div(id="clusterBarplot_loader",
                                                      shinycssloaders::withSpinner(
                                                        uiOutput("clusterBarplotUI")  # plotOutputの代わりにuiOutputを使用
                                                      )
                                                    ),
                                                 tags$br(),
                                                 tags$br(),
                                                       dataTableOutput(outputId = "clusterTable"),
                                                     #  dataTableOutput(outputId = "clusterTable_freq")
                                                        ),

                                        tabPanel("Cluster tree",
                                         selectInput("treeGroupBy", "Iden to show cluster tree:", c("orig.ident" = "orig.ident")),
                                         tags$h5("The identity will be set to active idenity."),
                                         checkboxInput("reordertree", label= "Reorder clusters based on similarities.", value = FALSE, width = NULL),

                                         selectInput("treeColorPalette", "Color palette:", c( "Set1",
                                        "Set2", "Set3",  "Paired", "Dark2", "Accent", "Spectral",
                                        'stallion','stallion2','calm','kelly','bear','ironMan','circus','paired',
                                        'grove','summerNight','zissou','Zissou1Continuous', 'darjeeling','rushmore','captain'), selected = 'Set1'),

                                          actionButton(inputId = "clusterTreeConfirm", label = "Display cluster tree",class = "btn btn-warning" ),

                          numericInput("treeplotWidth", "Plot width:", min = 100, max = 1200, value = 400, step = 50),
                         numericInput("treeplotHeight", "Plot height:", min = 100, max = 1600, value = 300, step = 50),
                                   downloadButton(outputId = "treeplotdownloaderPNG",label = "download as png"),
                                     downloadButton(outputId = "treeplotdownloaderPDF",label = "download as pdf"),
                                                 div(class="ldBar", id="clust2_loader", "data-preset"="circle"),
                                                 div(id="clusterBarplot_loader",
                                                     shinycssloaders::withSpinner(
                                                       plotOutput(outputId = "clusterTreeplot"),
                                                     )
                                                 )
                                                        ),

                                            )
                                   ),
                                   tabPanel("Shared Nearest Neighbour (SNN) Graph",
                                            div(class="ldBar", id="clust3_loader", "data-preset"="circle"),
                                            actionButton(inputId = "snnDisplayConfirm", label = "Display SNN graph"),
                                            div(id="snnSNN_loader",
                                                shinycssloaders::withSpinner(
                                                  visNetworkOutput(outputId="snnSNN", height = "1300px")
                                                )
                                            )
                                   )
                       ),
                     ),
                                   )
                          ),


                          tabPanel("scATAC-seq",
                                   fluidRow(
                                     box(
                                       width = 4, status = "info", solidHeader = TRUE,
                                       title = "Clustering options",
                                       sliderInput(inputId = "clusterDimensionsATAC", label = "Number of dimensions to use: ", min = 1, max = 100, value = 30, step = 1),
                                       sliderInput(inputId = "clusterResATAC", label = "Clustering resolution :", min = 0.1, max = 60, value = 0.6, step = 0.1),
                                       actionButton(inputId = "clusterConfirmATAC", label = "Perform clustering"),
                                     ),
                                     box(
                                       width = 8, status = "info", solidHeader = TRUE, title = "Clustering output",
                                       tabsetPanel(type = "tabs",
                                       tabPanel("Clustering results",
                                                tabsetPanel(type = "tabs",
                                                tabPanel("Cluster table",
                                                         div(class="ldBar", id="clust4_loader", "data-preset"="circle"),
                                                         dataTableOutput(outputId="clusterTableATAC"),
                                                         downloadButton(outputId = "clusterTableExportATAC", label = "Save table")
                                                ),
                                                tabPanel("Cluster barplot",
                                                         div(id="clusterBarplotATAC_loader",
                                                             shinycssloaders::withSpinner(
                                                               plotlyOutput(outputId = "clusterBarplotATAC", height = "700")
                                                             )
                                                  )
                                                    )
                                                  )
                                           )
                                       ),
                                     ),
                                   )
                          )
              )
      ),

      #UMAP tab
      tabItem(tabName = "umap",
        tabsetPanel(type = "tabs", id = "umapTabPanel",
           tabPanel("scRNA-seq",
                fluidRow(
                     box(width = 3, status = "info",
                    tabsetPanel(type = "tabs",
                        tabPanel("Calculation",
                         tags$h3("Calculate reduction"),
                       conditionalPanel(
                                condition = "input.reductionMethod != 'umapRunPhate'",
                           selectInput(inputId = "utilitiesActiveReduction2", label = "Choose reduction for calc UMAP etc:",  c("reduction" = "RNA.pca") ),
                           sliderInput(inputId = "umapPCs", label = "Number of principal components to use :", min = 1, max = 50, value = 30, step = 1),
                           checkboxInput("useAllDims", label= "Use all dimensions to calculate?", value = FALSE, width = NULL)
                        ),
                         sliderInput(inputId = "umapOutComponents", label = "Number of dimensions to calculate:", min = 2, max = 50, value = 2, step = 1)%>%
                           shinyInput_label_embed(
                             shiny_iconlink() %>%
                               bs_embed_popover(
                                 title = "If PHATE is selected, the runtime increases when a value > 3 is used.\npca, umap, dfmは次元数を増やしても低次元の値は変化しません。", placement = "bottom")),
                     
                    checkboxInput("randomSeed", label= "Set random seed?", value = FALSE, width = NULL),
                   conditionalPanel(
                                condition = "input.randomSeed",
                     sliderInput(inputId = "umapSeed", label = "Set seed for random function:", min = 1, max = 500, value = 42, step = 1)
                     ),




                             # ラジオボタンとRUNボタン
                        radioButtons(inputId = "reductionMethod",
                                     label = "Select method:",
                                     choices = c("UMAP" = "umapRunUmap",
                                                "tSNE" = "umapRunTsne",
                                                "Diffusion Map" = "umapRunDFM",
                                                "PHATE" = "umapRunPhate",
                                                "PaCMAP" = "umapRunPacmap",
                                                "ForceAtlas2" = "umapRunFA2",
                                                "TriMap" = "umapRunTrimap",
                                                "DensityPath" = "umapRunDensity"),
                                     selected = "umapRunUmap"),
                        actionButton(inputId = "runReduction", label = "Run", class = "btn btn-warning"),
                          hidden(
                          div(id = "hiddenButtons",
                                               actionButton(inputId = "umapRunUmap", label = "Run UMAP",class = "btn btn-info"),
                                               actionButton(inputId = "umapRunTsne", label = "Run tSNE"),
                                               actionButton(inputId = "umapRunDFM", label = "Run Diffusion Map"),
                                               actionButton(inputId = "umapRunPhate", label = "Run PHATE"),
                                               actionButton(inputId = "umapRunPacmap", label = "Run PaCMAP"),
                                               actionButton(inputId = "umapRunFA2", label = "Run ForceAtlas2"),
                                               actionButton(inputId = "umapRunTrimap", label = "Run TriMap"),
                                               actionButton(inputId = "umapRunDensity", label = "Run DensityPath"),

                                      )),   

                        tags$hr(),

                    conditionalPanel(
                                    condition = "input.reductionMethod == 'umapRunUmap'",

                           numericInput("umap_n_neighbors", "UMAP n_neigbors", min = 2, max = 100, value = 30, step = 1) %>%
                        shinyInput_label_embed(
                          shiny_iconlink() %>%
                            bs_embed_popover(
                              title = "n_neighborsは各データポイントを埋め込む際に考慮される近隣の点の数。数値が大きいと全体的構造が強調され、小さいと局所構造が保存される。典型的には2-100。Seurat default: 30", placement = "left"
                            )
                        ),
                           numericInput("umap_min_dist", "UMAP min dist", min = 0, max = 1, value = 0.3, step = 0.1) %>%
                        shinyInput_label_embed(
                          shiny_iconlink() %>%
                            bs_embed_popover(
                              title = "次元圧縮後の点間の最短距離を示す。小さいと点が密集し、大きいと点が広がりトポロジカルな構造を保存する。Seurat default:0.3", placement = "left"
                            )
                        ),

                           checkboxInput("densmap", label= "Use density-preserving densMAP?", value = FALSE, width = NULL) %>%
                        shinyInput_label_embed(
                          shiny_iconlink() %>%
                            bs_embed_popover(
                              title = "データ点の「広がり」を表現することで、元のデータの密度構造をより正確に反映。",
                            placement = "left"
                            )
                    )),

                    conditionalPanel(
                                condition = "input.densmap",

                              numericInput("dens.lambda", "dens_lamda", min = 0, max = 1, value = 0.3, step = 0.1 ) %>%
                            shinyInput_label_embed(
                              shiny_iconlink() %>%
                                bs_embed_popover(
                                  title = "Higher values prioritize density preservation over UMAP objective.密度情報の重要度を調整。値が大きいほど、元のデータの密度構造をより強く反映。",
                                  placement = "left"
                                )
                            ),
                             numericInput("dens.frac", "dens_frac", min = 0.1, max = 0.5, value = 0.3, step = 0.1)%>%
                            shinyInput_label_embed(
                              shiny_iconlink() %>%
                                bs_embed_popover(
                                  title = "Higher values place more emphasis on preserving the density information from early in the optimization.
                                  全イテレーションのうち、指定した割合のイテレーションで密度保持項を目的関数に含め、残りのイテレーションでは、通常のUMAPの目的関数のみを使用。大きな値: 密度保持をより重視し、元のデータの密度構造をより強く反映。　小さな値: 通常のUMAPに近い結果となり、トポロジー構造の保持が優先。", placement = "left"
                                )
                    )),


                       conditionalPanel(
                                condition = "input.reductionMethod == 'umapRunPhate'",
                      tags$h5("In PHATE, the data slot of the active assay is used."),
                      numericInput("phateknn", "PHATE knn", min = 1, max = 10, value = 5, step = 1),
                     numericInput("phatedecay", "PHATE decay", min = 10, max = 200, value = 40, step = 1),
                     tags$h5("In PHATE, decreasing knn and increasing decay reduce connectivity. eg, knn:4, decay:100"),
                     tags$h5("You may want to use all the dims for PHATE. Check 'Use all dimensions to calculate?'")
                     ),


                    conditionalPanel(
                                condition = "input.reductionMethod == 'umapRunDensity'",

                          tags$h5("Elastic Embeddingの分布は使用する次元数の影響を受けます。"),
                          tags$h5("25-35 PCsで開始し、まれな細胞集団を同定したいときは増やす。ノイズが多いときは減らす。"),

                                ),

                    # PaCMAP parameters
                    conditionalPanel(
                                condition = "input.reductionMethod == 'umapRunPacmap'",
                      tags$h5("PaCMAP: Pairwise Controlled Manifold Approximation"),
                      numericInput("pacmap_n_neighbors", "n_neighbors", min = 2, max = 200, value = 10, step = 1) %>%
                        shinyInput_label_embed(
                          shiny_iconlink() %>%
                            bs_embed_popover(
                              title = "近傍点数。UMAPのn_neighborsと同様、局所構造の保存に影響。デフォルト: 10", placement = "left"
                            )
                        ),
                      numericInput("pacmap_MN_ratio", "MN_ratio", min = 0.1, max = 2, value = 0.5, step = 0.1) %>%
                        shinyInput_label_embed(
                          shiny_iconlink() %>%
                            bs_embed_popover(
                              title = "Mid-near ratio。中距離ペアの重み。大きいとグローバル構造を強調。デフォルト: 0.5", placement = "left"
                            )
                        ),
                      numericInput("pacmap_FP_ratio", "FP_ratio", min = 0.5, max = 5, value = 2, step = 0.1) %>%
                        shinyInput_label_embed(
                          shiny_iconlink() %>%
                            bs_embed_popover(
                              title = "Further pairs ratio。遠距離ペアの重み。大きいとクラスター間の分離を強調。デフォルト: 2", placement = "left"
                            )
                        )
                    ),

                    # ForceAtlas2 parameters
                    conditionalPanel(
                                condition = "input.reductionMethod == 'umapRunFA2'",
                      tags$h5("ForceAtlas2: Force-directed graph layout"),
                      tags$h5("SNN/KNNグラフを使用してレイアウトを計算します。"),
                      numericInput("fa2_iterations", "iterations", min = 100, max = 5000, value = 1000, step = 100) %>%
                        shinyInput_label_embed(
                          shiny_iconlink() %>%
                            bs_embed_popover(
                              title = "アルゴリズムの反復回数。多いほど安定するが計算時間増加。デフォルト: 1000", placement = "left"
                            )
                        ),
                      checkboxInput("fa2_linlog", label = "LinLog mode (強調されたクラスター分離)", value = FALSE),
                      checkboxInput("fa2_prevent_overlap", label = "Prevent overlap (重なり防止)", value = FALSE)
                    ),

                    # TriMap parameters
                    conditionalPanel(
                                condition = "input.reductionMethod == 'umapRunTrimap'",
                      tags$h5("TriMap: Dimensionality Reduction Using Triplet Constraints"),
                      numericInput("trimap_n_inliers", "n_inliers", min = 2, max = 50, value = 10, step = 1) %>%
                        shinyInput_label_embed(
                          shiny_iconlink() %>%
                            bs_embed_popover(
                              title = "各点の近傍点数。局所構造の保存に影響。デフォルト: 10", placement = "left"
                            )
                        ),
                      numericInput("trimap_n_outliers", "n_outliers", min = 2, max = 20, value = 5, step = 1) %>%
                        shinyInput_label_embed(
                          shiny_iconlink() %>%
                            bs_embed_popover(
                              title = "各点の外れ値点数。グローバル構造の保存に影響。デフォルト: 5", placement = "left"
                            )
                        ),
                      numericInput("trimap_n_random", "n_random", min = 1, max = 10, value = 5, step = 1) %>%
                        shinyInput_label_embed(
                          shiny_iconlink() %>%
                            bs_embed_popover(
                              title = "ランダムトリプレット数。デフォルト: 5", placement = "left"
                            )
                        ),
                      numericInput("trimap_n_iters", "n_iters", min = 100, max = 1000, value = 400, step = 50) %>%
                        shinyInput_label_embed(
                          shiny_iconlink() %>%
                            bs_embed_popover(
                              title = "最適化の反復回数。デフォルト: 400", placement = "left"
                            )
                        )
                    ),

tags$br(),
                    tags$hr(),
                    tags$br(),


                    actionButton(inputId = "utilitiesConfirmDim3", label = HTML("Show the dimensions used<br>in previous clustering") ),
                    verbatimTextOutput("ClusterDim3"),

                    ),
                     tabPanel("Visualization",
                         tags$h3("Display plot"),
                         tags$hr(),
                         div(class="ldBar", id="dim_red1_loader", "data-preset"="circle"),
                         selectInput(inputId = "umapType", "Plot reduction:", c("reduction" = "RNA.pca.umap")),
                    #     selectInput("umapDimensions", "Dimensions to visualize:",
                    #                 c("2D" = "2",
                    #                   "3D" = "3")),
                         selectInput("umapColorBy", "Color by:",
                                     c("Cluster" = "seurat_clusters")),

                         selectInput("umapColorPalette", "Color palette:", c( "Set1",
                                        "Set2", "Set3",  "Paired", "Dark2", "Accent", "Spectral",
                                        'stallion','stallion2','calm','kelly','bear','ironMan','circus','paired',
                                        'grove','summerNight','zissou','Zissou1Continuous', 'darjeeling','rushmore','captain'), selected = 'Set1'),
                         checkboxInput("umapRandom", label = "Randomize cell order?", value = FALSE),
                         checkboxInput("umapUseDimPlot", label= "Use DimPlot function? (cannot randomize cell order for split graph)", value = FALSE, width = NULL),
                     checkboxInput("umapSplitByFlag", label= "Split by an identity?", value = FALSE, width = NULL),
                      selectInput("umapSplitBy", "Split by:", c("Cluster" = "orig.ident"), selected = NULL),
                      tags$h5("Needs to be different from color by"),
                       actionButton(inputId = "umapConfirm", label = "Update plot",class = "btn btn-warning"),
                      tags$h4("Additional options:"),
                         numericInput("umapDotSize", "Dot size:", min = 0.1, max = 10, value = 4, step = 0.1), # value = 5
                         numericInput("umapDotOpacity", "Dot opacity (0-1):", min = 0, max = 1, value = 1, step = 0.1), # value = 1
                         numericInput("umapDotBorder", "Dot border width:", min = 0, max = 10, value = 0.2, step = 0.1),
                         numericInput("umapLabelSize", "Cluster label size:", min = 0, max = 16, value = 8, step = 1),
                         numericInput("umaplegendtextSize", "Legend font size:", min = 0, max = 30, value = 16, step = 1),
                         selectInput("umaplegendtextColor", "Legend font color:", c('black','white','gray','lightgray','azure','cornsilk','cyan','red','orange'),
                            selected = 'black'),
                        # checkboxInput("umaplegendBack", label = "White background for labels?", value = FALSE), うまく実現できていない
                         tags$hr(),
                         numericInput("umapWidth", "Plot width:", min = 200, max = 1200, value = 800, step = 50),
                         numericInput("umapHeight", "Plot height:", min = 200, max = 1600, value = 700, step = 50),
                         numericInput("umapX", "Dim to show in X:", min = 1, max = 30, value = 1, step = 1),
                         numericInput("umapY", "Dim to show in Y:", min = 1, max = 30, value = 2, step = 1),
                         checkboxInput("umapReverseX", label = "Reverse X axis?", value = FALSE),
                       checkboxInput("umapReverseY", label = "Revese Y axis?", value = FALSE),
                          tags$h5("Color palettes: see https://stats.biopapyrus.jp/r/graph/rcolorbrewer.html and https://bookdown.org/ytliu13207/SingleCellMultiOmicsDataAnalysis/color-palette.html"),
                         tags$h5("Downloaded fig size: value/72 inches"),
                         tags$h4(' '),
                         actionButton(inputId = "umapRefresh", label = "Update reductions"),
                         tags$br(),
                     ),
                        tabPanel("3D",
                         tags$h3("Display 3D plot"),
                         tags$hr(),
                         div(class="ldBar", id="dim_red1_loader", "data-preset"="circle"),
                         selectInput(inputId = "umapType3D", "Plot reduction:", c("reduction" = "RNA.pca.umap")),
                         selectInput("umapColorBy3D", "Color by:",
                                     c("Cluster" = "seurat_clusters")),

                         selectInput("umapColorPalette3D", "Color palette:", c( "Set1",
                                        "Set2", "Set3",  "Paired", "Dark2", "Accent", "Spectral",
                                        'stallion','stallion2','calm','kelly','bear','ironMan','circus','paired',
                                        'grove','summerNight','zissou','Zissou1Continuous', 'darjeeling','rushmore','captain'), selected = 'Set1'),
                         checkboxInput("umapRandom3D", label = "Randomize cell order?", value = FALSE),
                       actionButton(inputId = "umapConfirm3D", label = "Update plot",class = "btn btn-warning"),
                      tags$hr(),
                  checkboxInput("select3D", label = div("Choose a cluster to visualize?"), value = FALSE),
                   selectInput(inputId = "select3Dident", label = "Choose identity to use: ", c("Cluster" = "orig.ident")),
                    actionButton(inputId = "select3DidentConfirm", label = "Update cluster ident to choose"),
                    selectInput(inputId = "select3Dcell", label = "Cluster to visualize:", choices = "-", multiple = FALSE,selectize = FALSE),

                      tags$hr(),
                  checkboxInput("feature3D", label = div("Feature plot mode"), value = FALSE),
                  selectizeInput(inputId = 'feature3DGeneSelect',
                                              label = 'Select genes:',
                                              choices = NULL,
                                              selected = NULL,
                                              multiple = FALSE),
                  selectInput("feature3DColor", "FeaturePlot color scheme:",
                       choices = c("Magma" = "Magma",
                       "Blues" = "Blues",               # defaultをBluesに
                       "RdBu" = "RdBu",                 # Zissou1をRdBuに
                       "YlOrRd" = "YlOrRd",             # Redsの代わり
                       "YlGnBu" = "YlGnBu",             # Greensの代わり
                       "Viridis" = "Viridis",
                       "Cividis" = "Cividis",
                       "Inferno" = "Inferno",
                       "Plasma" = "Plasma"),
            selected = 'Magma'),
                  checkboxInput("reverse3D", label = div("Reverse color"), value = FALSE),

                      tags$h4("Additional options:"),
                         numericInput("umapDotSize3D", "Dot size:", min = 0.1, max = 10, value = 4, step = 0.1), # value = 5
                         numericInput("umapDotOpacity3D", "Dot opacity (0-1):", min = 0, max = 1, value = 1, step = 0.1), # value = 1
                         numericInput("umapDotBorder3D", "Dot border width:", min = 0, max = 10, value = 0.2, step = 0.1),
                      #   numericInput("umapLabelSize3D", "Cluster label size:", min = 0, max = 16, value = 0, step = 1),
                         numericInput("umaplegendtextSize3D", "Legend font size:", min = 0, max = 30, value = 12, step = 1),
#                         selectInput("umaplegendtextColor3D", "Legend font color:", c('black','white','gray','lightgray','azure','cornsilk','cyan','red','orange'),
#                            selected = 'black'),
                         tags$hr(),
                         numericInput("umapWidth3D", "Plot width:", min = 200, max = 1200, value = 800, step = 50),
                         numericInput("umapHeight3D", "Plot height:", min = 200, max = 1600, value = 700, step = 50),
                        numericInput("umapX3D", "Dim for X:", min = 1, max = 30, value = 1, step = 1),
                         numericInput("umapY3D", "Dim for Y:", min = 1, max = 30, value = 2, step = 1),
                        numericInput("umapZ3D", "Dim for Z:", min = 1, max = 30, value = 3, step = 1),
                     ),

                     )),

                    box(width = 9, status = "info", solidHeader = TRUE, title = "Plot", height = "1200px",
                                    tabsetPanel(type = "tabs",
                                     div(class="ldBar", id="dim_red2_loader", "data-preset"="circle"),
                                   tabPanel("2D",
                                      downloadButton(outputId = "umapdownloaderPNG",label = "download as png"),
                                     downloadButton(outputId = "umapdownloaderPDF",label = "download as pdf"),
                                     div(id="umapPlot_loader",
                                         shinycssloaders::withSpinner(
                                         # plotlyOutput(outputId = "umapPlot") # 1000px
                                         plotOutput(outputId = "umapPlot"),
                                         ),
                                        textOutput("reduction_use2")
                                     )),
                                     tabPanel("3D",

                                      downloadButton(outputId = "umapdownloader3D",label = "download as HTML"),
                                    downloadButton(outputId = "umapdownloader3Dpng",label = "download as png"),
                                     downloadButton(outputId = "umapdownloader3Dpdf",label = "download as pdf"),
                                        plotlyOutput(outputId = "umapPlot3d"),
                                     )
                                   )),
                          )), #scRNAのtab終わり




                          tabPanel("scATAC-seq",
                                   fluidRow(
                                     box(width = 3, status = "info", solidHeader = TRUE,
                                         title = "Cells visualization options in reduced space",
                                         sliderInput(inputId = "umapDimensionsATAC", label = "Number of input dimensions to use :", min = 1, max = 100, value = 30, step = 1),
                                         sliderInput(inputId = "umapOutComponentsATAC", label = "Number of dimensions to fit output:", min = 2, max = 100, value = 3, step = 1)%>%
                                           shinyInput_label_embed(
                                             shiny_iconlink() %>%
                                               bs_embed_popover(
                                                 title = "Please note that tSNE doesn't return more than 2 dimensions. UMAP、Dfmは次元数を変化させても結果は変化しません。", placement = "bottom"
                                               )
                                           ),
                                         actionButton(inputId = "umapRunUmapTsneATAC", label = "Run UMAP and tSNE"),
                                         tags$h3("Display settings"),
                                         tags$hr(),
                                         div(class="ldBar", id="dim_red3_loader", "data-preset"="circle"),
                                         selectInput("umapTypeATAC", "Plot type:",
                                                     c("UMAP" = "umap",
                                                       "tSNE" = "tsne")
                                         ),
                                         selectInput("umapDimensionsPlotATAC", "Dimensions:",
                                                     c("2D" = "2",
                                                       "3D" = "3")),
                                         selectInput("umapColorByATAC", "Color by:",
                                                     c("Clusters" = "Clusters")),

                                         sliderInput("umapDotSizeATAC", "Size:", min = 1, max = 20, value = 5, step = 0.5),
                                         sliderInput("umapDotOpacityATAC", "Opacity:", min = 0, max = 1, value = 1, step = 0.1),
                                         sliderInput("umapDotBorderATAC", "Border width:", min = 0, max = 10, value = 0.5, step = 0.1),
                                         actionButton(inputId = "umapConfirmATAC", label = "Display plot",class = "btn btn-warning")
                                     ),

                                     box(width = 9, status = "info", solidHeader = TRUE, title = "Plot", height = "1200px",
                                         div(class="ldBar", id="dim_red4_loader", "data-preset"="circle"),
                                         div(id="umapPlotATAC_loader",
                                             shinycssloaders::withSpinner(
                                               plotlyOutput(outputId = "umapPlotATAC", height = "1100px")
                                             )
                                         )
                                     )
                                   )
                          )
              )
      ),

      #Feature inspection
      tabItem(tabName = "features",
              tabsetPanel(type = "tabs", id = "featuresTabPanel",
                          tabPanel("scRNA-seq",
                                   fluidRow(
             tabsetPanel(type = "tabs",
                         tabPanel("Feature plot", fluidRow(
                           box(width = 3, status = "info", solidHeader = TRUE, title = "Options",
                               radioButtons("findMarkersFeatureSignature", label = "Select between gene or signature to plot: ",
                                            choices = list("Gene" = "gene",
                                                           "Gene signature" = "signature"
                                            ),
                                            selected = "gene"),

                              conditionalPanel(
                                condition = "input.findMarkersFeatureSignature == 'gene'",
                                selectizeInput(
                                  inputId = 'findMarkersGeneSelect',
                                  label = 'Select genes:',
                                  choices = NULL,
                                  selected = NULL,
                                  multiple = TRUE
                                )
                              ),

                              conditionalPanel(
                              condition = "input.findMarkersFeatureSignature != 'gene'",
                               selectizeInput(inputId = 'findMarkersSignatureSelect',
                                              label = 'Select signature/numeric variables:',
                                              choices = "-",
                                              selected = "-",
                                              multiple = TRUE)
                            ),


                              tags$h5("can select multiple genes/signatures"),
                               selectInput("findMarkersReductionType", "Plot reduction:",
                                            c("reduction" = 'umap')),
                              selectInput("findMarkersFuncType", "Visualization function:",
                                           choices = c("FeatuePlot",'Nebulosa'), selected = 'FeaturePlot',
                               ),
                              tags$h5("Nebulosa may incorrectly show inverted density, especially for gene sets. May try wkde method."),
                              checkboxInput("wkde", label = "Use wkde for Nebulosa?", value = FALSE),
                              tags$hr(),
                               checkboxInput("findMarkersLabels", label = "Show cluster labels?", value = FALSE),
                               conditionalPanel(
                                 condition = "!input.findMarkersRandom",
                                 checkboxInput("findMarkersOrder", label = "Prioritize expressing cells?", value = FALSE)
                               ),
                               conditionalPanel(
                                 condition = "!input.findMarkersOrder",
                                 checkboxInput("findMarkersRandom", label = "Randomize cell order?", value = TRUE)
                               ),

                                 checkboxInput("featureSplitByFlag", label= "Split by an identity?", value = FALSE, width = NULL),
                      selectInput("featureSplitBy", "Split by:", c("Cluster" = "orig.ident"), selected = NULL),

                     actionButton(inputId = "findMarkersFPConfirm", label = "Display plot", class = "btn btn-warning"),
                     tags$br(),


                 numericInput("findMarkersDotSize", "Dot size:", min = 0.01, max = 10, value = 1, step = 0.01),

                conditionalPanel(
                  condition = "input.findMarkersFuncType == 'FeatuePlot'",
                  selectInput("featureColor", "FeaturePlot color scheme:",
                                           choices = c("default", "Zissou1", "Blues", "Reds", "Greens","YlOrRd", "YrOrBr","YlGnBu","RdPu",
                                            "PuRd", "viridis", "magma", "cividis", "inferno", "plasma"),
                                           selected = 'default',)
                ),

                conditionalPanel(
                  condition = "input.findMarkersFuncType == 'Nebulosa'",
                  selectInput("findMarkersColor", "Nebulosa color scheme:",
                                           choices = c("viridis", "magma", "cividis", "inferno", "plasma"),
                                           selected = 'viridis',)
                ),
               sliderInput("findMarkersMaxCutoff", "Set max expression value: (quantile)", min = 0, max = 100, value = 100, step = 1),
              sliderInput("findMarkersMinCutoff", "Set minimum expression value: (quantile)", min = 0, max = 99, value = 0, step = 1),
                                                          tags$hr(),
                 numericInput("findMarkersWidth", "Plot width:", min = 200, max = 1200, value = 600, step = 10),
                 numericInput("findMarkersHeight", "Plot height:", min = 200, max = 2400, value = 550, step = 10),
                            checkboxInput("findMarkersreverseX", label = "Reverse X axis?", value = FALSE),
                               checkboxInput("findMarkersreverseY", label = "Revese Y axis?", value = FALSE),


                               tags$hr(),
                               tags$h3("Add a new signature"),
                               textInput(inputId = "findMarkersSignatureName", label = "Gene signature name :", value = "Signature1"),
                               textAreaInput(inputId = "findMarkersSignatureMembers", label = "Paste a list of genes", cols = 80, rows = 5, placeholder = "Prg4\nTspan15\nCol22a1\nHtra4"),
                               actionButton(inputId = "findMarkersSignatureAdd", label = "Calculate signature score", class = "btn btn-info")
                           ),
                           column(width = 9, status = "info", solidHeader = TRUE, title = "Plot",
                               div(class="ldBar", id="DEA4_loader", "data-preset"="circle"),
                                   downloadButton(outputId = "featuredownloader",label = "download pdf"),
                                   downloadButton(outputId = "featuredownloaderPNG",label = "download png"),
                               div(id="findMarkersFeaturePlot_loader",
                                   shinycssloaders::withSpinner(
                                     plotOutput(outputId = "findMarkersFeaturePlot", height = "1000px") # 1300
                                   )
                               )

                           )
                         )),
        tabPanel("Multi-feature vizualization", fluidRow(
                           box(width=3, status="info", solidHeader=T, title="Options",
                               selectizeInput(inputId = 'findMarkersFeaturePair1',
                                              label = 'Select 1st feature:',
                                              choices = NULL,
                                              selected = NULL,
                                              multiple = FALSE),
                               selectizeInput(inputId = 'findMarkersFeaturePair2',
                                              label = 'Select 2nd Feature:',
                                              choices = NULL,
                                              selected = NULL,
                                              multiple = FALSE),
                               sliderInput("findMarkersBlendThreshold", "Select threshold for blending:", min = 0, max = 1, value = 0.5, step = 0.1),
                               selectInput("findMarkersFeaturePairReductionType", "Plot type:",
                                           c("-" = "-")
                               ),
                               radioButtons("findMarkersFeaturePairLabels", label = "Show cluster labels: ",
                                            choices = list("Yes" = TRUE,
                                                           "No" = FALSE)
                               ),
                               radioButtons("findMarkersFeaturePairOrder", label = "Prioritize expressing cells: ",
                                            choices = list("Yes" = TRUE,
                                                           "No" = FALSE)
                               ),
                               sliderInput("findMarkersFeaturePairMaxCutoff", "Set max expression value: (quantile)", min = 0, max = 99, value = 99, step = 1),
                               sliderInput("findMarkersFeaturePairMinCutoff", "Set minimum expression value: (quantile)", min = 0, max = 99, value = 0, step = 1),
                               actionButton(inputId = "findMarkersFeaturePairConfirm", label = "Display plot"),
                                                                                         tags$hr(),
               #  numericInput("MultifindMarkersWidth", "Plot width:", min = 200, max = 1200, value = 600, step = 10),
               #  numericInput("MultifindMarkersHeight", "Plot height:", min = 200, max = 2400, value = 550, step = 10),
                            checkboxInput("MultifindMarkersreverseX", label = "Reverse X axis?", value = FALSE),
                               checkboxInput("MultifindMarkersreverseY", label = "Revese Y axis?", value = FALSE),
                           ),
                           column(width=9, status="info", solidHeader=TRUE, title="Plot",
                               div(class="ldBar", id="DEA5_loader", "data-preset"="circle"),
                               div(
                                 column(
                                   div(id="findMarkersFPfeature1_loader",
                                       shinycssloaders::withSpinner(
                                         plotlyOutput(outputId="findMarkersFPfeature1", height = "500px") #650px
                                       )
                                   ), width = 6),
                                 column(
                                   div(id="findMarkersFPfeature2_loader",
                                       shinycssloaders::withSpinner(
                                         plotlyOutput(outputId="findMarkersFPfeature2", height = "500px")
                                       )
                                   ), width = 6),
                                 column(
                                   div(id="findMarkersFPfeature1_2_loader",
                                       shinycssloaders::withSpinner(
                                         plotlyOutput(outputId="findMarkersFPfeature1_2", height = "500px")
                                       )
                                   ), width = 6),
                                 column(
                                   div(id="findMarkersFPcolorbox_loader",
                                       shinycssloaders::withSpinner(
                                         plotlyOutput(outputId="findMarkersFPcolorbox", height = "500px")
                                       )
                                   ), width = 6),
                               )
                           )
                         )
                         ),
                         tabPanel("Violin plot", fluidRow(
                           box(width = 3, status = "info", solidHeader = TRUE, title = "Options",
                               radioButtons("findMarkersViolinFeaturesSignature", label = "Select between gene or signature: ",
                                            choices = list("Gene" = "gene",
                                                           "Gene signature" = "signature"
                                            ),
                                            selected = "gene"),

                              conditionalPanel(
                                condition = "input.findMarkersViolinFeaturesSignature == 'gene'",
                               selectizeInput(inputId = 'findMarkersGeneSelect2',
                                              label = 'Select genes:',
                                              choices = NULL,
                                              selected = NULL,
                                              multiple = TRUE), # allow for multiple inputs

                           radioButtons("vlnSlot", label = "Slot to visualize:",
                                            choices = list("Normalized data (default)" = "data",
                                                        "Raw counts" = "counts",
                                                        "Scaled data" = "scale.data"
                                            ),
                                            selected = "data")
                              ),


                              conditionalPanel(
                                condition = "input.findMarkersViolinFeaturesSignature != 'gene'",
                               selectizeInput(inputId = 'findMarkersViolinSignatureSelect',
                                              label = 'Select signature/numeric variables:',
                                              choices = "-",
                                              selected = "-",
                                              multiple = TRUE)
                               ),


                 selectInput("vlnGroupBy", "Group by:",
                             c("Cluster" = "seurat_clusters")),

                checkboxInput("vlnSplitByFlag", label= "Split by another identity?", value = FALSE, width = NULL),
                conditionalPanel(
                  condition = "input.vlnSplitByFlag == true",
                  selectInput("vlnSplitBy", "Split by:",
                              c("Cluster" = "seurat_clusters"))
                ),
                
                tags$hr(),
                tags$h4("Statistical comparison options:"),
                checkboxInput("vlnAddStatTest", label= "Add statistical test?", value = FALSE, width = NULL),
                conditionalPanel(
                  condition = "input.vlnAddStatTest == true",
                  tags$div(style = "margin-left: 20px;",
                    tags$p("※ Statistical comparison displays only the first gene", style = "color: #666; font-size: 0.9em; margin-bottom: 10px;"),
                    selectInput("vlnStatMethod", "Statistical test method:",
                              choices = list(
                                "Wilcoxon/Kruskal-Wallis" = "wilcoxon",
                                "ZIQRank (2 groups only)" = "ziqrank"
                              ),
                              selected = "wilcoxon"),
                    conditionalPanel(
                      condition = "input.vlnStatMethod == 'wilcoxon'",
                      tags$div(style = "margin-top: 5px; color: #666; font-size: 0.9em;",
                        "2 groups: Wilcoxon rank-sum test (Mann-Whitney U test) | 3+ groups: Kruskal-Wallis test followed by pairwise Wilcoxon tests"
                      )
                    ),
                    selectInput("vlnPvalueLabel", "P-value display format:",
                              choices = list(
                                "P value (numeric)" = "p",
                                "Significance levels (ns, *, **, ***)" = "p.signif"
                              ),
                              selected = "p"),
                    checkboxInput("vlnUseFDR", label= "Apply FDR correction for multiple testing?", value = TRUE, width = NULL),
                    checkboxInput("vlnHideNS", label= "Hide non-significant comparisons?", value = FALSE, width = NULL)
                  )
                ),
                
                tags$hr(),
                tags$h4("Visualization options:"),
                selectInput("vlnColorPalette", "Color palette:",
                            c( "Set1", "Set2", "Set3",  "Paired", "Dark2", "Accent", "Spectral",
                                       'stallion','stallion2','calm','kelly','bear','ironMan','circus','paired',
                                       'grove','summerNight','zissou','Zissou1Continuous','darjeeling','rushmore','captain'), selected = 'Set1'),
                tags$div(style = "display: flex; align-items: center;",
                  checkboxInput("addnoise", label= "Add small noise?", value = FALSE, width = NULL),
                  tags$span(
                    icon("question-circle", style = "margin-left: 5px; color: #3c8dbc; cursor: pointer;"),
                    title = "発現値にランダムなノイズを追加します。同じ発現値を持つ細胞が重なって見えにくい場合に有効です。ノイズは最大発現値の1%程度の小さな値です。stacked violin plotでdata pointを表示する場合には適応されません。",
                    `data-toggle` = "tooltip",
                    `data-placement` = "right"
                  )
                ),
                checkboxInput("vlnShowDataPoint", label= "Show data point?", value = FALSE, width = NULL),
                conditionalPanel(
                  condition = "input.vlnShowDataPoint == true",
                  tags$div(style = "margin-left: 20px;",
                    sliderInput(inputId = "findMarkersViolinPtSize", label = "Data point size:", min = 0, max = 1, value = 0, step = 0.1),
                    sliderInput("vlnDotOpacity", "Point opacity:", min = 0, max = 1, value = 1, step = 0.05),
                    sliderInput("vlnJitterWidth", "Jitter width:", min = 0, max = 1, value = 0.3, step = 0.1)
                  )
                ),
                numericInput("vlnWidth", "Plot width:", min = 200, max = 1200, value = 800, step = 20),
                numericInput("vlnHeight", "Plot height:", min = 200, max = 3000, value = 600, step = 50),
                tags$h5("Downloaded fig size: value/72 inches"),
                sliderInput("vlnFontScale", "Font size scale:", min = 0.1, max = 3, value = 1, step = 0.1),
                checkboxInput("vlnClean", label= "Remove all ticks and legends?", value = FALSE, width = NULL),
                               actionButton(inputId = "findMarkersViolinConfirm", label = "Display violin plot", class = "btn btn-info" ),
                conditionalPanel(
                  condition = "input.vlnAddStatTest == false",
                  tags$h4("OR"),
                  actionButton(inputId = "vlnStackedConfirm", label = "Display stacked violin plot",class = "btn btn-info" ),
                  tags$br(),tags$br(),
                  textAreaInput(inputId = "vlnStackedGenes", label = "You can also list the genes for stacked violin plot here", cols = 80, rows = 5, placeholder = "Prg4\nTspan15\nCol22a1\nHtra4")
                ),

                           ),
                           column(width = 9, status = "info", solidHeader = TRUE, title = "Plot",
                               div(class="ldBar", id="DEA6_loader", "data-preset"="circle"),
                               downloadButton(outputId = "vlndownloaderPNG",label = "download png"),
                               downloadButton(outputId = "vlndownloaderPDF",label = "download pdf"),
                               div(id="findMarkersViolinPlot_loader",
                                   shinycssloaders::withSpinner(
                                plotOutput(outputId = "findMarkersViolinPlot", height = '800px')
                                    # plotlyOutput(outputId = "findMarkersViolinPlot")
                                   )
                               ),
                               # Summary statistics table (shown when Add statistical test is enabled)
                               conditionalPanel(
                                 condition = "input.vlnAddStatTest == true",
                                 tags$hr(),
                                 DT::dataTableOutput(outputId = "vlnSummaryTable"),
                                 tags$br(),
                                 tags$h4("Summary Statistics"),
                                 downloadButton(outputId = "vlnSummaryDownload", label = "Download TSV")
                               )

                           )
                         )
                         ),

                         # Heatmap tab
                         tabPanel("Heatmap", fluidRow(
                           box(width = 3, status = "info", solidHeader = TRUE, title = "Gene selection options",
                               radioButtons("heatmapGeneSource", label = "Gene source:",
                                           choices = list("Select/Input genes" = "manual",
                                                         "Top HVGs" = "hvg"),
                                           selected = "manual"),

                               conditionalPanel(
                                 condition = "input.heatmapGeneSource == 'manual'",
                                 selectizeInput(inputId = 'heatmapGeneSelect',
                                               label = 'Select genes:',
                                               choices = NULL,
                                               selected = NULL,
                                               multiple = TRUE),
                                 tags$h5("can select multiple genes"),
                                 tags$h4("OR"),
                                 textAreaInput(inputId = "heatmapGeneList",
                                              label = "Paste a list of genes",
                                              cols = 80, rows = 5,
                                              placeholder = "Cd79a\nMs4a1\nCd3d\nCd3e\nNkg7\nGzmb")
                               ),

                               conditionalPanel(
                                 condition = "input.heatmapGeneSource == 'hvg'",
                                 numericInput(inputId = "heatmapHVGNum",
                                             label = "Number of top HVGs:",
                                             min = 1, max = 500, value = 50, step = 1),
                                 tags$h5("Select top N highly variable genes.")
                               ),

                               tags$hr(),
                               tags$h4("Clustering options:"),
                               checkboxInput("heatmapClusterRows", label = "Cluster genes (rows)?", value = FALSE),
                               checkboxInput("heatmapClusterCols", label = "Cluster cells (columns)?", value = FALSE),

                               tags$hr(),
                               tags$h4("Heatmap options:"),
                               checkboxInput("heatmapDownsample", label = "Downsample cells?", value = FALSE),
                               conditionalPanel(
                                 condition = "input.heatmapDownsample",
                                 numericInput("heatmapDownNum", "Number of cells to sample:",
                                             min = 10, max = 10000, value = 500, step = 10)
                               ),

                               selectInput("heatmapGroupBy", "Group by:",
                                          c("Cluster" = "seurat_clusters")),

                               selectInput("heatmapColorPalette2", "Cluster color palette:",
                                          choices = c("Set1", "Set2", "Set3", "Paired"),
                                          selected = "Set3"),

                               selectInput("heatmapSlot", label = "Data slot:",
                                          choices = list("Scaled data" = "scale.data",
                                                       "Normalized data" = "data"),
                                          selected = "scale.data"),

                               tags$hr(),
                               tags$h4("Plot dimensions:"),
                               numericInput("heatmapWidth2", "Plot width:", min = 200, max = 2400, value = 800, step = 10),
                               numericInput("heatmapHeight2", "Plot height:", min = 200, max = 2400, value = 800, step = 10),

                               actionButton(inputId = "heatmapConfirm", label = "Generate heatmap",
                                          class = "btn btn-warning")
                           ),

                           box(width = 9, status = "info", solidHeader = TRUE, title = "Heatmap",
                              downloadButton(outputId = "featureHeatmapDownloadPNG", label = "download png"),
                              downloadButton(outputId = "featureHeatmapDownloadPDF", label = "download pdf"),
                              plotOutput(outputId = "featureHeatmap")
                           )
                         )
                         )
                                     )
                                   )
                                  ),

                          tabPanel("scATAC-seq",
                                    fluidRow(
                                      box(width = 3, status = "info", solidHeader = TRUE, title = "Options",
                                          selectizeInput(inputId = 'findMarkersGeneSelectATAC',
                                                         label = 'Select a gene:',
                                                         choices = NULL,
                                                         selected = NULL,
                                                         multiple = FALSE),
                                          selectInput("findMarkersReductionTypeATAC", "Plot type:",
                                                      c("UMAP" = "umap",
                                                        "tSNE" = "tsne")
                                          ),
                                          actionButton(inputId = "findMarkersFPConfirmATAC", label = "Display plot"),
                                      ),
                                      box(width = 9, status = "info", solidHeader = TRUE, title = "Plot",
                                          div(class="ldBar", id="DEA10_loader", "data-preset"="circle"),
                                          div(id="findMarkersFeaturePlotATAC_loader",
                                              shinycssloaders::withSpinner(
                                                plotOutput(outputId = "findMarkersFeaturePlotATAC", height = "1100px")
                                              )
                                          )
                                      )
                                    )
                                  )
                          )
      ),


      #DEA tab ===RNA
      tabItem(tabName = "findMarkers",
              tabsetPanel(type = "tabs", id = "findMarkersTabPanel",
                          tabPanel("scRNA-seq",
                                   fluidRow(
                                     box(width = 3, status = "info", solidHeader = TRUE,
                                         title = "Differential Expression Analysis options",
                                         selectInput("findMarkersTest", "Test used:",
                                                     c("Wilcoxon rank sum test" = "wilcox",
                                                     	"MAST" = "MAST",
                                                     	"Pseudoreplicate-edgeR" = 'edger',
                                                       "Likelihood-ratio test for single cell feature expression" = "bimod",
                                                       "Standard AUC classifier" = "roc",
                                                       "Student's t-test" = "t",
                                                       "DESeq2" = "DESeq2",
                                                       "Pseudoreplicate-DESeq2" = 'deseq',
                                                       "Pseudoreplicate-limma" = 'limma'
                                                     )),
                                         radioButtons("findMarkersLogBase", label = "Base used for average logFC calculation: ",
                                                      choices = list("log(e)" = "avg_logFC",
                                                                     "log(2)" = "avg_log2FC"
                                                      ),
                                                      selected = "avg_log2FC"),

                                       selectInput("MASTRegressColumns2", "Select latent variables to include for model in MAST, Logistic regression, Negative binomial, or Poisson.", list(), selected = NULL, multiple = TRUE, selectize = TRUE, width = NULL, size = NULL),
                                       tags$h5("Add Cellular Detection Rate (CDR) to MAST model. You can calculate CDR on DEG ANALYSIS."),

                                         sliderInput(inputId = "findMarkersMinPct", label = "Minimum % of expression", min = 0, max = 1, value = 0.25, step = 0.05)%>%
                                           shinyInput_label_embed(
                                             shiny_iconlink() %>%
                                               bs_embed_popover(
                                                 title = "Only test genes that are detected in a minimum fraction of cells in either of the two populations:", placement = "bottom"
                                               )
                                           ),
                                           tags$h5("For pseudoreplicates, this is the rate relative to the maximum rate among the clusters."),

                                         sliderInput(inputId = "findMarkersLogFC", label = "Avg Log FC threshold", min = 0, max = 3, value = 0.25, step = 0.05)%>%
                                           shinyInput_label_embed(
                                             shiny_iconlink() %>%
                                               bs_embed_popover(
                                                 title = "Limit testing to genes which show, on average, at least X-fold difference (log-scale) between the two groups of cells:", placement = "bottom"
                                               )
                                           ),

                                         sliderInput(inputId = "findMarkersPval", label = "P-value threshold", min = 0, max = 1, value = 0.05, step = 0.01)%>%
                                           shinyInput_label_embed(
                                             shiny_iconlink() %>%
                                               bs_embed_popover(
                                                 title = "Only return markers that have a p-value < slected threshold, or a power > selected threshold (if the test is ROC) :", placement = "bottom"
                                               )
                                           ),
                                         actionButton(inputId = "findMarkersConfirm", label = "RUN",class = "btn btn-warning"),
                                         tags$br(),
                                         tags$hr(),
                                         sliderInput(inputId = "heatmapNum", label = "Number of top marker genes for plots",min = 10, max = 500, value = 20, step = 10),
                                          sliderInput(inputId = "downNum", label = "Number of cells to show in heatmap",min = 1000, max = 5000, value = 1500, step = 100),
                                           checkboxInput("staticdownsample", label= "Downsample for static heatmap?", value = FALSE, width = NULL),
                                         selectInput("heatmapColorPalette", "Color palette:",c( "Set1",
                                        "Set2", "Set3",  "Paired", "Dark2", "Accent","Spectral")),
                      sliderInput("hmWidth", "Plot width:", min = 200, max = 1200, value = 800, step = 50),
                      sliderInput("hmHeight", "Plot height:", min = 200, max = 1600, value = 600, step = 50),
                                     ),

                                     box(
                                       width = 9, status = "info", solidHeader = TRUE, title = "DEA results",
                                       tabsetPanel(type = "tabs",
                                           tabPanel("Marker genes",
                                                    div(class="ldBar", id="DEA1_loader", "data-preset"="circle"),
                                                    dataTableOutput(outputId="findMarkersTable"),
                                                    downloadButton(outputId = "findMarkersRNAExport", label = "Save table")),

                                           tabPanel("Interactive Heatmap",
                                                    div(class="ldBar", id="DEA2_loader", "data-preset"="circle"),
                                                    actionButton(inputId = "findMarkersTop10HeatmapConfirm", label = "Display t
                                                  op marker genes heatmap"),
                                                    tags$br(),
                                                    tags$hr(),
                                                    div(id="findMarkersHeatmap_loader",
                                                        shinycssloaders::withSpinner(
                                                          plotlyOutput(outputId = "findMarkersHeatmap", height = 1000)
                                                          )
                                                                            )
                                                    ),

                                               tabPanel("Static heatmap",
                                                    div(class="ldBar", id="DEA4_loader", "data-preset"="circle"),
                                                    actionButton(inputId = "findMarkersStatic0HeatmapConfirm", label = "Display static heatmap"),
                                                    tags$br(),
                                                    tags$hr(),
                                                    downloadButton(outputId = "heatmapdownloaderPNG",label = "download png"),
                                                    downloadButton(outputId = "heatmapdownloaderPDF",label = "download pdf"),
                                                        plotOutput(outputId = "staticHeatmap", height = 1000)
                                                    ),

                                                   tabPanel("Dotplot",
                                                            div(class="ldBar", id="DEA3_loader", "data-preset"="circle"),
                                                            actionButton(inputId = "findMarkersTop10DotplotConfirm", label = "Display top-10 marker genes dotplot"),
                                                            div(id="findMarkersDotplot_loader",
                                                                shinycssloaders::withSpinner(
                                                                  plotlyOutput(outputId = "findMarkersDotplot", height = "800px")
                                                                )
                                                            )
                                                   ),
                                                   tabPanel("VolcanoPlot", fluidRow(
                                                     box(width = 3, status = "info", solidHeader = TRUE, title = "Cluster selection",
                                                         selectInput("findMarkersClusterSelect", "Cluster:", choices=c("-"="-"), multiple = F, selectize = F),
                                                         actionButton(inputId = "findMarkersVolcanoConfirm", "Display volcano plot")
                                                         ),

                                                     box(width = 9, status = "info", solidHeader = TRUE, title = "Volcano plot",
                                                         div(class="ldBar", id="DEA7_loader", "data-preset"="circle"),
                                                         div(id="findMarkersVolcanoPlot_loader",
                                                             shinycssloaders::withSpinner(
                                                               plotlyOutput(outputId = "findMarkersVolcanoPlot", height = "800px")
                                                               )
                                                         )
                                                     )
                                                  )
                                                )
                                       )
                                     )
                                   )
                          ),
                          tabPanel("scATAC-seq",
                                   fluidRow(
                                     box(width = 3, status = "info", solidHeader = TRUE,
                                         title = "Marker genes/peaks detection options (scATAC-seq)",
                                         tags$h3("Marker genes"),
                                         tags$hr(),
                                         selectInput("findMarkersTestATAC", "Test used:",
                                                     c("Wilcoxon" = "wilcoxon",
                                                       "Binomial" = "binomial",
                                                       "T-test" = "ttest"
                                                     )),
                                         selectInput("findMarkersGroupByATAC", "Cells group by:",
                                                     c("Clusters" = "Clusters",
                                                       "Integration predicted clusters" = "predictedGroup_Co"
                                                     )),
                                         sliderInput(inputId = "findMarkersLogFCATAC", label = "Log2FC threshold:", min = 0, max = 3, value = 0.25, step = 0.01),

                                         sliderInput(inputId = "findMarkersFDRATAC", label = "FDR threshold:", min = 0, max = 1, value = 0.01, step = 0.01),
                                         actionButton(inputId = "findMarkersConfirmATAC", label = "OK"),

                                         tags$h3("Marker peaks"),
                                         tags$hr(),
                                         selectInput("findMarkersPeaksTestATAC", "Test used:",
                                                     c("Wilcoxon" = "wilcoxon",
                                                       "Binomial" = "binomial",
                                                       "T-test" = "ttest"
                                                     )),
                                         selectInput("findMarkersPeaksGroupByATAC", "Cells group by:",
                                                     c("Clusters" = "Clusters",
                                                       "Integration predicted clusters" = "predictedGroup_Co"
                                                     )),
                                         sliderInput(inputId = "findMarkersPeaksLogFCATAC", label = "Log2FC threshold:", min = 0, max = 3, value = 0.25, step = 0.01),

                                         sliderInput(inputId = "findMarkersPeaksFDRATAC", label = "FDR threshold:", min = 0, max = 1, value = 0.01, step = 0.01),
                                         fileInput(inputId = "findMarkersPeaksCustomPeaks", label = "Please upload a .bed file (If you are using the example dataset you can upload the peakset file (.bed) provided in Help > Examples)", accept = ".bed"),
                                         #--activation in local version--
                                         # textInput(inputId = "pathToMacs2", label = "Absolute path to MACS2")%>%
                                         #   shinyInput_label_embed(
                                         #     shiny_iconlink() %>%
                                         #       bs_embed_popover(
                                         #         title = "Absolute path to MACS2 installation folder:
                                         #         Windows OS: the path will be detected automatically.
                                         #         Linux OS: provide the path for the MACS2, e.g. /home/user/anaconda3/bin/macs2", placement = "left"
                                         #       )
                                         #   ),

                                         actionButton(inputId = "findMarkersPeaksConfirmATAC", label = "OK"),
                                     ),

                                     box(
                                       tabsetPanel(type = "tabs", id = "ATAC_markers_tabs",
                                                   tabPanel("Marker genes (ATAC)", fluidRow(
                                                     tabsetPanel(type = "tabs", id = "marker_genes_tab_id",
                                                                 tabPanel("Marker genes table",
                                                                          div(class="ldBar", id="DEA8_loader", "data-preset"="circle"),

                                                                          div(id="findMarkersGenesATACTable_loader",
                                                                              shinycssloaders::withSpinner(
                                                                          dataTableOutput(outputId="findMarkersGenesTableATAC")
                                                                            )
                                                                          ),
                                                                          downloadButton(outputId = "findMarkersGenesATACExport", label = "Save table"),
                                                                 ),
                                                                 tabPanel("Marker genes heatmap (top-10)",
                                                                          div(id="findMarkersGenesHeatmapATAC_loader",
                                                                              shinycssloaders::withSpinner(
                                                                                plotlyOutput(outputId = "findMarkersGenesHeatmapATAC", height = "700px")
                                                                              )
                                                                          )
                                                                 )
                                                     )
                                                    )
                                                   ),
                                                   tabPanel("Marker peaks (ATAC)", fluidRow(
                                                     tabsetPanel(type = "tabs", id = "marker_peaks_tab_id",
                                                       tabPanel("Marker peaks table",
                                                                div(class="ldBar", id="DEA9_loader", "data-preset"="circle"),

                                                                div(id="findMarkersPeaksATACTable_loader",
                                                                    shinycssloaders::withSpinner(
                                                                      dataTableOutput(outputId="findMarkersPeaksTableATAC"),
                                                                    )
                                                                ),
                                                                downloadButton(outputId = "findMarkersPeaksATACExport", label = "Save table")
                                                       ),
                                                       tabPanel("Marker peaks heatmap (top-10)",
                                                                div(id="findMarkersPeaksHeatmapATAC_loader",
                                                                    shinycssloaders::withSpinner(
                                                                      plotlyOutput(outputId = "findMarkersPeaksHeatmapATAC", height = "700px")
                                                                    )
                                                                )
                                                       )
                                                     )
                                                    )
                                                   )

                                       )
                                     )
                                   )
                          )
              )
      ),

      #DEG tab
      tabItem(tabName = "findDEG",
              tabsetPanel(type = "tabs", id = "findDEGTabPanel",
                                   fluidRow(
                                     title = "Differential Expression Analysis options",
box(width = 4, status = "info", solidHeader = TRUE,
    
    # ここにtabsetPanelを追加して2つのタブを作成
    tabsetPanel(
      # Single Sampleタブ
      tabPanel("Single Sample",
               selectInput(inputId = "DEGFirstCluster", label = "Cluster(s) to test:", choices = "-", multiple = T),
               selectInput(inputId = "DEGSecondCluster", label = "vs. cluster(s):", choices = "-", multiple = T),
               tags$h5("Can select multiple clusters. If the second clusters are not selected, the selected clusters will be tested against the remaining clusters."),
               
               selectInput("findMarkersTestDEG", "Test used:",
                           c("Wilcoxon rank sum test" = "wilcox",
                             "MAST" = "MAST",
                             "Pseudoreplicate-edgeR" = 'edger',
                             "Likelihood-ratio test for single cell feature expression" = "bimod",
                             "Standard AUC classifier" = "roc",
                             "Student's t-test" = "t",
                             "DESeq2" = "DESeq2",
                             "Pseudoreplicate-DESeq2" = 'deseq',
                             "Pseudoreplicate-limma" = 'limma'
                           )),
               tags$h5("You may want to add Cellular Detection Rate (CDR) for MAST model. Calculate CDR and add CDR to model in MAST."),
               actionButton(inputId = "calcCDR", label = "Calc CDR for MAST" ),
               tags$br(),tags$br(),
               selectInput("MASTRegressColumns", "Select latent variables to include for model in MAST, Logistic regression, Negative binomial, or Poisson.", list(), selected = NULL, multiple = TRUE, selectize = TRUE, width = NULL, size = NULL),
               checkboxInput("OnlyPos", label = "Only show upregulated genes?: ",value=FALSE),
               tags$h5("Options below do not affect pseudoreplicate analysis."),
               
               numericInput(inputId = "findMarkersMinPctDEG", label = "Minimum fraction of cells expressing genes (min.pct)", min = 0, max = 1, value = 0.1, step = 0.01)%>%
                 shinyInput_label_embed(
                   shiny_iconlink() %>%
                     bs_embed_popover(
                       title = "Only test genes that are detected in a minimum fraction of cells in either of the two populations:", placement = "bottom"
                     )
                 ),
               numericInput(inputId = "findMarkersLogFCDEG", label = "Avg Log FC threshold (LFC)", min = 0, max = 2, value = 0.25, step = 0.05)%>%
                 shinyInput_label_embed(
                   shiny_iconlink() %>%
                     bs_embed_popover(title = "Limit testing to genes which show, on average, at least X-fold difference (log-scale) between the two groups of cells:", placement = "bottom"
                     )
                 ),
               radioButtons("findMarkersLogBaseDEG", label = "Base used for average logFC calculation: ",
                            choices = list("log(2)" = "avg_log2FC","log(e)" = "avg_logFC"
                            ),
                            selected = "avg_log2FC"),
               actionButton(inputId = "findMarkersConfirmDEG", label = "Run DEG analysis",class = "btn btn-warning"),
               tags$hr(),
               
               tags$h3("Generate ranking file for GSEA"),
               tags$h4("Should set Avg Log FC threshold <= 0.1 and may also lower Minimum % of expression."),
               
               tags$hr(),
               radioButtons("Rnkmetric", label = "Ranking metric :",
                            choices = list("sign(LFC) x -log10(P)" = "Default",
                                          "LFC x -log10(P)" = "Multi"),   selected = "Default"),
               radioButtons("GSEAoutput", label = "Sign for up/down :",
                            choices = list("Homer (A vs B : B as compared with A)" = "Homer",
                                          "As shown in the result tab (A vs B : A as compared with B" = "Rev"),   selected = "Rev"),
               
               downloadButton(outputId = "confirmRnkFile", label = "Download rnk file")
      ),
      
      # Multiple Samplesタブ
      tabPanel("Multiple Samples",
               # NEBULA/glmmTMB分析セクション
               tags$h3("NEBULA/glmmTMB for n>2 samples"),
               tags$hr(),
               selectInput("DEMethod", "Select DE method:", 
                           choices = list("NEBULA-HL" = "NEBULA-HL", 
                                         "NEBULA-LN" = "NEBULA-LN", 
                                         "glmmTMB" = "glmmTMB"),
                           selected = "NEBULA-HL"),
               tags$h5("NEBULAは30サンプル以上を推奨"),
               tags$h5("glmmTMB is exremely slow!"),
               checkboxInput("useREML", "Use REML estimation (recommended for small samples)", value = TRUE),
              tags$h5("REMLはサンプルサイズが小さい場合に推奨"),
               selectInput("NEBULARandom", "Select sample ID (e.g., orig.ident)", 
                           list(), selected = 'orig.ident', multiple = FALSE),
               tags$h5("サンプル情報の入っているidentityを選択"),
               tags$hr(),
               selectInput(inputId = "NEBULAFirstCluster", label = "Control group:", choices = "-", multiple = T),
               selectInput(inputId = "NEBULASecondCluster", label = "vs. Test group:", choices = "-", multiple = T),
              numericInput(inputId = "NEBULAMinPctDEG", label = "Minimum fraction of cells expressing genes (min.pct)", min = 0, max = 1, value = 0.1, step = 0.01)%>%
                 shinyInput_label_embed(
                   shiny_iconlink() %>%
                     bs_embed_popover(
                       title = "Only test genes that are detected in a minimum fraction of cells in either of the two populations:", placement = "bottom"
                     )
                 ),
               selectInput("NEBULARegressColumns", "Covariates:", list(), 
                           selected = NULL, multiple = TRUE, selectize = TRUE, width = NULL, size = NULL),
               tags$h5("細胞検出率(CDR)やバッチ効果などの変数を選択"),
               numericInput(inputId = "NEBULALogFCDEG", 
                            label = "Avg Log FC threshold (LFC)", 
                            min = 0, max = 2, value = 0.25, step = 0.05),
               tags$h5("DOI: 10.1186/s13059-022-02605-1, 10.1186/s42003-021-02146-6"),
               actionButton(inputId = "findNEBULADEG", 
                            label = "Run NEBULA/glmmTMB analysis", 
                            class = "btn btn-warning"),
               tags$br(),
               tags$hr(),
               
               # MASTランダム効果分析セクション
               tags$h3("MAST with a random effect for n>2 samples"),
               selectInput("MASTRandom", "Select identity used as random variable (e.g., orig.ident)", list(), selected = 'orig.ident', multiple = FALSE),
               tags$h5("サンプル情報の入っているidentityを選択"),
               selectInput(inputId = "MASTFirstCluster", label = "First group:", choices = "-", multiple = T),
               selectInput(inputId = "MASTSecondCluster", label = "vs. Second:", choices = "-", multiple = T),
               tags$h5("Cluster x 条件のidenityをまず作成してください → UTILITY IDENTITY $ ASSAY → AxB"),
               tags$h5("各グループに含まれる細胞を選択 例:1_WT1, 1_WT2 vs. 1_KO1, 1_KO2"),
               selectInput("MASTRandomRegressColumns", "Latent variables:", list(), selected = NULL, multiple = TRUE, selectize = TRUE, width = NULL, size = NULL),
               tags$h5("MASTではCDRを推奨"),
               tags$h5("DOI: 10.1038/s41467-021-21038-1"),
               actionButton(inputId = "findMarkersMASTRandom", label = "Run MAST with a random effect",class = "btn btn-warning")
      )
    )
), # box end


               box(
                 width = 8, status = "info", solidHeader = TRUE, title = "DEG results",
                 tabsetPanel(type = "tabs",
                             tabPanel("DEG",
                                      div(class="ldBar", id="DEA1_loaderDEG", "data-preset"="circle"),
                                      dataTableOutput(outputId="findMarkersTableDEG"),
                                      downloadButton(outputId = "findMarkersRNAExportDEG", label = "Save table")
                                      ),
                             tabPanel("Heatmap",
                                      div(class="ldBar", id="DEA2_loaderDEG", "data-preset"="circle"),
                                      actionButton(inputId = "findMarkersTop10HeatmapConfirmDEG", label = "Display top-50 marker genes heatmap"),
                                      div(id="findMarkersHeatmap_loaderDEG",
                                         # shinycssloaders::withSpinner(
                                            plotlyOutput(outputId = "findMarkersHeatmapDEG", height = "1300px")
                                         #   )
                                          )
                                      ),

                             tabPanel("Dotplot",
                                      div(class="ldBar", id="DEA3_loaderDEG", "data-preset"="circle"),
                                      actionButton(inputId = "findMarkersTop10DotplotConfirmDEG", label = "Display top-30 marker genes dotplot"),
                                      div(id="findMarkersDotplot_loaderDEG",
                                      #    shinycssloaders::withSpinner(
                                            plotlyOutput(outputId = "findMarkersDotplotDEG", height = "1000px")
                                      #    )
                                      )
                             ),
                           # tabPanel("Violinplot",
                           #           div(class="ldBar", id="DEA6_loaderDEG", "data-preset"="circle"),
                           #           actionButton(inputId = "findMarkersViolinConfirmDEG", label = "Display top-20 DEG"),
                           #           div(id="findMarkersViolinPlot_loaderDEG",
                           #              shinycssloaders::withSpinner(
                           #                 #plotlyOutput(outputId = "findMarkersViolinplotDEG", height = "1300px")
                           #                 plotlyOutput(outputId = "findMarkersViolinplotDEG")

                                       #   )
                                 #     )
                            # ),
                             tabPanel("VolcanoPlot",
                                   div(class="ldBar", id="DEA6_loaderDEG", "data-preset"="circle"),
                                   actionButton(inputId = "findMarkersVolcanoConfirmDEG", "Display volcano plot"),
                                   div(class="ldBar", id="DEA7_loaderDEG", "data-preset"="circle"),
                                   div(id="findMarkersVolcanoPlot_loaderDEG",
                                    #   shinycssloaders::withSpinner(
                                         plotlyOutput(outputId = "findMarkersVolcanoPlotDEG", height = "800px")
                                    #     )
                                   )
                               )

                 )
               ) # end of box
             )


              )
      ),


      #Pseudobulk tab
      tabItem(tabName = "pseudobulk",
              tabsetPanel(type = "tabs", id = "pseudobulkTabPanel",
           fluidRow(
             title = "Pseudobulk Analysis",
             box(width = 3, status = "info", solidHeader = TRUE,

              tags$h3("Generate pseudobulk data"),

                selectInput("bulkSample", "Select identity for sample ID (e.g., ctrl_1, ctrl_2, stim_1, stim_2)", list(), selected = 'orig.ident', multiple = FALSE),
                selectInput("bulkCluster", "Select identity for clusters (e.g., seurat_clusters", list(), selected = 'seurat_clusters', multiple = FALSE),
                tags$h4("For test"),
                selectInput("bulkCondition", "Select identity for condition (e.g., group IDs (ctrl/stim))", list(), selected = NULL, multiple = FALSE),
                                tags$h5("When only generating psedubulk data, need not to change."),
           actionButton(inputId = "generateBulk", label = "Generate pseudobulk data", class = "btn btn-warning"),
           tags$br(),
            tags$h5("MDS plot is displayed on the Pesudobulk tab"),
          downloadButton(outputId = "downloadBulk", label = "Download pseudobulk file"),

           tags$br(),
                tags$hr(),
         tags$h3("Set conditions for test"),
        selectInput("bulkTestIdent", "Select conditon for test", list(), multiple = FALSE),
                                                tags$h5("vs."),
          selectInput("bulkTestControl", "Select conditon for control", list(), multiple = FALSE),


          selectInput("bulkTest", label = "Test method :",
                              choices = list("edgeR" = "edgeR", "DESeq2" = "DESeq2", "limma-trend" = "limma-trend",
                               "limma-voom" = "limma-voom"),   selected = "edgeR"),


          actionButton(inputId = "RunBulkTest", label = "Run bulk test by MUSCAT", class = "btn btn-warning"),
                tags$hr(),
             tags$h3("Mixed model test"),
             tags$h5("1. linear mixed models (LMMs) on log-normalized data\n2. LMMs on variance-stabilized data\n3. generalized linear mixed models (GLMMs) directly on counts"),

          selectInput("mixedTest", label = "Test method :",
                              choices = list("LMM on log-normalized data" = "1", "LMM on variance-stabilized data" = "2", "GLMM" = "3"),   selected = "1"),

        actionButton(inputId = "RunMixedTest", label = "Run mixed model test by MUSCAT", class = "btn btn-warning"),
        downloadButton(outputId = "muscatDown", label = "Download mixed model results")



             ), # box end


             box(
               width = 9, status = "info", solidHeader = TRUE, title = "Pseudobulk results",
               tabsetPanel(type = "tabs",
                         tabPanel("Pseudobulk",
                                    verbatimTextOutput(outputId = "bulkcellnum"),
                                   plotlyOutput('pb_mds', height = "600px"),
                                   selectInput("MUSCATtable", "Select cluster to show", list(), multiple = FALSE),
                                   actionButton(inputId = "showMUSCATout", "Display table"),
                                   dataTableOutput(outputId="MUSCATout"),
                                   downloadButton(outputId = "export_MUSCAT", label = "Save table")
                           )

               )
             ) # end of box
           )


              )
      ),


      #Doublets' detection
      tabItem(tabName = "doubletDetection",
              tabsetPanel(type = "tabs", id = "doubletDetectionTabPanel",
                          tabPanel("scRNA-seq",
                                   fluidRow(
                                     box(
                                       width = 4, status = "info", solidHeader = TRUE,
                                       title = "DoubletFinder parameters",
                                       sliderInput(inputId = "doubletsPN", label = "Artificial doublet's rate :", min = 0.01, max = 1, value = 0.25, step = 0.01),
                                       sliderInput(inputId = "doubletsPCs", label = "Number of principal components to use :", min = 1, max = 50, value = 30, step = 1),
                                       radioButtons("doubletsPKRadio", label = "PC neighborhood size estimation: ",
                                                    choices = list("Automatic" = "auto",
                                                                   "Manual" = "manual"
                                                    ),
                                                    selected = "auto"),
                                       sliderInput(inputId = "doubletsPK", label = "PC neighborhood size (used only when manual is selected):", min = 0, max = 1, value = 0.09, step = 0.01),
                                       sliderInput(inputId = "doubletsNExp", label = "Percentage of doubles expected :", min = 0.01, max = 1, value = 0.07, step = 0.01),
                                       actionButton(inputId = "doubletsConfirm", label = "Perform doublets' detection",class = "btn btn-warning"),
                                     ),
                                     box(
                                       width = 8, status = "info", solidHeader = TRUE, title = "Doublet detection output",
                                       div(class="ldBar", id="doubletRNA_loader1", "data-preset"="circle"),
                                       column(verbatimTextOutput(outputId = "doubletsInfo"), width = 6),
                                       column(
                                         width = 6,
                                         tags$div(style = "margin-top: 10px;",
                                           tags$h5(tags$b("Doublet types:")),
                                           tags$p(tags$b("Homotypic doublets:"), "Two cells from the same cluster/cell type. Difficult to detect due to similar gene expression patterns."),
                                           tags$p(tags$b("Non-homotypic doublets:"), "Two cells from different clusters/cell types. Easier to detect due to mixed gene expression patterns."),
                                           tags$p(style = "color: #3c8dbc;", tags$b("Note:"), "DoubletFinder primarily targets non-homotypic doublets for more reliable detection."),
                                           tags$hr(),
                                           tags$h5(tags$b("推奨ワークフロー（DoubletFinder）:"), style = "color: #d9534f;"),
                                           tags$p("1. ", tags$b("まず基本的なQCを実施:"), "極端に低品質な細胞（超低UMI、超低遺伝子数など）やゴミを除去"),
                                           tags$p("2. ", tags$b("正規化とPCAを実施:"), "フィルタ後のオブジェクトでNormalization → PCA → DoubletFinder"),
                                           tags$p("3. ", tags$b("重要な注意点:"), style = "color: #d9534f;", "過剰に厳しいQCは避けてください。実際のdoublet構造まで削ってしまい、検出精度が低下します"),
                                           tags$p("4. ", tags$b("DoubletFinder実行後:"), "doubletスコアを参考に最終的なQC閾値を決定し、追加フィルタリング（ミトコンドリア高発現細胞など）を実施"),
                                           tags$p("5. ", tags$b("複数サンプルの場合:"), "Doubletは同じ物理キャプチャ内でのみ発生。別々のフローセル/ランでキャプチャした場合は、サンプルごとにオブジェクトを分けて個別に実行。ハッシュタグで混ぜた複数サンプル（同じcapture）は一括で実行可能")
                                         )
                                       )
                                       )
                                   ),
                                   fluidRow(
                                     tags$hr(style = "border-top: 2px solid #3c8dbc; margin-top: 20px; margin-bottom: 20px;"),
                                     tags$h4("scDblFinder", style = "color: #3c8dbc; margin-left: 15px;"),
                                     box(
                                       width = 4, status = "info", solidHeader = TRUE,
                                       title = "scDblFinder parameters",
                                       sliderInput(inputId = "scDblFinderDBR", label = "Expected doublet rate (0 = auto-estimation):", min = 0, max = 0.5, value = 0, step = 0.01),
                                       tags$p(style = "color: #666; font-size: 0.85em;", "0 = automatic estimation based on cell count (recommended). Typical 10X: ~0.8% per 1000 cells."),
                                       sliderInput(inputId = "scDblFinderDBRsd", label = "Doublet rate uncertainty (dbr.sd):", min = 0, max = 2, value = 0, step = 0.1),
                                       tags$p(style = "color: #666; font-size: 0.85em;", "0 = auto (40% of dbr). Set to 1 to ignore expected doublet count."),
                                       sliderInput(inputId = "scDblFinderNDims", label = "Number of dimensions to use :", min = 5, max = 50, value = 20, step = 1),
                                       numericInput(inputId = "scDblFinderNThreads", label = "Number of threads :", value = 4, min = 1, max = 8, step = 1),
                                       selectInput("scDblFinderReduction", "Select PCA/reduction to use:",
                                                   c("pca" = "pca"),
                                                   selected = "pca"),
                                       tags$p(style = "color: #666; font-size: 0.85em;", "Select the dimensionality reduction (e.g., RNA.pca, pca) to use for doublet detection."),
                                       tags$hr(),
                                       checkboxInput("scDblFinderUseClusters", "Use cluster information (improves accuracy for clear cluster structure)", FALSE),
                                       conditionalPanel(
                                         condition = "input.scDblFinderUseClusters == true",
                                         selectInput("scDblFinderClusterColumn", "Select cluster column:",
                                                     c("seurat_clusters" = "seurat_clusters"),
                                                     selected = "seurat_clusters"),
                                         tags$p(style = "color: #666; font-size: 0.9em;",
                                                "Providing cluster information can improve accuracy in datasets with clear cluster structure.")
                                       ),
                                       tags$hr(),
                                       checkboxInput("scDblFinderMultiSample", "Multiple samples (process each sample separately)", FALSE),
                                       conditionalPanel(
                                         condition = "input.scDblFinderMultiSample == true",
                                         selectInput("scDblFinderSampleColumn", "Select sample identity column:",
                                                     c("orig.ident" = "orig.ident"),
                                                     selected = "orig.ident"),
                                         tags$p(style = "color: #666; font-size: 0.9em;",
                                                "IMPORTANT: Doublets arise only within the same physical capture (flowcell/10x run). If multiple samples were mixed with hashtags in ONE capture, treat as a single sample (uncheck this option). Only split by sample if they were captured in SEPARATE flowcells/runs. In that case, use the batch/capture column here.")
                                       ),
                                       tags$hr(),
                                       actionButton(inputId = "scDblFinderConfirm", label = "Perform scDblFinder detection", class = "btn btn-warning"),
                                     ),
                                     box(
                                       width = 8, status = "info", solidHeader = TRUE, title = "scDblFinder output",
                                       div(class="ldBar", id="scDblFinder_loader1", "data-preset"="circle"),
                                       column(verbatimTextOutput(outputId = "scDblFinderInfo"), width = 6),
                                       column(
                                         width = 6,
                                         tags$div(style = "margin-top: 10px;",
                                           tags$h5(tags$b("scDblFinder features:")),
                                           tags$p(tags$b("Method:"), "Uses a fully simulation-based approach with random forest classifier."),
                                           tags$p(tags$b("Accuracy:"), "Generally more accurate than DoubletFinder, especially with lower doublet rates."),
                                           tags$p(tags$b("Recommended data:"), "Works best on data without empty drops but not yet heavily filtered. Ideal for early QC stages."),
                                           tags$p(style = "color: #3c8dbc;", tags$b("Note:"), "scDblFinder provides doublet scores and classifications, and handles cluster information automatically."),
                                           tags$hr(),
                                           tags$h5(tags$b("推奨ワークフロー（scDblFinder）:"), style = "color: #5bc0de;"),
                                           tags$p("1. ", tags$b("最小限のQCのみ実施:"), "empty dropletsと極端にゼロに近い細胞（明らかなゴミ）だけを除去"),
                                           tags$p("2. ", tags$b("「ほぼraw」データで実行:"), "正規化とPCAを済ませた", tags$b("軽くフィルタした"), "オブジェクトでscDblFinderを実行"),
                                           tags$p("3. ", tags$b("scDblFinder実行後:"), "doubletスコアを取得したら、通常のQCフィルタリング（ミトコンドリア高発現細胞、低品質細胞など）を実施"),
                                           tags$p("4. ", tags$b("DoubletFinderとの違い:"), style = "color: #5bc0de;", "scDblFinderは早期QC段階で実行。DoubletFinderはQC後の高品質データで実行"),
                                           tags$p("5. ", tags$b("サンプル分割について:"), "Doubletは同じ物理キャプチャ内（同じフローセル/10xラン）でのみ発生。ハッシュタグで混ぜた複数サンプルは1つのcaptureとして扱う（分割不要）。別々のフローセル/ランでキャプチャした場合のみ、バッチ/capture列で分割")
                                         )
                                       )
                                     )
                                   )
                          ),
                          tabPanel("scATAC-seq",
                                   fluidRow(
                                     box(
                                       width = 4, status = "info", solidHeader = TRUE,
                                       title = "Doublet detection options",
                                       sliderInput(inputId = "doubletsATACk", label = "The number of cells neighboring a simulated doublet to be considered as putative doublets :", min = 5, max = 100, value = 10, step = 1),
                                       radioButtons("doubletsATACLSI", label = "Order of operations in the TF-IDF normalization: ",
                                                    choices = list("tf-logidf" = "1",
                                                                   "log(tf-idf)" = "2",
                                                                   "logtf-logidf" = "3"
                                                    ),
                                                    selected = "1"),
                                       actionButton(inputId = "doubletsATACConfirm", label = "Perform doublets' detection"),
                                     ),
                                     box(
                                       width = 8, status = "info", solidHeader = TRUE, title = "Doublet detection output",
                                       div(class="ldBar", id="doubletATAC_loader2", "data-preset"="circle"),
                                       div(id="doubletATAC_loader3",
                                           shinycssloaders::withSpinner(
                                            plotOutput(outputId = "doubletsScoreATAC")
                                            ), width = 6
                                           ),
                                       div(id="doubletATAC_loader4",
                                           shinycssloaders::withSpinner(
                                            plotOutput(outputId = "doubletEnrichmentATAC")
                                           ), width = 6
                                       )
                                     ),
                                   )
                          )
              )
      ),

      #Cell cycle phase analysis
      tabItem(tabName = "cellCycle",
              fluidRow(
                box(
                  width = 12, status = "info", solidHeader = T,
                  title = "Cell cycle phase analysis",
                  tabsetPanel(type = "tabs",
                              tabPanel("Dimensionality reduction plot",
                                       selectInput("cellCycleReduction", "Plot type:",
                                                   c("-" = "-")
                                       ),
                                       actionButton(inputId = "cellCycleRun", label = "Run cell cycle analysis",class = "btn btn-warning"),
                                       div(class="ldBar", id="CC1_loader", "data-preset"="circle"),
                                       div(id="cellCyclePCA_loader",
                                           shinycssloaders::withSpinner(
                                             plotlyOutput(outputId = "cellCyclePCA", height = "700px")
                                           )
                                       )
                              ),
                              tabPanel("Barplot",
                                       div(class="ldBar", id="CC2_loader", "data-preset"="circle"),
                                       div(id="cellCycleBarplot_loader",
                                           shinycssloaders::withSpinner(
                                             plotlyOutput(outputId = "cellCycleBarplot", height = "1100px")
                                           )
                                       )
                              )
                  )
                )
              )
      ),

      #Enrichment analysis -gProfiler
      tabItem(tabName = "gProfiler",
              tabsetPanel(type = "tabs", id = "gProfilerTabPanel",
                          tabPanel("scRNA-seq",
                                   fluidRow(
                                     box(width = 2, status = "info", solidHeader = TRUE,
                                         title = "Enrichment analysis options",
                                         tags$h3("1. Options for input list"),
                                         tags$hr(),
                                         selectInput("gProfilerList", "Input list of genes:",
                                                     c("-" = "-")),
                                         radioButtons("gprofilerRadio", label = "Sigificance threshold : ",
                                                      choices = list("P-value" = "p_val",
                                                                     "Adjusted P-value" = "p_val_adj",
                                                                     "Power" = "power"
                                                      ),
                                                      selected = "p_val"),
                                         sliderInput("gProfilerSliderSignificance", "", min = 0, max = 1, value = 0.01, step = 0.01),
                                         radioButtons("gProfilerLFCRadio", label = "Direction of deregulation : ",
                                                      choices = list("Up-regulated" = "Up",
                                                                     "Down-regulated" = "Down"),
                                                      selected = "Up"
                                         ),
                                         sliderInput("gProfilerSliderLogFC", "Log FC threshold:", min = 0, max = 3, value = 0.25, step = 0.01),
                                         tags$h3("2. Options for enrichment analysis"),
                                         tags$hr(),
                                         selectInput("gProfilerDatasources", "Select datasources", list('Gene Ontology'=list("Gene Ontology-Molecular Function (GO:MF)"="GO:MF", "Gene Ontology-Cellular Component (GO:CC)"= "GO:CC", "Gene Ontology-Biological Process (GO:BP)"="GO:BP"),
                                             'Biological Pathways'= list("KEGG PATHWAY"="KEGG", "Reactome"="REAC", "WikiPathways"="WP"),
                                             'Regulatory motifs in DNA'= list("TRANSFAC"= "TF","miRTarBase"= "MIRNA"),
                                            'Protein Databases'=list("CORUM"= "CORUM", "Human Protein Atlas (HPA)"="HPA"),
                                            'Human Phenotype Ontology' =list("Human Phenotype Ontology"= "HP")),
                                                     selected = list("GO:MF", "GO:CC", "GO:BP", "KEGG"),
                                                     multiple = TRUE, selectize = TRUE, width = NULL, size = NULL),
                                         selectInput("gProfilerOrganism", "Select organism", choices=c("Homo sapiens (Human)"="human","Mus musculus (Mouse)"="mouse"), selected = NULL, multiple = FALSE,selectize = TRUE, width = NULL, size = NULL),
                                         radioButtons("gprofilerRadioCorrection", label = "Correction method for multiple testing : ",
                                                      choices = list("Analytical(g:SCS)" = "gSCS",
                                                                     "Benjamini-Hochberg false discovery rate" = "fdr",
                                                                     "Bonferroni correction" = "bonferroni"
                                                      ),
                                                      selected = "bonferroni"
                                         ),
                                         sliderInput("gProfilerSliderSignificanceTerms", "Significance for enriched terms :", min = 0, max = 1, value = 0.05, step = 0.01),
                                         actionButton(inputId = "gProfilerConfirm", label = "OK"),
                                         tags$h3("3. Multiple cluster enrichment analysis"),
                                         tags$hr(),
                                         selectizeInput(
                                           "gProfilerFlameSelection",
                                           label = "Select up to 10 clusters",
                                           choices = c("-"="-"),
                                           multiple = TRUE,
                                           options = list(maxItems = 10)
                                         ),
                                         actionButton(inputId = "sendToFlame", label = "Send to Flame")
                                     ),
                                     box(
                                       width = 10, status = "info", solidHeader = TRUE, title = "Enrichment analysis results",
                                       tabsetPanel(type = "tabs",
                                                   tabPanel("Table of functional terms",
                                                            div(class="ldBar", id="gprof1_loader", "data-preset"="circle"),
                                                            dataTableOutput(outputId = "gProfilerTable"),
                                                            downloadButton(outputId = "gProfilerRNAExport", label = "Save table")),
                                                   tabPanel("Manhattan plot",
                                                            div(class="ldBar", id="gprof2_loader", "data-preset"="circle"),
                                                            div(id="gProfilerManhattan_loader",
                                                                shinycssloaders::withSpinner(
                                                                  plotlyOutput(outputId = "gProfilerManhattan")
                                                                )
                                                            )
                                                   )
                                       )
                                     )
                                   )
                          ),
                          tabPanel("scATAC-seq",
                                   fluidRow(
                                     box(width = 3, status = "info", solidHeader = TRUE,
                                         title = "Motif enrichment analysis (scATAC-seq)",
                                         selectInput("findMotifsSetATAC", "Motif set:",
                                                     c("Cisb" = "cisbp",
                                                       "ENCODE" = "encode",
                                                       "Homer" = "homer",
                                                       "JASPAR 2016" = "JASPAR2016",
                                                       "JASPAR 2018" = "JASPAR2018",
                                                       "JASPAR 2020" = "JASPAR2020"
                                                     )),
                                         selectInput("findMotifsGroupByATAC", "Cells group by:",
                                                     c("Clusters" = "Clusters",
                                                       "Integration predicted clusters" = "predictedGroup_Co"
                                                     )),
                                         sliderInput(inputId = "findMotifsLogFCATAC", label = "Log2FC threshold:", min = 0, max = 3, value = 0.25, step = 0.01),
                                         sliderInput(inputId = "findMotifsFDRATAC", label = "FDR threshold:", min = 0, max = 1, value = 0.01, step = 0.01),
                                         actionButton(inputId = "findMotifsConfirmATAC", label = "OK"),
                                     ),

                                     box(width = 9, status = "info", solidHeader = TRUE, title = "Motif enrichment analysis results",
                                         tabsetPanel(type = "tabs",
                                                     tabPanel("Table of enriched motifs",
                                                                div(class="ldBar", id="motif_loader", "data-preset"="circle"),
                                                                div(id="findMotifsATACTable_loader",
                                                                  shinycssloaders::withSpinner(
                                                                    dataTableOutput(outputId="findMotifsTableATAC")
                                                                  )
                                                                ),
                                                                downloadButton(outputId = "findMotifsATACExport", label = "Save table")
                                                              ),
                                                     tabPanel("Heatmap of enriched motifs (top-10)",
                                                              div(id="findMotifsHeatmapATAC_loader",
                                                                  shinycssloaders::withSpinner(
                                                                    plotlyOutput(outputId = "findMotifsHeatmapATAC", height = "800px")
                                                                  )
                                                                )
                                                              )
                                                     )
                                     )
                                   )
                          )
              )
      ),

      #Clusters' annotation
      tabItem(tabName = "annotateClusters",
              tabsetPanel(type="tabs", id = "annotateClustersTabPanel",
                          tabPanel("scRNA-seq",
                                   fluidRow(
                                     box(
                                       width = 3, status = "info", solidHeader = TRUE,
                                       title = "Annotation parameters",
                                       radioButtons("annotateClustersReference", label = "Reference dataset : ",
                                                    choices = list("ImmGen (mouse)" = "immgen",
                                                                   "Presorted RNAseq (mouse)" = "mmrnaseq",
                                                                   "Blueprint-Encode (human)" = "blueprint",
                                                                   "Primary Cell Atlas (human)" = "hpca",
                                                                   "DICE (human)" = "dice",
                                                                   "Hematopoietic diff (human)" = "hema",
                                                                   "Presorted RNA seq (human)" = "hsrnaseq"
                                                    ),
                                                    selected = "mmrnaseq"
                                       ),
                                       tags$hr(),
                                       sliderInput("annotateClustersSlider", "Keep top Nth % of variable genes in reference :", min = 0, max = 100, value = 100, step = 1),
                                       tags$hr(),
                                       radioButtons("annotateClustersMethod", label = "Select method for comparisons : ",
                                                    choices = list("logFC dot product" = "logfc_dot_product",
                                                                   "logFC Spearman" = "logfc_spearman",
                                                                   "logFC Pearson" = "logfc_pearson",
                                                                   "Spearman (all genes)" = "all_genes_spearman",
                                                                   "Pearson (all genes)" = "all_genes_pearson"
                                                    ),
                                                    selected = "all_genes_pearson"
                                       ),
                                       tags$hr(),
                                       actionButton(inputId = "annotateClustersConfirm", label = "OK"),
                                     ),
                                     box(
                                       width = 9, status = "info", solidHeader = TRUE, title = "Cell type annotation",
                                       tabsetPanel(type = "tabs",
                                                   tabPanel("Top-5 hits table",
                                                            div(class="ldBar", id="annot1_loader", "data-preset"="circle"),
                                                            dataTableOutput(outputId="annotateClustersCIPRTable"),
                                                            downloadButton(outputId = "annotationRNAExport", label = "Save table")
                                                   ),
                                                   tabPanel("Top-5 hits dotplot",
                                                            div(class="ldBar", id="annot2_loader", "data-preset"="circle"),
                                                            div(id="annotateClustersCIPRDotplot_loader",
                                                                shinycssloaders::withSpinner(
                                                                  plotlyOutput(outputId="annotateClustersCIPRDotplot", height = "1100px")
                                                                )
                                                            )
                                                   )
                                       )
                                     )
                                   )
                          ),
                          tabPanel("scATAC-seq",
                                   fluidRow(
                                     box(
                                       width = 3, status = "info", solidHeader = TRUE, title = "Annotation options",
                                       fileInput(inputId = "annotateClustersRDSInput", label = "Upload an .RDS file", accept = ".RDS"),
                                       actionButton(inputId = "annotateClustersConfirmATAC", label = "OK"),
                                     ),
                                     box(
                                       width = 9, status = "info", solidHeader = TRUE, title = "Cell type annotation from scRNA-seq", # #
                                       div(id="annotateClustersUMAP_loader",
                                           shinycssloaders::withSpinner(
                                             plotlyOutput(outputId="annotateClustersUMAPplot", height = "1100px")
                                           )
                                       )
                                     )
                                   )
                          ),
                          tabPanel("HemaScribe",
                                   fluidRow(
                                     box(
                                       width = 3, status = "info", solidHeader = TRUE,
                                       title = "HemaScribe parameters",
                                       selectInput(inputId = "utilitiesReductionHemascribe", label = "Choose reduction for calculation:",  c("reduction" = "RNA.pca") ),
                                       tags$h4("Choose pca. To use batch-corrected data, choose harmony."),
                                       tags$br(),
                                       tags$br(),
                                       checkboxInput("hemaScribeBatchCorrection", "Use batch correction", value = FALSE),
                                       conditionalPanel(
                                         condition = "input.hemaScribeBatchCorrection == true",
                                         selectInput("hemaScribeBatchMetadata", "Select ident for batch:",
                                                   choices = NULL,
                                                   selected = "orig.ident")
                                       ),
                                       tags$hr(),
                                       actionButton(inputId = "hemaScribeConfirm", label = "Run HemaScribe", class = "btn btn-primary"),
                                     ),
                                     box(
                                       width = 9, status = "info", solidHeader = TRUE, title = "HemaScribe Analysis",
                                       div(class="ldBar", id="hemaScribe_loader", "data-preset"="circle"),
                                       tags$h4("About HemaScribe"),
                                       tags$p("HemaScribe is a two-stage classifier for automated annotation of hematopoietic cell types in single-cell RNA-seq data."),
                                       tags$h5("Classification Stages:"),
                                       tags$ul(
                                         tags$li(tags$strong("Broad Classification:"), " Identifies major hematopoietic cell lineages using bulk RNA-seq references"),
                                         tags$li(tags$strong("Fine Classification:"), " Provides detailed subtype annotation, particularly for HSPCs (Hematopoietic Stem and Progenitor Cells)")
                                       ),
                                       tags$hr(),
                                       tags$h4("How to visualize:"),
                                       tags$h5("細胞のclassificationはmetadata(ident)に追加されている"),
                                       tags$h5("分化系譜がわかりやすいElastic EmbeddingはEEとして登録"),
                                       tags$h5("Plot reducionでEEを選択"),
                                       tags$h5("pseudotimeやhematopoietic scroeはFeature PlotでGene signatureで選択できる"),
                                       tags$hr(),
                                       tags$h5("HemaScape Results Explanation:"),
                                       tags$h4("1. density_cluster_pred（密度クラスター）"),
                                       tags$p("転写状態空間での", tags$strong("安定な細胞状態"), "を表す"),
                                       tags$ul(
                                         tags$li(tags$strong("DensityPath"), "アルゴリズムで同定された高密度領域"),
                                         tags$li("造血分化過程の", tags$strong("重要な中間点"), "や", tags$strong("決定点"), "を表現"),
                                         tags$li("細胞が比較的長時間滞在する安定状態"),
                                         tags$li(tags$strong("例"), ": HSC状態、MPP状態、lineage-committed progenitor状態など")
                                       ),
                                       tags$h4("2. branch_pred（分化系譜）"),
                                       tags$p("造血分化の", tags$strong("主要な系譜"), "を表す"),
                                       tags$ul(
                                         tags$li(tags$strong("造血分化の大きな運命決定"), "を反映"),
                                         tags$li(tags$strong("主要な分化経路"), ":", 
                                                tags$ul(
                                                  tags$li("Myeloid（骨髄系）"),
                                                  tags$li("Lymphoid（リンパ系）"),
                                                  tags$li("Megakaryocyte/Erythroid（巨核球/赤血球系）")
                                                )),
                                         tags$li("HemaScribeの細胞型アノテーションと連動")
                                       ),
                                       tags$h4("3. branch_segment_clusters_pred（分化セグメント）"),
                                       tags$p("各系譜内での", tags$strong("より細かい分化段階")),
                                       tags$ul(
                                         tags$li("branch_predをさらに細分化したもの"),
                                         tags$li(tags$strong("同一系譜内の分化進行"), "を捉える"),
                                         tags$li(tags$strong("例"), ": Myeloid系譜内でのGMP→GP→成熟顆粒球への段階的分化")
                                       ),
                                       tags$h4("4. pseudotime_pred（擬似時間）"),
                                       tags$p("HSCからの", tags$strong("分化進行度")),
                                       tags$ul(
                                         tags$li("HSCを起点（pseudotime = 0）とした分化の進行度"),
                                         tags$li("値が大きいほど分化が進んだ状態"),
                                         tags$li("造血分化のタイムライン上での位置を示す")
                                       ),
                                       tags$h5("生物学的解釈"),
                                       tags$ul(
                                         tags$li(tags$strong("density_cluster"), ": 「この細胞は何の状態にあるか？」"),
                                         tags$li(tags$strong("branch_pred"), ": 「この細胞はどの系譜に向かっているか？」"),
                                         tags$li(tags$strong("branch_segment_clusters"), ": 「系譜内でどの段階にあるか？」"),
                                         tags$li(tags$strong("pseudotime"), ": 「分化がどれだけ進んでいるか？」")
                                       ),
                                       tags$h5("Results:"),
                                       tags$p("After analysis completion, results are added to the Seurat object metadata and can be accessed for downstream visualization and analysis.")
                                     )
                                   )
                          ),

                         # BoneMarrowMap tab
                         tabPanel("BoneMarrowMap",
                                  fluidRow(
                                    box(
                                      width = 4, status = "info", solidHeader = TRUE,
                                      title = "BoneMarrowMap Parameters",

                                      # Species warning
                                      tags$div(
                                        id = "bmmSpeciesWarning",
                                        style = "background-color: #f8d7da; padding: 10px; border-radius: 5px; margin-bottom: 15px; border-left: 4px solid #dc3545;",
                                        tags$p(style = "margin: 0; color: #721c24;",
                                          tags$b("⚠ Human data only: "), "BoneMarrowMap is designed for human hematopoietic cells."
                                        )
                                      ),

                                      tags$hr(),
                                      tags$h4("1. Batch Correction"),
                                      checkboxInput("bmmUseBatch", "Apply batch correction", value = FALSE),
                                      conditionalPanel(
                                        condition = "input.bmmUseBatch == true",
                                        selectInput("bmmBatchVar", "Select batch variable:",
                                                  choices = NULL,
                                                  selected = NULL),
                                        tags$p(style = "color: #666; font-size: 0.85em;",
                                               "Select metadata column for batch correction (e.g., orig.ident, sample)")
                                      ),

                                      tags$hr(),
                                      tags$h4("2. Mapping Settings"),
                                      numericInput("bmmSigma", "Sigma (soft clustering)",
                                                  value = 0.1, min = 0.01, max = 1.0, step = 0.05),
                                      tags$p(style = "color: #666; font-size: 0.85em;",
                                             "Fuzziness for soft clustering. σ=1 is hard clustering, lower values are softer."),

                                      tags$hr(),
                                      tags$h4("3. QC Settings"),
                                      numericInput("bmmMADthreshold", "MAD threshold",
                                                  value = 2.5, min = 1.0, max = 5.0, step = 0.5),
                                      tags$p(style = "color: #666; font-size: 0.85em;",
                                             "Median Absolute Deviation cutoff for identifying low-quality mappings."),
                                      checkboxInput("bmmThresholdByDonor", "Threshold by donor", value = FALSE),
                                      conditionalPanel(
                                        condition = "input.bmmThresholdByDonor == true",
                                        selectInput("bmmDonorKey", "Select donor variable:",
                                                  choices = NULL,
                                                  selected = NULL)
                                      ),

                                      tags$hr(),
                                      tags$h4("4. Prediction Settings"),
                                      numericInput("bmmK", "k (nearest neighbors)",
                                                  value = 30, min = 5, max = 100, step = 5),
                                      tags$p(style = "color: #666; font-size: 0.85em;",
                                             "Number of nearest neighbors for cell type and pseudotime prediction."),
                                      checkboxInput("bmmIncludeBroad", "Include broad cell types", value = TRUE),

                                      tags$hr(),
                                      actionButton(inputId = "bmmConfirm", label = "Run BoneMarrowMap", class = "btn btn-primary")
                                    ),
                                    box(
                                      width = 8, status = "info", solidHeader = TRUE, title = "BoneMarrowMap Analysis",
                                      div(class="ldBar", id="bmm_loader", "data-preset"="circle"),

                                      tags$h4("About BoneMarrowMap"),
                                      tags$p("BoneMarrowMap is a Symphony-based reference mapping tool for projecting query hematopoietic cells onto a comprehensive human bone marrow reference atlas."),

                                      tags$h5("Processing Steps:"),
                                      tags$ol(
                                        tags$li(tags$strong("map_Query():"), " Projects query cells onto the reference PCA space using Symphony"),
                                        tags$li(tags$strong("calculate_MappingError():"), " Computes mapping quality metrics for QC"),
                                        tags$li(tags$strong("predict_CellTypes():"), " Assigns cell type labels based on k-NN classification"),
                                        tags$li(tags$strong("predict_Pseudotime():"), " Predicts differentiation pseudotime scores")
                                      ),

                                      tags$hr(),
                                      tags$h4("Output"),
                                      tags$h5("Metadata columns added:"),
                                      tags$ul(
                                        tags$li(tags$code("mapping_error"), " - Mapping error score"),
                                        tags$li(tags$code("mapping_error_QC"), " - QC status (Pass/Fail)"),
                                        tags$li(tags$code("initial_CellType"), " / ", tags$code("predicted_CellType"), " - Cell type predictions"),
                                        tags$li(tags$code("predicted_CellType_Broad"), " - Broad cell type category"),
                                        tags$li(tags$code("initial_Pseudotime"), " / ", tags$code("predicted_Pseudotime"), " - Pseudotime scores")
                                      ),

                                      tags$h5("Reductions added:"),
                                      tags$ul(
                                        tags$li(tags$code("bmm"), " - BoneMarrowMap harmony embedding"),
                                        tags$li(tags$code("bmm_umap"), " - UMAP projection onto reference coordinates")
                                      ),

                                      tags$hr(),
                                      tags$h5("Reference:"),
                                      tags$p("Zeng et al., ",
                                             tags$a(href = "https://github.com/andygxzeng/BoneMarrowMap",
                                                   target = "_blank", "BoneMarrowMap GitHub"))
                                    )
                                  )
                         )
              )
      ),

      #irGSEA tab
      tabItem(tabName = "genesetscore",
              fluidRow(
                box(
                  width = 12, status = "info", solidHeader = TRUE,
                  title = "Gene Set Score",

                  tabsetPanel(
                    id = "genesetScoreTabPanel",

                    # irGSEA tab
                    tabPanel("irGSEA",
                      tags$h3("Gene set scoring by irGSEA"),
                      selectInput("irGSEAmethod", "Select method", choices=c("pagoda2","VISION", "AUCell", "singscore",
                                            "ssgsea", "JASMINE", "viper"), selected = "pagoda2"),
                      tags$h5("See https://www.sciencedirect.com/science/article/pii/S2001037020304293 for the benchmark of the methods"),

                      # Method comparison help - expandable
                      tags$div(
                        tags$button(
                          class = "btn btn-link",
                          `data-toggle` = "collapse",
                          `data-target` = "#methodComparisonHelp",
                          style = "padding: 5px 10px; text-decoration: none;",
                          tags$i(class = "fa fa-question-circle", style = "margin-right: 5px;"),
                          "Method Comparison Guide (click to expand)"
                        ),
                        tags$div(
                          id = "methodComparisonHelp",
                          class = "collapse",
                          style = "background-color: #f0f8ff; border-left: 4px solid #2196F3; padding: 10px; margin: 10px 0;",
                          tags$p(tags$em("Based on irGSEA benchmarking study (Briefings in Bioinformatics, 2024)")),
                          tags$ul(
                            tags$li(tags$b("Dataset-composition-independent methods:"),
                                    tags$br(),
                                    tags$b("AUCell, UCell, singscore, ssgsea, JASMINE, viper"),
                                    tags$ul(
                                      tags$li("Each gene set is scored ", tags$b("independently")),
                                      tags$li("Scores depend ", tags$b("only on gene expression ranks"), " within each cell"),
                                      tags$li("Results are ", tags$b("NOT affected"), " by other gene sets in the dataset"),
                                      tags$li("Works with ", tags$b("1 or more"), " gene sets")
                                    )),
                            tags$li(tags$b("Dataset-composition-dependent methods:"),
                                    tags$br(),
                                    tags$b("pagoda2, VISION"),
                                    tags$ul(
                                      tags$li("Gene sets are evaluated ", tags$b("relative to the entire dataset")),
                                      tags$li("Results ", tags$b("ARE affected"), " by other gene sets present"),
                                      tags$li("pagoda2 selects top 15 aspects based on variance across all gene sets"),
                                      tags$li("When adding new data or gene sets, all scores must be recalculated")
                                    ))
                          ),
                          tags$p(tags$b("Note:"), " For GMT files with only 1 gene set, use dataset-composition-independent methods.",
                                 style = "color: #d32f2f; margin-top: 5px;")
                        )
                      ),

                     selectInput("irGSEAset", "Select mSigDB gene set", choices=c("Hallmark"="H","KEGG_LEGACY" = "CP:KEGG_LEGACY",
                      "KEGG_MEDICUS" ="CP:KEGG_MEDICUS","Reactome"="CP:REACTOME",
                        "Gene Ontology Biological Process"="GO:BP", "WikiPathways"="CP:WIKIPATHWAYS","BIOCARTA"="CP:BIOCARTA","TF target GTRD subset"="TFT:GTRD",
                        "C7 immunologic signature"="C7:IMMUNESIGDB", "C8 cell type signature"="C8"), selected = "Hallmark"),
                      actionButton(inputId = "irGSEAconfirm", label = "Calculate gene set score",class = "btn btn-info"),
                      tags$br(),
                      tags$hr(),
                      fileInput(inputId = "uploadgmt", label = "Use your own gmt", accept = c("gmt","GMT")),
                      actionButton(inputId = "irGSEAconfirmUpload", label = "Upload gmt and calculate gene set score"),
                      conditionalPanel(
                        condition = "input.irGSEAmethod == 'pagoda2'",
                        tags$div(
                          style = "background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 8px; margin: 10px 0;",
                          tags$p(
                            tags$b("⚠ Note for pagoda2:"),
                            " pagoda2 requires at least ", tags$b("2 gene set terms"), " in your GMT file. ",
                            "For single gene set term analysis, use other methods (AUCell, UCell, singscore, ssgsea, VISION, etc.).",
                            style = "margin: 0; color: #856404;"
                          )
                        )
                      ),
                      tags$h5("options:"),
                      numericInput("maxGSSize", "Max genes in a set:", min = 100, max = 2000, value = 500, step = 100),

                      tags$h4("New assay wiil be generated, which can be used for visualization and analysis. Counts and data slot are the same."),
                      tags$h5("For feature plot, the Zissou1 color may be appropriate."),
                      tags$h5("Default assay is used for calculation except pagoda2 and VISION, which use RNA counts.")
                    ),

                    # GSDensity tab
                    tabPanel("GSDensity",
                      tags$h3("Density-based Gene Set Specificity (GSDensity)"),
                      tags$h5("Liang et al., Nature Methods (2023). ",
                              tags$a(href="https://github.com/KChen-lab/gsdensity", target="_blank", "GitHub")),

                      # Method description - expandable
                      tags$div(
                        tags$button(
                          class = "btn btn-link",
                          `data-toggle` = "collapse",
                          `data-target` = "#gsdensityHelp",
                          style = "padding: 5px 10px; text-decoration: none;",
                          tags$i(class = "fa fa-question-circle", style = "margin-right: 5px;"),
                          "About GSDensity (click to expand)"
                        ),
                        tags$div(
                          id = "gsdensityHelp",
                          class = "collapse",
                          style = "background-color: #f0f8ff; border-left: 4px solid #2196F3; padding: 10px; margin: 10px 0;",
                          tags$p("GSDensity uses Multiple Correspondence Analysis (MCA) to co-embed cells and genes, ",
                                 "then evaluates gene set enrichment via Kullback-Leibler divergence (KLD) and ",
                                 "identifies relevant cells using Random Walk with Restart (RWR) label propagation."),
                          tags$ul(
                            tags$li(tags$b("Cluster-free:"), " Does not require pre-defined clusters"),
                            tags$li(tags$b("Sparse-resistant:"), " Works well with dropout-heavy scRNA-seq data"),
                            tags$li(tags$b("Per-cell scores:"), " Produces continuous pathway activity scores for each cell"),
                            tags$li(tags$b("Specificity:"), " Can evaluate which clusters are most enriched for each pathway"),
                            tags$li(tags$b("Spatial support:"), " Can test spatial clustering of pathway-active cells")
                          )
                        )
                      ),

                      tags$hr(),

                      # Gene set source selection
                      tags$h4("Gene Set Source"),
                      radioButtons("gsdensitySource", "Select gene set source:",
                                   choices = c("mSigDB" = "msigdb", "Upload GMT" = "gmt"),
                                   selected = "msigdb", inline = TRUE),

                      conditionalPanel(
                        condition = "input.gsdensitySource == 'msigdb'",
                        selectInput("gsdensityGeneset", "Select mSigDB gene set",
                          choices = c("Hallmark" = "H",
                                      "KEGG_LEGACY" = "CP:KEGG_LEGACY",
                                      "KEGG_MEDICUS" = "CP:KEGG_MEDICUS",
                                      "Reactome" = "CP:REACTOME",
                                      "Gene Ontology Biological Process" = "GO:BP",
                                      "WikiPathways" = "CP:WIKIPATHWAYS",
                                      "BIOCARTA" = "CP:BIOCARTA",
                                      "TF target GTRD subset" = "TFT:GTRD",
                                      "C7 immunologic signature" = "C7:IMMUNESIGDB",
                                      "C8 cell type signature" = "C8"),
                          selected = "H")
                      ),
                      conditionalPanel(
                        condition = "input.gsdensitySource == 'gmt'",
                        fileInput(inputId = "gsdensityGMT", label = "Upload GMT file", accept = c("gmt", "GMT"))
                      ),

                      tags$hr(),

                      # Parameters
                      tags$h4("Parameters"),
                      fluidRow(
                        column(4, numericInput("gsdensityDims", "MCA dimensions:", min = 10, max = 100, value = 50, step = 10)),
                        column(4, numericInput("gsdensityNgrids", "KLD grid resolution:", min = 50, max = 500, value = 100, step = 50)),
                        column(4, numericInput("gsdensityNtimes", "Permutations:", min = 50, max = 500, value = 100, step = 50))
                      ),
                      fluidRow(
                        column(4, numericInput("gsdensityNN", "Nearest neighbors:", min = 50, max = 1000, value = 300, step = 50)),
                        column(4, numericInput("gsdensityRestart", "RWR restart:", min = 0.1, max = 0.95, value = 0.75, step = 0.05)),
                        column(4, numericInput("gsdensityGeneSetCutoff", "Min genes per set:", min = 1, max = 50, value = 3, step = 1))
                      ),

                      tags$hr(),

                      # Options
                      tags$h4("Options"),
                      checkboxInput("gsdensitySpecificity", "Compute cluster specificity scores", value = TRUE),
                      checkboxInput("gsdensityBinarize", "Binarize cell labels (positive/negative)", value = TRUE),
                      checkboxInput("gsdensitySpatial", "Compute spatial KLD (for Spatial Transcriptomics data)", value = FALSE),
                      conditionalPanel(
                        condition = "input.gsdensitySpatial == true",
                        fluidRow(
                          column(4, numericInput("gsdensitySpatialN", "Spatial KLD bins:", min = 5, max = 50, value = 10, step = 5)),
                          column(4, numericInput("gsdensitySpatialNtimes", "Spatial permutations:", min = 10, max = 100, value = 20, step = 10))
                        )
                      ),

                      tags$hr(),

                      # Run button
                      actionButton(inputId = "runGSDensity", label = "Run GSDensity", class = "btn btn-info"),

                      tags$hr(),

                      # Results
                      tags$h4("KLD Test Results (significant pathways)"),
                      DT::dataTableOutput("gsdensityKLDtable"),

                      conditionalPanel(
                        condition = "input.gsdensitySpecificity == true",
                        tags$hr(),
                        tags$h4("Cluster Specificity Scores"),
                        DT::dataTableOutput("gsdensitySpecTable")
                      ),

                      conditionalPanel(
                        condition = "input.gsdensitySpatial == true",
                        tags$hr(),
                        tags$h4("Spatial KLD Results"),
                        DT::dataTableOutput("gsdensitySpatialTable")
                      ),

                      tags$h4("Scores are stored as a new assay for FeaturePlot visualization."),
                      tags$h5("Binarized labels are stored in metadata (cluster identity dropdown).")
                    ),

                    # CytoTRACE2 tab
                    tabPanel("CytoTRACE2",
                      tags$h3("CytoTRACE2 for development potential"),
                      actionButton(inputId = "runCytotrace", label = "Run CytoTRACE2",class = "btn btn-info"),
                      tags$h4("CytoTRACE2_Score"),
                      tags$table(
                        tags$thead(
                          tags$tr(
                            tags$th("Range"),
                            tags$th("Potency")
                          )
                        ),
                        tags$tbody(
                          tags$tr(
                            tags$td("0 to 1/6"),
                            tags$td("Differentiated")
                          ),
                          tags$tr(
                            tags$td("1/6 to 2/6"),
                            tags$td("Unipotent")
                          ),
                          tags$tr(
                            tags$td("2/6 to 3/6"),
                            tags$td("Oligopotent")
                          ),
                          tags$tr(
                            tags$td("3/6 to 4/6"),
                            tags$td("Multipotent")
                          ),
                          tags$tr(
                            tags$td("4/6 to 5/6"),
                            tags$td("Pluripotent")
                          ),
                          tags$tr(
                            tags$td("5/6 to 1"),
                            tags$td("Totipotent")
                          )
                        ),
                        class = "table table-bordered"
                      )
                    )
                  )


                )
              )
      ),
      #Trajectory analysis
      tabItem(tabName = "trajectory",
              tabsetPanel(type="tabs", id = "trajectoryTabPanel",
                          tabPanel("scRNA-seq",
                                   fluidRow(
                                     box(
                                       width = 3, status = "info", solidHeader = TRUE,
                                       title = "Slingshot parameters",
                                       selectInput("trajectoryReduction", "Dimensionality reduction method:", choices=c("PCA"), selected = "RNA.pca", multiple = FALSE,selectize = TRUE, width = NULL, size = NULL),
                                        tags$h4("PCA is recommended"),
                                       numericInput("trajectorySliderDimensions", "Number of dimensions to use :", min = 0, max = 50, value = 10, step = 1),
                                       tags$h4("seurat_clusters is used."),
                                       selectInput("trajectoryStart", "Initial states:", choices=c("DO NOT SET"), selected = "DO NOT SET", multiple = T, selectize = TRUE),
                                       selectInput("trajectoryEnd", "Final states:", choices=c("DO NOT SET"), selected = "DO NOT SET", multiple = T, selectize = TRUE),
                                       actionButton(inputId = "trajectoryConfirm", label = "1. Run calc", class = "btn btn-warning"),
                                       tags$hr(),
                                      selectInput("trajectoryReductionShow", "Visualization space:", choices=c("UMAP"), selected = "RNA.umap", multiple = FALSE, selectize = TRUE, width = NULL, size = NULL),
                                      actionButton(inputId = "trajectoryVis", label = "2. Visualize trajectory", class = "btn btn-warning"),
                                       checkboxInput("omega", label = "Set omega TRUE for multiple lineages of cells?", value = FALSE),
                                       selectInput("distmethod", label = "Distance calculaton method",
                                                choices = c("slingshot",  "simple", "scaled.full", "scaled.diag","mnn"),
                                                selected = "slingshot"),
                                       numericInput("stretch", "How long to strech the curve beyond endpoint:", min = 0, max = 3, value = 2,step = 1),
                                                                              tags$br(),
                                       tags$hr(),
                                       tags$h3("Visualization option"),
                                        selectInput("trajectoryColorPalette", "Color palette:", c( "Set1",
                                        "Set2", "Set3",  "Paired", "Dark2", "Accent", "Spectral",
                                        'stallion','stallion2','calm','kelly','bear','ironMan','circus','paired',
                                        'grove','summerNight','zissou','Zissou1Continuous', 'darjeeling','rushmore','captain'), selected = 'Set1'),
                                     numericInput("trajectoryDotSize", "Dot size:", min = 0.1, max = 10, value = 2, step = 0.1), # value = 5
                                  numericInput("trajectoryDotOpacity", "Dot opacity (0-1):", min = 0, max = 1, value = 0.8, step = 0.1), # value = 1
                                     numericInput("trajectoryWidth", "Plot width:", min = 200, max = 1200, value = 800, step = 50),
                                    numericInput("trajectoryHeight", "Plot height:", min = 200, max = 1600, value = 700, step = 50),
                         numericInput("slingX", "Dim to show in X:", min = 1, max = 30, value = 1, step = 1),
                         numericInput("slingY", "Dim to show in Y:", min = 1, max = 30, value = 2, step = 1),

                                     ),

                                   box(
                                     width = 9, height = 1200, status = "info", solidHeader = TRUE, title = "Trajectory analysis results",
                                     tabsetPanel(type = "tabs",
                                      tabPanel("Structure overview",
                                      verbatimTextOutput(outputId="trajectoryText"),
                                      downloadButton(outputId = "trajectoryStructuredownloaderPNG",label = "download as png"),
                                     downloadButton(outputId = "trajectoryStructuredownloaderPDF",label = "download as pdf"),
                                                          div(class="ldBar", id="traj1_loader", "data-preset"="circle"),
                                                          div(id="trajectoryPlot_loader",
                                                              shinycssloaders::withSpinner(
                                                                plotOutput(outputId="trajectoryPlot")
                                                                )
                                                              )
                                                        ),
                                                tabPanel("Lineage curves",
                                        actionButton(inputId = "trajectoryConfirmCurve", label = "Redraw", class = "btn btn-info"),
                                  downloadButton(outputId = "trajectoryCurvedownloaderPNG",label = "download as png"),
                                     downloadButton(outputId = "trajectoryCurvedownloaderPDF",label = "download as pdf"),
                                                          div(class="ldBar", id="traj1_loader", "data-preset"="circle"),
                                                          div(id="trajectoryCurve_loader",
                                                              shinycssloaders::withSpinner(
                                                                plotOutput(outputId="trajectoryCurve")
                                                                )
                                                              )),
                                                 tabPanel("Lineage-Pseudotime view", fluidRow(
                                                       selectInput(inputId = 'trajectoryLineageSelect',
                                                                   label = 'Select lineage:',
                                                                   choices = c("Lineage1"),
                                                                   selected = "Lineage1",
                                                                   multiple = FALSE),
                                                       actionButton(inputId = "trajectoryConfirmLineage", label = "change lineage",
                                                        class = "btn btn-info"),
                                     downloadButton(outputId = "trajectoryTimedownloaderPNG",label = "download as png"),
                                     downloadButton(outputId = "trajectoryTimedownloaderPDF",label = "download as pdf"),
                                      downloadButton(outputId = "trajectoryPseudotimeExport", label = "download pseudotime table"),
                                                       div(class="ldBar", id="traj2_loader", "data-preset"="circle"),
                                                       div(id="trajectoryPseudotimePlot_loader",
                                                           shinycssloaders::withSpinner(
                                                             plotOutput(outputId = "trajectoryPseudotimePlot")
                                                             )
                                                           )
                                                 )# fluid rowの最後
                                                )
                                   )
                          )
                  )
                ),
                tabPanel("scATAC-seq",
                         fluidRow(
                           box(
                             width = 3, status = "info", solidHeader = TRUE,
                             title = "Trajectory parameters",
                             sliderInput("trajectorySliderDimensionsATAC", "Number of UMAP dimensions to use :", min = 0, max = 100, value = 3, step = 1),
                             selectInput(inputId = "trajectoryGroupByATAC",
                                         label = "Cells group by: ",
                                         choices = c("-"="-",
                                                     "Clusters"="Clusters",
                                                     "Integration predicted clusters"="predictedGroup_Co"),
                                         selected = "-"),
                             selectInput("trajectoryStartATAC", "Initial state:", choices=c("-"="-"), selected = "-", multiple = F, selectize = F),
                             selectInput("trajectoryEndATAC", "Final state:", choices=c("-"="-"), selected = "-", multiple = F, selectize = F),
                             actionButton(inputId = "trajectoryConfirmATAC", label = "OK")
                           ),
                           box(
                             width = 9, status = "info", solidHeader = TRUE,
                             title = "Pseudotime plot",
                             selectInput(inputId = 'trajectoryLineageSelectATAC',
                                         label = 'Select lineage:',
                                         choices = c("Lineage1"),
                                         selected = "Lineage1",
                                         multiple = FALSE),
                             actionButton(inputId = "trajectoryConfirmLineageATAC", label = "Display pseudotime ranking"),
                             div(class="ldBar", id="traj4_loader", "data-preset"="circle"),
                             div(id="trajectoryPseudotimePlotATAC_loader",
                                 shinycssloaders::withSpinner(
                                   plotOutput(outputId = "trajectoryPseudotimePlotATAC", height = "1100px")
                                   )
                                 ),
                             div(class="ldBar", id="traj3_loader", "data-preset"="circle"),
                             verbatimTextOutput(outputId="trajectoryTextATAC"),
                           )
                         )
                )
              )
      ),

      #L-R analysis
      tabItem(tabName = "ligandReceptor",
        tabsetPanel(type = "tabs",
            tabPanel("Nichenet",  fluidRow(
                 box(
                   width = 3, status = "info", solidHeader = TRUE,
                   title = "Nichenet",
                   selectInput("ligandReceptorSender", "Ligand expressing cluster:", choices=c("-"="-"), multiple = TRUE, selectize = TRUE),
                   selectInput("ligandReceptorReciever", "Receptor expressing cluster:", choices=c("-"="-"), multiple = FALSE, selectize = TRUE),
                    tags$h4("Genes differentially expressed in the target cells"),
                    tags$h5("e.g., genes differentially expressed upon cell-cell interaction"),
                     textAreaInput(inputId = "geneoi", label = "Genes of interest", cols = 80, rows = 5, placeholder = "Prg4\nTspan15\nCol22a1\nHtra4"),
                    tags$h5("The potential ligands will be ranked based on the presence of their target genes in the gene set of interest"),
                    tags$h5("If left blank, all the expressed ligands in sender cells will be used."),
                   numericInput("topnum", label = "Number of top ligands to be used:", min = 10, value = 30),
                   checkboxInput("subsettingNichenet", label = "Subset the data only for the sender/receiver cells?", value = FALSE),
                   tags$h5("Affects only top ligands expression dotplots."),
                   selectInput("nichnetDatabase", "Database use:",c(
                                                     "Nichenet"="Nichenet",
                                                     "cellchat-secreted + Omnipath-small"="cellchat-small",
                                                     "cellchat-secreted + Omnipath-only"="cellchat-omnipath",
                                                     "cellchat-secreted + Omnipath-full-highconfident"="cellchat-full",
                                                     "Omnipath: small"="small",
                                                     "Omnipath: omnipath-only"="full-highconfident",
                                                     "Omnipath: full-high confident"="omnipath",
                                                     "Omnipath: full"='full',
                                                     "CellPhoneDB-LR-only + Omnipath-only"="cellphonedb-LR-omnipath",
                                                     "CellPhoneDB-LR-all + Omnipath-only"="cellphonedb-full-omnipath"
                                                     ), multiple = FALSE, selected = "Nichenet"),
                   actionButton(inputId = "ligandReceptorConfirm", label = "Run Nichenetr",class = "btn btn-warning"),
                   tags$hr(),
                   tags$h3("Options for prioritization analysis"),
                   checkboxInput("runNichenetPriority", label = div(style = "font-size:18px","Run prioritizing analysis?"), value = FALSE),
                   selectInput(inputId = "NichenetDEident", label = "Choose identity containing comparing conditions (e.g., WT and KO): ", c("Cluster" = "orig.ident")),
                    actionButton(inputId = "NichenetDEidentConfirm", label = "Show cluster ident to select", class = "btn btn-info"),
                    selectInput(inputId = "NichenetDEidentTest", label = "Test cell type:", choices = "-", multiple = FALSE,selectize = FALSE),
                    #selectInput(inputId = "NichenetDEidentCTRL", label = "Control cell type:", choices = "-", multiple = TRUE,selectize = TRUE),
                     checkboxInput("usePriorLigands", label = "Use prioritized results to determine top ligands?", value = FALSE),
                    checkboxInput("includeAcrossCell", label = "Include condition-specificity of the ligand/receptor across all cell-types?", value = TRUE),###コード追加必要
                 ),
                 box(
                   width = 9, status = "info", solidHeader = TRUE, title = "L-R analysis results",
                   div(class="ldBar", id="lr_loader", "data-preset"="circle"),
                   div(
                     tabsetPanel(type = "tabs",
                                 tabPanel("All interactions",
                                          div(id="ligandReceptorFullHeatmap_loader",
                                              shinycssloaders::withSpinner(
                                                plotlyOutput(outputId="ligandReceptorFullHeatmap", height = "1100px")
                                                )
                                              ),
                                          downloadButton(outputId = "ligandReceptorFullExport", label = "Save table")),
                                 tabPanel("Curated interactions",
                                    tags$h3("Curated interactions (documented in literature and publicly available databases)"),
                                          div(id="ligandReceptorCuratedHeatmap_loader",
                                              shinycssloaders::withSpinner(
                                                plotlyOutput(outputId="ligandReceptorCuratedHeatmap", height = "1100px")
                                                )
                                              ),
                                          downloadButton(outputId = "ligandReceptorShortExport", label = "Save table")),
                              tabPanel("Top ligands",
                                tags$h3("Expression of top-ranked ligands"),
                                numericInput("ligandX", label = "Download size X:", min = 200, value = 800),
                                numericInput("ligandY", label = "Download size Y:", min = 200, value = 600),
                                downloadButton(outputId = "bestliganddownloaderPDF",label = "download as pdf"),
                                    plotOutput("p_best_ligand", height = "400px", width = '800px'),
                                    ),
                                 tabPanel("Receptors-genes",
                                    tags$h3("Receptors and top-predicted target genes of top-ranked ligands"),
                                numericInput("LRX", label = "Download size X:", min = 200, value = 800),
                                numericInput("LRY", label = "Download size Y:", min = 200, value = 800),
                                    downloadButton(outputId = "LRdownloaderPDF",label = "download as pdf"),
                                    plotOutput("p_ligand_target_network", height = "800px")
                                    ),

                                tabPanel("Ligand expression",
                                    tags$h3("Log fold difference in ligand expression from sender cells"),
                                numericInput("ligandDEGX", label = "Download size X:", min = 200, value = 800),
                                numericInput("ligandDEGY", label = "Download size Y:", min = 200, value = 800),
                                    downloadButton(outputId = "ligandDEGdownloaderPDF",label = "download as pdf"),
                                    plotOutput("p_ligand_lfc", height = "800px")
                                    ),
                                 tabPanel("Ligand activity",
                                    tags$h3("Ligand activity heatmap"),
                                numericInput("ligandDEGX", label = "Download size X:", min = 100, value = 400),
                                numericInput("ligandDEGY", label = "Download size Y:", min = 200, value = 800),
                                    downloadButton(outputId = "ligandauprdownloaderPDF",label = "download as pdf"),
                                    plotOutput("p_ligand_aupr", height = "600px", width = '200px')
                                    ),

                              tabPanel("Circos plot",
                                    tags$h3("Circos plot of ligan-receptor pairs"),
                                    radioButtons("circostype", label = "Select circos plot type: ",
                                            choices = list("Width = ligand-target gene regulatory potential" = "1",
                                                 "+Transparancy = relative ligand-target gene regulatory potential" = "2",
                                                 "Width = ligand-receptor interaction weight" = "3",
                                                 "+Transparency = ligand-receptor interaction weight" = "4"
                                                 )
                                            ),
                                    selectInput("nichenetColorPalette", "Ligand color palette:",c("Set1" = "Set1",
                                        "Set2" = "Set2", "Set3" = "Set3",  "Paired" = "Paired"), selected= "Set1"),
                                    selectInput("nichenetreceptorColor", "Receptor color:",c("tomato",'darkred','orange','darkorange', 'violet', 'palevioletred','blue','darkblue','darkcyan','darkseagreen',
                                        'chartreuse4','darkgoldenrod','azure3',
                                        'darkgrey'), selected= "tomato"),
                                    numericInput("cutoff_include_all_ligands_threshold", label = "Cutoff: links n% of lowest scores are removed", value=40, min = 0, max = 100),
                                    tags$h4("Circosplotのgeneral/specificの判定は全細胞腫で行われます。もしリガンド側の細胞と指定しているものだけで判定したい場合は、それ以外の細胞を除いたデータセットで解析してください。"),
                                    actionButton(inputId = "RedrawCircos", label = "Redraw circos plot",class = "btn btn-info" ),
                                    plotOutput("nichenet_circos", height = "800px", width = '800px'),
                                    plotOutput("circos_legend", height = "400px", width = '400px'),
                                numericInput("circosR", label = "Download size:", min = 200, value = 600),
                                radioButtons("circosFigtype", label = "Save as: ",
                                            choices = list("png", 'svg', 'pdf') ),
                                    downloadButton(outputId = "circosdownloaderPDF",label = "download circos plot"),

                                    ),

                                tabPanel("Ligand prioritization result table",

                                    DT::dataTableOutput("prior_table"),

                                    downloadButton(outputId = "prior_table_download", label = "Save table")
                                  ),


                                 tabPanel("Ligand prioritization plots",
                                numericInput("priorX", label = "Download size X:", min = 200, value = 800),
                                numericInput("priorY", label = "Download size Y:", min = 200, value = 800),
                                tags$h3("Prioritzed ligands activity"),
                                plotOutput("p_prior_ligand_aupr", height = "600px", width = '200px'),
                                        downloadButton(outputId = "priorauprdownloaderPDF",label = "download as pdf"),
                                        tags$h3("Prioritzed ligands expression"),
                                plotOutput("rotated_dotplot", height = "800px"),
                                    downloadButton(outputId = "priordotplotdownloaderPDF",label = "download as pdf"),
                                      tags$h3("Ligand expression between test ant control"),
                                plotOutput("DE_dotplot", height = "800px"),
                                     downloadButton(outputId = "DEdotplotGdownloaderPDF",label = "download as pdf"),
                                    tags$h3("Prioritzed ligads fold difference"),
                                plotOutput("p_prior_ligand_lfc", height = "600px", width = '400px'),
                                 downloadButton(outputId = "priorliganddownloaderPDF",label = "download as pdf"),
                                tags$h3("Mushroom plot"),
                                plotOutput("p_mushroom", height = "600px"),
                                  downloadButton(outputId = "mushroomdownloaderPDF",label = "download as pdf"),
                     ) # prioritizeの終わり
                 ))
                 ) # boxの終わり
                 )),　#　tab panelの終わり
                tabPanel("CellChat", fluidRow(
                 box(
                   width = 3, status = "info", solidHeader = TRUE,
                   title = "CellChat",
                   radioButtons("cellchatDB_use", label = "DB to use : ",
                                  choices = list("CellChat", "CellPhoneDB" ),
                                  selected = "CellChat"),
                   tags$h5("Original CellPhoneDB is for human. If mouse data, genes will be converted to human for caculation."),
                    selectInput(inputId = "cellchatIdent", label = "Choose identity to use: ",
                                 c("Cluster" = "orig.ident")),
                    selectInput(inputId = "cellchatDB" , label = "CellChat db on:", choices=c("Secreted Signaling",
                        "ECM-Receptor","Cell-Cell Contact","Non-protein Signaling", "all"), selected = "Secreted Signaling", multiple = F),
                    selectInput(inputId = "cellphoneDB" , label = "CellPhone db on:", choices=c("Ligand-Receptor",
                        "Adhesion-Adhesion","Gap-Gap","Ligand-Ligand", "Ligand-Receptor", "all"), selected = "Ligand-Receptor", multiple = F),
                    actionButton(inputId = "cellchatConfirm", label = "Run CellChat",class = "btn btn-warning"),
                    checkboxInput("projectData", label = "Use data projected on protein-protein interaction network", value = FALSE),
                    tags$h5("Useful for shallow sequencing data. See https://htmlpreview.github.io/?https://github.com/jinworks/CellChat/blob/master/tutorial/CellChat-vignette.html"),
                    numericInput("thresh.p", label = "Threshold for overexpressed genes:", min = 0.01, value = 0.05, max = 1, step=0.01),
                    numericInput("thresh", label = "Threshold for significant pairs:", min = 0.01, value = 0.05, max = 1, step=0.01),
                    tags$hr(),
                    tags$h3("Comparison of two conditios"),
                     selectInput(inputId = "cellchatSplit", label = "Choose identity to split for commarison: ",
                                 c("Cluster" = "orig.ident")),
                    actionButton(inputId = "cellchatComparisonConfirm", label = "Run comparison analysis",class = "btn btn-info"),
                    tags$h5('Do not need to run "Run CellChat" first.'),
                   checkboxInput("uploadcellchatres", label = h4("Use precomputed cellchat data for [Run CellChat] or [Run comparison analysis]?"), value = FALSE),
                   tags$h5('Upload data below.'),
                    tags$hr(),
                    tags$h3("Additional visualization"),
                    selectInput("cellchatSender", "Sender cell cluster:", choices=c("-"="-"), multiple = TRUE, selectize = TRUE),
                   selectInput("cellchatReciever", "Receiver cell cluster:", choices=c("-"="-"), multiple = TRUE, selectize = TRUE),
                   selectInput("cellchatSignaling", "Signaling pathway to show:", choices=c("-"="-"), multiple = FALSE, selectize = TRUE),
                    actionButton(inputId = "cellchatBubble", label = "Update bubble plots",class = "btn btn-info"),

                   tags$hr(),
                    tags$h3("Upload precomputed data"),
                    fileInput(inputId = "cellchat", label = "cellchat.qs", accept = c(".qs",".qs2")),
                                        tags$h4('Additional files for comparison analysis:'),
                    fileInput(inputId = "cellchat1", label = "cellchat.1.qs", accept = c(".qs",".qs2")),
                    fileInput(inputId = "cellchat2", label = "cellchat.2.qs", accept = c(".qs",".qs2")),
                   actionButton(inputId = "cellchatUpload", label = "Upload cellcaht data"),

                   ),
                 box(
                   width = 9, status = "info", solidHeader = TRUE, title = "L-R analysis results",

                              tabPanel("CellChat",
                                downloadButton(outputId = "cellchatDown", label = "Save zipped data"),
                                     tags$h5('Total interaction strength'),
                                    plotOutput("heatmap_g"),
                                    tags$h5('Significant L-R interactions from the sender to receiver cells'),
                                    plotOutput("bubble1"),
                                    tags$h5('Up/down-regulated ligand-receptor pairs'),
                                    plotOutput("bubble2"),
                                    tags$h5('The significant interactions associated with the chosen pathway'),
                                    plotOutput("bubble3"),
  #                                            ),
                                 )

                    ))
                ))),

      #GRN analysis
      tabItem(tabName = "grn",
              tabsetPanel(type="tabs", id = "grnTabPanel",
                          tabPanel("scRNA-seq",
               fluidRow(
                 box(width = 3, status = "info", solidHeader = TRUE, title = "GRN input parameters",
                     div(class="ldBar", id="loom_production_loader", "data-preset"="circle"),

                     tags$h3("Run pySCENIC"),
                     tags$hr(),
                     tags$h4(strong("Step 1:")),
                     radioButtons("grnGenomeBuild", label = h4("Select genome build : "),
	                  choices = list("Mus musculus (Mouse) - mm10" = "mm10",
	                                 "Homo sapiens (Human) - hg38" = "hg38"
	                  ),
	                  selected = "mm10"),
                      selectInput("IdentSCENIC", "Set ident for calculation:",
                              c("Cluster" = "seurat_clusters")),
                      textInput(inputId = "SCENICName", label = "SCENIC assay name :", value = "SCENIC"),
                     actionButton(inputId = "Pyscenic1st", label = "Run step 1",class = "btn btn-info"),
                     tags$h5("This may take 20m/100cells ~1.5h/1000cells."),

                     tags$hr(),
                     tags$h4(strong("For metacell:")),
                     tags$h4(strong("Step 1a:")),
                     tags$h5("Load the metacell-summarized h5ad file and normalize the data first."),
                     actionButton(inputId = "Pyscenic1a", label = "Run step 1a. calc regulon"),
                     tags$h5("Save the data by [Download SCENIC res] below."),
                     tags$h4(strong("Step 1b:")),
                      tags$h4(strong("Start with regulon info file")),
                     tags$h5("For metacell, load the original data that was used to generate the metacells."),
                     fileInput(inputId = "uploadregcsv", label = "Choose reg.csv file", accept = ".csv"),
                     actionButton(inputId = "uploadregcsvConfirm", label = "Run step 1b."),
                     tags$h5("You can also upload a reg.csv generated from the entire dataset and calculate AUC independently on a subset of the dataset (e.g., WT and KO separately)."),
          #           tags$h3("Prepare files for pyscenic"),
                     tags$hr(),
	                  tags$h4(strong("Step 2:")),
                    tags$h4("Calc regulon specificity score"),
                     actionButton(inputId = "Pyscenic2nd", label = "Run step 2",class = "btn btn-info"),
                     div(class="ldBar", id="loom_analysis_loader", "data-preset"="circle"),
                     tags$hr(),
                  tags$h4(strong("Step 3:")),
                  tags$h4("Analyze gene regulatory network"),
                  actionButton(inputId = "grnLoomAnalysis", label = "Run step 3", class = "btn btn-info"),
                  tags$h5("You can upload your scenic.loom file"),
                     fileInput(inputId = "grnLoomInput", label = "Upload secnic.loom and analyze with it", accept = ".loom"),
                    tags$hr(),
                    tags$br(),
                    downloadButton(outputId = "DownloadSCENIC", label = "Download SCENIC res", class = "btn btn-warning"),
                    tags$br(),

                     tags$h3("Visualization"),
                     tags$hr(),
                     selectInput(inputId = "grnMatrixSelectionRNA", label = "Regulons - display:", choices = c("Matrix of AUC values"="auc",
                     "Matrix of RSS scores"="rss")),
                     sliderInput(inputId = "grnTopRegulonsRNA", label = "Display top regulons:", min = 5, max = 100, value = 10, step = 1),
                     actionButton(inputId = "grnConfirmVisualizationRNA", label = "Plot"),
                 ),
                 box(width = 9, status = "info", solidHeader = TRUE, title = "GRN output",
                     div( dataTableOutput(outputId="grnMatrixRNA") ),
                     tags$br(),
                     tags$h5(HTML('基本的に1,2,3の順番に進める。データの保存は随時可能。<br>1a以外は必ず比較したいクラスターをもつidenityを指定すること。<br>細胞数が多く時間がかかる場合はMetisのSEACellsでmetacellを作り、SEAcells.summarized.h5adデータを読み込みnormalizeして1aを行いDownload SCENIC resでreg.csvをダウンロードする。metacell化していないもとのデータを読み込み、1bでreg.csvをアップロードして解析。<br>WTとKOといった複数条件を含むデータセットの場合、全体と個別に行うことで結果は異なる可能性がある。WTとKOを比較する場合は、例えば全体のデータセットで1aを行い、全体のデータセット、WTのみ、KOのみで1b→2と行い、結果を比較する。')),
                     tags$h5(HTML('複数datasetをマージしている場合やHashtagを使っている場合に、全体でreg.csvを作り、その後、個別のsubsetで2以降を行うこともできる。
                      <br>WT+KOの全体でregulon.csvを作り、WT, KOを個別に解析することも。')),
                      tags$h5(HTML('転写因子活性について<br>
                      	Z-score: 各細胞タイプにおけるregulonの活性スコア。<br>
RSS: regulonの活性が特定の細胞タイプにどれだけ集中しているかをエントロピーベースで評価。regulonが一つのセルタイプにおいてのみ活性である場合、RSS スコアは 1 となる。範囲：0-1。<br>特異性を評価したい場合はRSS、活性の相対的な強さを見たい場合はZ-scoreが適している。基本的にはRSSをみるが、RSSが高くても活性が低い場合がある。https://doi.org/10.1016/j.celrep.2018.10.045')),
                     tags$hr(),
                     div(id="grnHeatmapRNA_loader",
                         shinycssloaders::withSpinner(
                           plotlyOutput(outputId = "grnHeatmapRNA", height = "800px")
                         )
                     )
                 )
               )
                          ),
                          tabPanel("scATAC-seq",
                                   fluidRow(
                                     box(
                                       width = 3, status = "info", solidHeader = TRUE, title = "Analysis options",
                                       selectInput("grnGroupByATAC", "Cells group by:",
                                                   c("Clusters" = "Clusters",
                                                     "Integration predicted clusters" = "predictedGroup_Co"
                                                   )),
                                       selectInput("grnMatrixATAC", "Matrix:",
                                                   c("Gene activity score matrix" = "GeneScoreMatrix",
                                                     "Gene Integration matrix" = "GeneIntegrationMatrix"
                                                   )),
                                       sliderInput(inputId = "grnFdrATAC", label = "FDR threshold:", min = 0, max = 1, value = 0.1, step = 0.01),
                                       sliderInput(inputId = "grnCorrlationATTAC", label = "Correllation threshold:", min = 0, max = 1, value = 0.7, step = 0.1),
                                       actionButton(inputId = "grnConfirmATAC", label = "OK")
                                     ),
                                     box(width = 9, status = "info", solidHeader = TRUE, title = "Gene regulatory networks results",
                                         tabsetPanel(type = "tabs",
                                                     tabPanel("Positive regulators table",
                                                              div(class="ldBar", id="grn2_loader", "data-preset"="circle"),
                                                              div(id="grnATACTable_loader",
                                                                  shinycssloaders::withSpinner(
                                                                    dataTableOutput(outputId="grnMatrixATAC")
                                                                  )
                                                              ),
                                                              downloadButton(outputId = "grnPositiveRegulatorsATACExport", label = "Save table"),
                                                     ),
                                                     tabPanel("Positive regulators heatmap (top-10)",
                                                              div(id="grnHeatmapATAC_loader",
                                                                  shinycssloaders::withSpinner(
                                                                    plotlyOutput(outputId = "grnHeatmapATAC", height = "800px")
                                                                  )
                                                              )
                                                     ),
                                                     tabPanel("Peak to gene links",

                                                              div(id="grnATACTable2_loader",
                                                                  shinycssloaders::withSpinner(
                                                                    dataTableOutput(outputId="grnP2GlinksTable"),
                                                                    )
                                                                  ),
                                                              downloadButton(outputId = "grnPeakToGeneLinksATACExport", label = "Save table")
                                                              ),
                                                     tabPanel("Peak x motif occurence matrix",

                                                              div(id="grnATACTable3_loader",
                                                                  shinycssloaders::withSpinner(
                                                                    dataTableOutput(outputId="grnMotifTable"),
                                                                  )
                                                              ),
                                                              downloadButton(outputId = "grnPeakMotifTableATACExport", label = "Save table")
                                                     )
                                         )
                                     )
                                   )
                          )
              )
      ),

      #ATAC-seq tracks
      tabItem(tabName = "visualizeTracks",
              fluidRow(
                box(width = 3, status = "info", solidHeader = TRUE,
                    title = "scATAC-seq tracks options",
                    selectInput("visualizeTracksGroupByATAC", "Cells group by:",
                                c("Clusters" = "Clusters",
                                  "Integration predicted clusters" = "predictedGroup_Co"
                                )),
                    selectizeInput(inputId = 'visualizeTracksGene',
                                   label = 'Select a gene:',
                                   choices = NULL,
                                   selected = NULL,
                                   multiple = FALSE),
                    sliderInput("visualizeTracksBPupstream", "BP upstream :", min = 100, max = 100000, value = 50000, step = 1000),
                    sliderInput("visualizeTracksBPdownstream", "BP downstream :", min = 100, max = 100000, value = 50000, step = 1000),
                    actionButton(inputId = "visualizeTracksConfirm", label = "OK")
                    ),
                box(width = 9, status = "info", solidHeader = TRUE,
                    title = "scATAC-seq tracks",
                    div(class="ldBar", id="tracks_loader", "data-preset"="circle"),
                    div(id="visualizeTracksOutput_loader",
                        shinycssloaders::withSpinner(
                          plotOutput(outputId="visualizeTracksOutput", height = "1100px")
                        )
                    )
                )
              )
            ),

#================spacial
      #Clustering tab
      tabItem(tabName = "spatial",
              tabsetPanel(type = "tabs", id = "spatialTabPanel",
                   tabPanel("Spatial plot", fluidRow(
                           box(width = 3, status = "info", solidHeader = TRUE, title = "Spatial plot option",
                               radioButtons("SpatialFeaturesSignature", label = "Select between gene or signature: ",
                                            choices = list("Gene" = "gene",
                                                           "Gene signature" = "signature"
                                            ),
                                            selected = "gene"),
                            selectizeInput(inputId = 'SpatialGene',
                                              label = 'Select genes:',
                                              choices = NULL,
                                              selected = NULL,
                                              multiple = TRUE), # allow for multiple inputs

                           radioButtons("SpatialGeneFeature", label = "Slot to visualize:",
                                            choices = list("Normalized data (default)" = "data",
                                                        "Raw counts" = "counts",
                                                        "Scaled data" = "scale.data"
                                            ),
                                            selected = "data"),
                               selectizeInput(inputId = 'SpatialFeature',
                                              label = 'Select signature/numeric variables:',
                                              choices = "-",
                                              selected = "-",
                                              multiple = TRUE),
                                selectInput("spatielfeatureColor", "SpatialPlot color scheme:",
                                  choices = c("default","Blues", "Reds", "Zissou1",  "Greens",
                                              "YlOrRd", "YrOrBr", "YlGnBu", "RdPu", "PuRd",
                                              "viridis", "magma", "cividis", "inferno", "plasma"),
                                  selected = 'default'
                                ),
              sliderInput("spatialMaxCutoff", "Set max expression value: (quantile)", min = 0, max = 100, value = 100, step = 1),
              sliderInput("spatialMinCutoff", "Set minimum expression value: (quantile)", min = 0, max = 99, value = 0, step = 1),


                               actionButton(inputId = "SpatialConfirm", label = "Display spatial feature plot",class = "btn btn-info" ),

                               tags$hr(),
                               tags$h3("Spatial Dim Plot"),
                              selectInput("SpatialGroupBy", "Group by:",
                                   c("Cluster" = "seurat_clusters")),
                              selectInput("SpatialDimPalette", "Color palette:",
                             c( "Set1", "Set2", "Set3",  "Paired", "Dark2", "Accent", "Spectral",
                                        'stallion','stallion2','calm','kelly','bear','ironMan','circus','paired',
                                        'grove','summerNight','zissou','Zissou1Continuous','darjeeling','rushmore','captain'), selected = 'Set1'),
                              
                              tags$hr(),
                              tags$h4("Show specified clusters"),
                              tags$h5("Please set active identity."),
                               checkboxInput("SpatialLimitClusters", label= "Show only selected clusters?", value = FALSE, width = NULL),
                               selectInput(inputId = "SpatialDimClusters", label = "Highlight clusters:", choices = "", multiple = T),
                              checkboxInput(inputId= 'facet.highlight', label= "Separate plot for each cluster?", value = FALSE, width = NULL),

                              actionButton(inputId = "SpatialDimConfirm", label = "Display spatial dim plot",class = "btn btn-info" ),
                               tags$hr(),
                              tags$h4('Options:'),
                              checkboxInput(inputId= 'showEntire', label= "Show entire histology image?", value = TRUE, width = NULL),
                              numericInput(inputId = "image.alpha", label = "Background image opacity. Set to 0 to remove.",
                                                  min = 0, max = 1, value = 1, step = 0.1),
                              numericInput(inputId = "plot.alpha", label = "Spot opacity",
                                                  min = 0, max = 1, value = 1, step = 0.1),
                              checkboxInput(inputId= 'Spatialkeep.scale', label= "Scale to the highest overall expression?", value = FALSE, width = NULL),
                              numericInput(inputId = "pt.size.factor", label = "Scale the size of the spots",
                                                  min = 0, max = 20, value = 1.6, step = 0.1),
                              checkboxInput(inputId= 'SpatialLabel', label= "Show cluster labels?", value = FALSE, width = NULL),
                              
                          numericInput("SpatialWidth", "Plot width:", min = 200, max = 1600, value = 800, step = 50),
                          numericInput("SpatialHeight", "Plot height:", min = 200, max = 1600, value = 800, step = 50),
                              ), #column
                              
                           column(width = 9, status = "info", solidHeader = TRUE, title = "Plot",
                               downloadButton(outputId = "SpatialdownloaderPNG",label = "download png"),
                               downloadButton(outputId = "SpatialdownloaderPDF",label = "download pdf"),

                                plotOutput(outputId = "SpatialPlot", height = '800px'),
                                    # plotlyOutput(outputId = "findMarkersViolinPlot")
                                   )

                         ) #fluidrow
                      ), #tabpanel

                  tabPanel("Clustering",
                   fluidRow(
                     box(
                       width = 4, status = "info", solidHeader = TRUE,
                       title = "Spatial-speciifc clustering",
                       tags$h3("BANKSY clustering"),

                      tags$hr(),
                      selectInput("BANKSYActiveAssay", "Set active assay:", c("Assay" = "RNA")),
                      tags$h4("Default values are for identifying zones"),
                        numericInput(inputId = "k_geom", label = "k_geom : Local neighborhood size. Affects the connectivity in the neighborhood graph. Larger values will yield larger domains.",   min = 10, max = 100, value = 50, step = 1),
                        numericInput(inputId = "BANKSYlambda", label = "lambda : Influence of the neighborhood. Larger values yield more spatially coherent domains. Controls the balance between gene expression and spatial information. 0.2 for cell-typing, 0.8 for zone-finding.",   min = 0, max = 1, value = 0.8, step = 0.05),
                        checkboxInput("BANKSYfeatures", label="Compute all genes for downstream analysis?", value = FALSE),

                    actionButton(inputId = "RunBANKSY", label = "Perform BANKSY clustering"),

                     ))),

                  # UI部分 - "Spatial subsetting" タブ内に統合
tabPanel("Spatial subsetting", fluidRow(
  box(width = 3, status = "info", solidHeader = TRUE, title = "Subsetting",
     # ステップ1: 画像表示ボタン
     actionButton(inputId = "ShowSpatialImage", label = "Show image", class = "btn btn-info"),
     
     tags$hr(),
     # ステップ2: 座標入力
     sliderInput("spatial_x_min", "X min:", value = 0, min=0, max=1000),
     sliderInput("spatial_x_max", "X max:", value = 1000, min=0, max=1000),
     sliderInput("spatial_y_min", "Y min:", value = 0, min=0, max=1000),
     sliderInput("spatial_y_max", "Y max:", value = 1000, min=0, max=1000),
     checkboxInput("FlipXY", "Flip XY axes", value=TRUE),
     tags$h5("If the subsetting direction is incorrect, deselect this option."),
     
     tags$hr(),
     br(), br(),
     actionButton("spatial_preview_subsetting", "Preview subestting", class= "btn btn-info"),
            tags$br(),
     tags$hr(),
     tags$br(),
     actionButton("spatial_confirm_subsetting", "Confirm subsetting", class = "btn btn-warning"),

  ), #box
  
  column(width = 9,
                plotOutput("spatial_plot", height = "600px"),
       tags$br(),
     tags$hr(),
     tags$br(),
     verbatimTextOutput("spatial_selection_info"),
     tags$br(),
     tags$hr(),
     tags$br(),

                plotOutput("subset_plot", height = "600px")
     
  ) #column
) #fluidrow
) #tabpanel




)),



      #---------------------------------HELP------------------------------------
      tabItem(tabName = "help",
              fluidRow(
                column(12,
                       tabsetPanel(
                         tabPanel("Examples",
                                  div(class = "div_container",
                                      examples_help
                                  ),
                         ),
                         tabPanel("Data Input",
                                  tabsetPanel(type = "tabs",
                                    tabPanel("scRNA-seq: count matrix input",
                                      br(),
                                      file_upload_tab_intro,
                                      file_upload_txt,
                                      br(),
                                      file_upload_tab_new_project
                                    ),
                                    tabPanel("scRNA-seq: 10x files input",
                                      br(),
                                      file_upload_tab_intro,
                                      file_upload_10x,
                                      br(),
                                      file_upload_tab_new_project
                                    ),
                                    tabPanel("scATAC-seq: arrow file input",
                                      br(),
                                      file_upload_tab_intro,
                                      file_upload_arrow,
                                      br(),
                                      file_upload_tab_new_project
                                    ),
                                    tabPanel("Metadata output",
                                              tabsetPanel(type = "tabs",
                                                            tabPanel("Metadata RNA",
                                                              br(),
                                                              file_upload_metadata_RNA
                                                            ),
                                                            tabPanel("Metadata ATAC",
                                                              br(),
                                                              file_upload_metadata_ATAC
                                                            )
                                                          )
                                             )
                                  )
                         ),
                         tabPanel("Quality Control",
                                  tabsetPanel(type = "tabs",
                                    tabPanel("scRNA-seq QC: prior-filtering",
                                             br(),
                                             qc_tab_intro,
                                             rna_qc
                                    ),
                                    tabPanel("scRNA-seq QC: post-filtering",
                                             br(),
                                             qc_tab_intro,
                                             rna_qc_pf
                                    ),
                                    tabPanel("scATAC-seq QC: soft-filtering",
                                      br(),
                                      qc_tab_intro,
                                      atac_qc
                                    )
                                  )
                         ),
                         tabPanel("Normalization",
                                  tabsetPanel(type = "tabs",
                                              tabPanel("Normalization and scaling options",
                                                       br(),
                                                       norm_tab_intro,
                                                       rna_normalization_param
                                              ),
                                              tabPanel("Most variable genes",
                                                       br(),
                                                       norm_tab_intro,
                                                       rna_normalization_output
                                              )
                                  )
                         ),
                         tabPanel("PCA/LSI",
                                  tabsetPanel(type = "tabs",
                                              tabPanel("scRNA-seq: Optimal number of PCs",
                                                       br(),
                                                       pca_tab_intro,
                                                       br(),
                                                       pca_optimal_pcs
                                              ),
                                              tabPanel("scRNA-seq: Exploration of PCs",
                                                       br(),
                                                       pca_tab_intro,
                                                       br(),
                                                       pca_explore_pcs
                                              ),
                                              tabPanel("scATAC-seq: LSI",
                                                       br(),
                                                       pca_tab_intro,
                                                       br(),
                                                       pca_lsi
                                              )
                                  )
                         ),
                         tabPanel("Clustering",
                                  tabsetPanel(type = "tabs",
                                              tabPanel("scRNA-seq: Clustering parameters",
                                                       br(),
                                                       clustering_tab_intro,
                                                       br(),
                                                       clustering_rna_input
                                              ),
                                              tabPanel("scRNA-seq: Clustering output",
                                                       br(),
                                                       clustering_tab_intro,
                                                       br(),
                                                       clustering_rna_output
                                              ),
                                              tabPanel("scATAC-seq: Clustering parameters",
                                                       br(),
                                                       clustering_tab_intro,
                                                       br(),
                                                       clustering_atac_input
                                              ),
                                              tabPanel("scATAC-seq: Clustering output",
                                                       br(),
                                                       clustering_tab_intro,
                                                       br(),
                                                       clustering_atac_output
                                              )
                                  )

                         ),
                         tabPanel("UMAP etc",
                                  tabsetPanel(type = "tabs",
                                              tabPanel("scRNA-seq: Input parameters",
                                                       br(),
                                                       umap_tab_intro,
                                                       br(),
                                                       umap_rna_input
                                              ),
                                              tabPanel("scRNA-seq: Visualization",
                                                       br(),
                                                       umap_tab_intro,
                                                       br(),
                                                       umap_rna_output
                                              ),
                                              tabPanel("scATAC-seq: Input parameters",
                                                       br(),
                                                       umap_tab_intro,
                                                       br(),
                                                       umap_atac_input
                                              ),
                                              tabPanel("scATAC-seq: Visualization",
                                                       br(),
                                                       umap_tab_intro,
                                                       br(),
                                                       umap_atac_output
                                              )
                                  )

                         ),
                         tabPanel("Markers identification analysis",
                                  tabsetPanel(type = "tabs",
                                              tabPanel("scRNA-seq: Marker genes",
                                                       br(),
                                                       dea_tab_intro,
                                                       br(),
                                                       dea_rna_input
                                              ),
                                              tabPanel("scRNA-seq: Feature and signature visualization",
                                                       br(),
                                                       dea_tab_intro,
                                                       br(),
                                                       dea_rna_signature
                                              ),
                                              tabPanel("scATAC-seq: Marker genes",
                                                       br(),
                                                       dea_tab_intro,
                                                       br(),
                                                       dea_atac_genes
                                              ),
                                              tabPanel("scATAC-seq: Marker peaks",
                                                       br(),
                                                       dea_tab_intro,
                                                       br(),
                                                       dea_atac_peaks
                                              ),
                                              tabPanel("scATAC-seq: Gene activity score",
                                                       br(),
                                                       dea_tab_intro,
                                                       br(),
                                                       dea_atac_activity
                                              )
                                  )

                         ),


                         tabPanel("Cell Cycle phase",
                                  br(),
                                  cellCycle_tab_intro,
                                  br(),
                                  cell_cycle_rna
                         ),
                         tabPanel("Functional/Motif Enrichment",
                                  tabsetPanel(type = "tabs",
                                              tabPanel("scRNA-seq: Functional enrichment analysis",
                                                br(),
                                                functional_tab_intro,
                                                br(),
                                                grpofiler_tab_rna
                                              ),
                                              tabPanel("scATAC-seq: Motif enrichment analysis",
                                                br(),
                                                functional_tab_intro,
                                                br(),
                                                motif_tab_atac
                                              )
                                            )
                         ),
                         tabPanel("Cluster Annotation",
                                  br(),
                                  annot_tab_intro,
                                  br(),
                                  annot_cipr_rna
                         ),
                         tabPanel("Trajectory Inference",
                                  tabsetPanel(type = "tabs",
                                              tabPanel("scRNA-seq: Trajectory inference analysis",
                                                       br(),
                                                       traj_tab_intro,
                                                       br(),
                                                       traj_rna_slingshot
                                              ),
                                              tabPanel("scATAC-seq: Trajectory inference analysis",
                                                       br(),
                                                       traj_tab_intro,
                                                       br(),
                                                       traj_atac_slingshot
                                              )
                                  )
                         ),
                         tabPanel("Ligand-Receptor Analysis",
                                 br(),
                                 lr_tab_intro,
                                 br(),
                                 lr_rna_nichnet
                         ),
                         tabPanel("Gene regulatory networks analysis",
                                  tabsetPanel(type="tabs",
                                    tabPanel("scRNA-seq: GRN inference analysis",
                                             br(),
                                             grn_tab_intro,
                                             br(),
                                             grn_tab_rna
                                    ),
                                    tabPanel("scATAC-seq: GRN inference analysis",
                                             br(),
                                             grn_tab_intro,
                                             br(),
                                             grn_tab_atac
                                    )
                                  )
                         ),
                         tabPanel("Tracks",
                                  br(),
                                  tracks_tab_intro,
                                  br(),
                                  tracks_tab_atac
                                  )
                       )
                )
              ) #fluidRow end
      ),

      tabItem (tabName = "about",
               div(id = "about_div", class = "div_container",
                   h1(class = "container_title", "About SCALA"),
                   HTML("
                              <hr>
                              <h2 class=sub_title> Research team </h2>
                              <ul>
                              <li> Christos Tzaferis, tzaferis[at]fleming[dot]com
                              <li> Evangelos Karatzas, karatzas[at]fleming[dot]gr
                              <li> Fotis Baltoumas, baltoumas[at]fleming[dot]gr
                              <li> Georgios A. Pavlopoulos, pavlopoulos[at]fleming[dot]gr
                              <li> George Kollias, kollias[at]fleming[dot]gr
                              <li> Dimitris Konstantopoulos, konstantopoulos[at]fleming[dot]gr
                              </ul>
                              <footer>

                              <h2 class=sub_title> Developers </h2>
                              <ul>
                                <li> Christos Tzaferis, tzaferis[at]fleming[dot]com
                                <li> Dimitris Konstantopoulos, konstantopoulos[at]fleming[dot]gr
                              </ul>

                              <h3 class=sub_title>Code Availability</h3>
                              <p>The source code for SCALA can be found in <a href='https://github.com/PavlopoulosLab/SCALA/' target='_blank'>this</a> repository.</p>

                              <h3 class=sub_title> Cite SCALA </h3>
                              <p style='font-size:15px'>If you find SCALA useful in your work please cite: </br>Tzaferis C., Karatzas E., Baltoumas F.A., Pavlopoulos G.A.,
                              Kollias G., Konstantopoulos D. (2022) <b>SCALA: A web application for multimodal analysis of single cell next generation sequencing data.</b>
                              <i>bioRxiv 2022.11.24.517826; doi: <a href='https://doi.org/10.1101/2022.11.24.517826' target='_blank'>https://doi.org/10.1101/2022.11.24.517826</a></i></p>

                              &copy;"),
                              sprintf("%s", YEAR),
                              HTML("
                              <a href=\"https://fleming.gr/kollias-lab-single-cell-analysis-unit\" target=\"_blank\">Single Cell Analysis Unit</a> |
                              <a href=\"https://sites.google.com/site/pavlopoulossite\" target=\"_blank\">Bioinformatics and Integrative Biology Lab</a> |
                              <a href=\"https://www.fleming.gr\" target=\"_blank\">Biomedical Sciences Research Center \"Alexander Fleming\"</a>
                              </footer>"
                                   )
                   )
               )
      )

    )# tab item list
  )

ui_secure = secure_app(ui)