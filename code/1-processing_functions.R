

# COREKEY -----------------------------------------------------------------
process_corekey = function(corekey){
  corekey %>% 
  dplyr::select(sample_id, horizon, treatment, ftc) %>% 
  distinct()
}

#
# TC-TN -------------------------------------------------------------------
process_tctn = function(tctn, tctn_key, corekey_processed){
  tctn %>% 
  mutate(tctn_id = str_remove(tctn_id, "-")) %>% 
  left_join(tctn_key) %>% 
  left_join(corekey_processed) %>% 
  filter(is.na(skip))
}

make_graphs_tctn = function(tctn_processed){
  gg_tc = 
    tctn_processed %>% 
    mutate(ftc = replace_na(ftc, "control")) %>% 
    ggplot(aes(x = treatment, y = tc_perc, color = as.character(ftc))) +
    geom_point(size = 3, position = position_dodge(width = 0.4))+
    scale_color_manual(values = pnw_palette("Sunset",4))+
    facet_wrap(~reorder(horizon, desc(horizon)), scales = "free_y")+
    theme_kp()+
    labs(x = "", color = "FTC count", shape = "",
         subtitle = "post-incubation data only")+
    NULL  
  
  gg_tn = 
    tctn_processed %>% 
    mutate(ftc = replace_na(ftc, "control")) %>% 
    ggplot(aes(x = treatment, y = tn_perc, color = as.character(ftc))) +
    geom_point(size = 3, position = position_dodge(width = 0.4))+
    scale_color_manual(values = pnw_palette("Sunset",4))+
    facet_wrap(~reorder(horizon, desc(horizon)), scales = "free_y")+
    theme_kp()+
    labs(x = "", color = "FTC count", shape = "",
         subtitle = "post-incubation data only")+
    NULL 
  
  list(gg_tc = gg_tc,
       gg_tn = gg_tn)
}
compute_stats_tctn = function(){
  summary(aov(tc_perc ~ ftc, data = tctn_processed %>% filter(treatment  == "freeze-thaw" & horizon == "O")))
  summary(aov(tc_perc ~ treatment, data = tctn_processed %>% filter(horizon == "B")))
  ## no significant difference in control vs. freeze-thaw or by ftc count
}


#
# NH4-N -------------------------------------------------------------------
process_din = function(din, din_weights, corekey_processed){
  din_blank = 
    din %>% 
    filter(sample_id == "Filter Blank") %>% 
    pull(nh4_n_mg_l) %>% 
    mean(.)
  
  din_blank_corr = 
    din %>% 
    mutate(nh4_mgl = nh4_n_mg_l - din_blank) %>% 
    dplyr::select(time, sample_id, nh4_mgl) 
  
  din_blank_corr %>% 
    left_join(corekey_processed) %>% 
    filter(!is.na(treatment)) %>% 
    left_join(din_weights) %>% 
    mutate(od_soil_g = round(fm_soil_g/((moisture_perc/100)+1), 2),
           soil_water_g = fm_soil_g - od_soil_g,
           nh4n_mg_kg =  round(nh4_mgl * (100 + soil_water_g)/od_soil_g,2))
}

make_graphs_din = function(din_processed){
  din_processed %>% 
    mutate(ftc = replace_na(ftc, "control")) %>% 
    ggplot(aes(x = time, y = nh4n_mg_kg, color = as.character(ftc), shape = treatment))+
    geom_point(size = 3, position = position_dodge(width = 0.4))+
    scale_color_manual(values = pnw_palette("Sunset",4))+
    facet_wrap(~reorder(horizon, desc(horizon)), scales = "free_y")+
    theme_kp()+
    labs(x = "", color = "FTC count", shape = "")+
    NULL  
}


#
# WEOC --------------------------------------------------------------------
process_weoc = function(weoc, weoc_weights, corekey_processed){
  weoc %>% 
    left_join(corekey_processed) %>% 
    filter(!is.na(treatment)) %>% 
    left_join(weoc_weights) %>% 
    mutate(npoc_dil = npoc_mg_L * doc_dilution,
           od_soil_g = round(fm_soil_g/((moisture_perc/100)+1), 2),
           soil_water_g = fm_soil_g - od_soil_g,
           weoc_mg_kg =  round(npoc_dil * (50 + soil_water_g)/(od_soil_g),2),
           doc_suva = npoc_mg_L/uv_dilution,
           abs280_m_1 = abs280_cm_1 * 100,
           suva_L_mg_m = round(abs280_m_1/doc_suva,2)) %>% 
    dplyr::select(time, sample_id, horizon, treatment, ftc, weoc_mg_kg, suva_L_mg_m)
}

make_graphs_weoc = function(weoc_processed){
  (gg_weoc = 
    weoc_processed %>% 
    mutate(ftc = replace_na(ftc, "Control")) %>% 
    ggplot(aes(x = time, y = weoc_mg_kg, color = as.character(ftc), shape = treatment))+
    geom_point(size = 3, position = position_dodge(width = 0.4))+
    scale_color_manual(values = pnw_palette("Sunset",4),
                       labels = c("FTC-1", "FTC-2", "FTC-6", "control"))+
    facet_wrap(~reorder(horizon, desc(horizon)), scales = "free_y")+
    labs(y = expression(bold("WEOC, mg kg"^-1)))+
     scale_x_discrete(breaks = c("initial", "post-freeze"),
                      labels = c("pre-incubation", "post-incubation"))+
    theme_kp()+
    labs(x = "", color = "FTC count", shape = "")+
     guides(shape = guide_legend(order = 1),
            color = guide_legend(order = 2))+
    NULL)   
  
  gg_suva = 
    weoc_processed %>% 
    mutate(ftc = replace_na(ftc, "control")) %>% 
    ggplot(aes(x = time, y = suva_L_mg_m, color = as.character(ftc), shape = treatment))+
    geom_point(size = 3, position = position_dodge(width = 0.4))+
    scale_color_manual(values = pnw_palette("Sunset",4))+
    facet_wrap(~reorder(horizon, desc(horizon)), scales = "free_y")+
    theme_kp()+
    labs(x = "", color = "FTC count", shape = "")+
    NULL  
  
  list(gg_weoc = gg_weoc,
       gg_suva = gg_suva)
}

compute_stats_weoc = function(){
  summary(aov((weoc_mg_kg) ~ ftc, data = weoc_processed %>% filter(treatment == "freeze-thaw" & horizon == "O" & time == "post-freeze")))
  summary(aov((suva_L_mg_m) ~ ftc, data = weoc_processed %>% filter(treatment == "freeze-thaw" & horizon == "O" & time == "post-freeze")))
}


#
# RESPIRATION -------------------------------------------------------------
process_respiration = function(respiration, respiration_headspace, corekey_processed){
  compute_slope = function(dat){
    lm(CO2_moles_per_mL ~ timepoint_min, data = dat) %>% 
      broom::tidy() %>% 
      filter(term == "timepoint_min") %>% 
      dplyr::select(estimate) %>% 
      rename(slope_moles_mL_min = estimate) %>% 
      mutate(slope_moles_mL_min = round(slope_moles_mL_min, 4))
  }
  # AREA = 0.01 # m2

  respiration_slope = 
    respiration %>% 
    filter(!is.na(CO2_moles_per_mL)) %>% 
    group_by(time, sample_id, notes1, notes2) %>% 
    do(compute_slope(.)) %>% 
    filter(slope_moles_mL_min > 0)
    
  respiration_slope %>% 
    left_join(respiration_headspace) %>% 
    mutate(flux_moles_hr = 60 * slope_moles_mL_min * (headspace_mL/1000),
           flux_moles_g_hr = flux_moles_hr/od_soil_g,
           flux_mmoles_g_hr = flux_moles_g_hr * 1000,
           flux_mgC_g_hr = flux_mmoles_g_hr * 12) %>% 
    left_join(corekey_processed)
  
}


make_graphs_respiration = function(respiration_processed){
  resp_graph_label = 
    tribble(
      ~x, ~y, ~horizon, ~label,
      3.5, 35, "O", "FTC-incubation",
      7, 35, "O", "post-incubation",
      1, -0.5, "B", "day0",
      2, -0.5, "B", "day10",
      6, -0.5, "B", "day50",
    )
  
  gg_resp_ftc6 =
    respiration_processed %>% 
    mutate(time = recode(time, "post-freeze-0hr" = "0hr", "post-freeze-6hr" = "6hr", "post-freeze-24hr" = "24hr"),
           time = factor(time, levels = c("initial", "thaw1", "thaw3", "thaw5", "thaw6", "0hr", "6hr", "24hr"))) %>% 
    filter(treatment == "control" | ftc == 6) %>% 
    ggplot(aes(x = time, y = flux_mgC_g_hr, color = treatment))+
    geom_point(size = 2, position = position_dodge(width = 0.5), aes(shape = treatment))+
    geom_vline(xintercept = 1.5, linetype = "dashed")+
    geom_vline(xintercept = 5.5, linetype = "dashed")+
    geom_text(data = resp_graph_label, aes(x = x, y = y, label = label), color = "black", size = 3)+
    scale_color_manual(values = (soil_palette("redox",2)))+
    scale_shape_manual(values = c(1, 19))+
    labs(x = "")+
    facet_grid(reorder(horizon, desc(horizon)) ~., scales = "free_y")+
    theme_kp()+
    NULL
  
  gg_resp = 
    respiration_processed %>% 
    filter(is.na(notes1)) %>% 
    mutate(ftc = replace_na(ftc, "control")) %>% 
    ggplot(aes(x = time, y = flux_mgC_g_hr, color = as.character(ftc), shape = treatment))+
    geom_point(size = 3, position = position_dodge(width = 0.4))+
    scale_color_manual(values = pnw_palette("Sunset",4))+
    facet_wrap(~reorder(horizon, desc(horizon)), scales = "free_y")+
    theme_kp()+
    labs(x = "", color = "FTC count", shape = "")+
    NULL   
  
  list(gg_resp = gg_resp,
       gg_resp_ftc6 = gg_resp_ftc6)
  
}
misc_resp = function(){
  
  respiration %>%
    filter(grepl("OTB", sample_id)) %>% 
    filter(time == "thaw6") %>% 
    ggplot(aes(x = timepoint_min, y = CO2_moles_per_mL))+
    geom_point()+
    geom_smooth(method = "lm", se = FALSE)+
    facet_wrap(~ time + sample_id)+
    theme_kp()+
    NULL
  
  
  respiration_processed %>% 
    filter(is.na(notes1)) %>% 
    ggplot(aes(x = time, y = flux_mgC_g_hr, color = as.character(ftc)))+
    geom_point(position = position_dodge(width = 0.5))+
    facet_grid(horizon ~., scales = "free_y")+
    theme_kp()+
    NULL
  
  
}

# combine all -------------------------------------------------------------

combine_all_data = function(tctn_processed, din_processed, weoc_processed, respiration_processed, corekey_processed){
  tctn_1 = 
    tctn_processed %>% 
    dplyr::select(time, sample_id, tc_perc, tn_perc) %>% 
    pivot_longer(-c(time, sample_id), names_to = "variable")
  
  din_1 = 
    din_processed %>% 
    dplyr::select(time, sample_id, nh4n_mg_kg) %>% 
    rename(value = nh4n_mg_kg) %>% 
    mutate(variable = "nh4_mg_kg") %>% 
    dplyr::select(time, sample_id, variable, value)
  
  weoc_1 = 
    weoc_processed %>% 
    dplyr::select(time, sample_id, weoc_mg_kg, suva_L_mg_m) %>% 
    pivot_longer(-c(time, sample_id), names_to = "variable")
  
  resp_1 = 
    respiration_processed %>% 
    filter(is.na(notes1)) %>% 
    ungroup() %>% 
    dplyr::select(time, sample_id, flux_mgC_g_hr) %>% 
    rename(value = flux_mgC_g_hr) %>% 
    mutate(variable = "flux_mgC_g_hr", 
           value = round(value, 2),
           time = recode(time, "post-freeze-6hr" = "post-freeze")) %>% 
    dplyr::select(time, sample_id, variable, value)
  
  bind_rows(tctn_1, din_1, weoc_1, resp_1) %>% 
    left_join(corekey_processed)
}
compute_summaries = function(combined){

# ftc summary -- effect of ftc frequency ----------------------------------
  do_aov2 = function(dat){
    aov(value ~ ftc, data = dat) %>% 
      broom::tidy() %>% 
      filter(term == "ftc") %>% 
      rename(p_value = `p.value`) %>% 
      dplyr::select(statistic, p_value) %>% 
      mutate(statistic = round(statistic, 2),
             p_value = round(p_value, 3))
  }
  stats_ftc = 
    combined %>% 
    filter(time == "post-freeze" & treatment == "freeze-thaw") %>% 
    group_by(time, horizon, variable) %>% 
    do(do_aov2(.)) 
  
  ftc_summary = 
    combined %>% 
    filter(time == "post-freeze" & treatment == "freeze-thaw") %>% 
    group_by(time, horizon, variable, ftc) %>% 
    dplyr::summarise(mean  = mean(value),
                     se = sd(value)/sqrt(n()),
                     mean_se = paste(round(mean, 2), "\u00b1", round(se, 2))) %>% 
    mutate(ftc = paste0("ftc-", ftc)) %>% 
    dplyr::select(-mean, -se) %>% 
    pivot_wider(names_from = "ftc", values_from = "mean_se") %>% 
    left_join(stats_ftc) %>% knitr::kable()
  

# ftc vs. control ---------------------------------------------------------
stats_aov_control_vs_ftc = function(){
  do_aov1 = function(dat){
    aov(value ~ treatment, data = dat) %>% 
      broom::tidy() %>% 
      filter(term == "treatment") %>% 
      rename(p_value = `p.value`) %>% 
      dplyr::select(statistic, p_value) %>% 
      mutate(statistic = round(statistic, 2),
             p_value = round(p_value, 3))
  }
  stats_control_vs_ftc = 
    combined %>% 
    filter(time == "post-freeze") %>%
    group_by(time, horizon, variable) %>% 
    do(do_aov1(.))
}
stats_hsd_control_vs_ftc = function(){
  do_hsd = function(dat){
    a = aov((value) ~ trt, data = dat) 
    h = HSD.test(a, "trt")
    h$groups %>% 
      rownames_to_column("trt") %>% 
      dplyr::select(trt, groups) %>% 
      pivot_wider(values_from = "groups", names_from = "trt")
      
  }
  stats_control_vs_ftc = 
    incubation_combined %>% 
    group_by(horizon, variable) %>% 
    do(do_hsd(.))
  
}  
  
  incubation_initial = 
    combined %>% 
    filter(time == "initial") %>% 
    rename(trt = time)
  incubation_final = 
    combined %>% 
    filter(time == "post-freeze") %>% 
    rename(trt = treatment)
  
  incubation_combined = 
    bind_rows(incubation_initial, incubation_final)
    
  
  group_by(horizon, variable, time) %>% 
    dplyr::summarise(mean  = mean(value),
                     se = sd(value)/sqrt(n()),
                     mean_se = paste(round(mean, 2), "\u00b1", round(se, 2)))

  incubation_summary_final = 
    combined %>% 
    filter(time == "post-freeze") %>% 
    group_by(horizon, variable, treatment) %>% 
    dplyr::summarise(mean  = mean(value),
                     se = sd(value)/sqrt(n()),
                     mean_se = paste(round(mean, 2), "\u00b1", round(se, 2))) %>% 
    rename(trt = treatment)
    
  incubation_summary = 
    incubation_combined %>% 
    group_by(horizon, variable, trt) %>% 
    dplyr::summarise(mean  = mean(value),
                     se = sd(value)/sqrt(n()),
                     mean_se = paste(round(mean, 2), "\u00b1", round(se, 2))) %>% 
    
    dplyr::select(-mean, -se) %>% 
    pivot_wider(names_from = "trt", values_from = "mean_se") %>% knitr::kable()
  

    
   

}


aov(nh4n_mg_kg ~ as.character(ftc),
 data = 
  din_processed %>% 
  filter(time == "post-freeze" & treatment == "freeze-thaw" & horizon == "B")
) %>% summary()


  din_processed %>% 
  filter(time == "post-freeze") %>% 
  ungroup() %>% 
  group_by(horizon, treatment) %>% 
  dplyr::summarize(mean = mean(moisture_perc))
