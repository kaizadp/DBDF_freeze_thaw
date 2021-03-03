source("code/0-functions.R")
source("code/1-processing_functions.R")

ftc_plan = 
  drake_plan(
    # corekey -----------------------------------------------------------------
    corekey = read.csv("data/corekey.csv"),
    corekey_processed = process_corekey(corekey),
    
    # TC-TN -------------------------------------------------------------------
    tctn = read.csv("data/total_cn.csv"),
    tctn_key = read.csv("data/total_cn_key.csv", na.strings = ""),
    tctn_processed = process_tctn(tctn, tctn_key, corekey_processed),
    
    #
    # extractable inorganic N -------------------------------------------------
    din = read.csv("data/extractable_n.csv"),
    din_weights = read.csv("data/extractable_n_weights.csv"),
    din_processed = process_din(din, din_weights, corekey_processed),
    nh4_graph = make_graphs_din(din_processed),
    
    # organic C ---------------------------------------------------------------
    weoc = read.csv("data/weoc.csv"),
    weoc_weights = read.csv("data/weoc_weights.csv"),
    weoc_processed = process_weoc(weoc, weoc_weights, corekey_processed),
    weoc_graphs = make_graphs_weoc(weoc_processed),
    
    # respiration -------------------------------------------------------------
    respiration = read.csv("data/respiration.csv", na.strings = ""),
    respiration_headspace = read.csv("data/respiration_headspace.csv") %>% filter(time == "initial") %>% dplyr::select(-time),
    respiration_processed = process_respiration(respiration, respiration_headspace, corekey_processed),
    respiration_graphs = make_graphs_respiration(respiration_processed),
    
    
    # report ------------------------------------------------------------------
    report = rmarkdown::render(
      knitr_in("reports/dbdf_ftc_report.Rmd"),
      output_format = rmarkdown::github_document()), quiet = T
  )


make(ftc_plan)
loadd(tctn_processed, din_processed, weoc_processed, respiration_processed)
