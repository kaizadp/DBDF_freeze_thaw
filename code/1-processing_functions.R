

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

make_graphs_tctn = function(){
  tctn_processed %>% 
    ggplot(aes(x = treatment, y = tc_perc, color = as.character(ftc))) +
    geom_point(position = position_dodge(width = 0.4))+
    facet_wrap(~horizon, scales = "free_y")+
    theme_kp()+
    NULL
  
  tctn_processed %>% 
    ggplot(aes(x = treatment, y = tn_perc, color = as.character(ftc))) +
    geom_point(position = position_dodge(width = 0.4))+
    facet_wrap(~horizon, scales = "free_y")+
    theme_kp()+
    NULL
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
  gg_weoc = 
    weoc_processed %>% 
    mutate(ftc = replace_na(ftc, "control")) %>% 
    ggplot(aes(x = time, y = weoc_mg_kg, color = as.character(ftc), shape = treatment))+
    geom_point(size = 3, position = position_dodge(width = 0.4))+
    scale_color_manual(values = pnw_palette("Sunset",4))+
    facet_wrap(~reorder(horizon, desc(horizon)), scales = "free_y")+
    theme_kp()+
    labs(x = "", color = "FTC count", shape = "")+
    NULL   
  
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