source("code/0-functions.R")


# COREKEY -----------------------------------------------------------------
process_corekey = function(corekey){
  corekey %>% 
  dplyr::select(sample_id, horizon, treatment, ftc) %>% 
  distinct()
}

#
# TC-TN -------------------------------------------------------------------
process_tctn = function(tctn, corekey_processed){
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

make_graphs_din = function(){
  din_processed %>% 
    ggplot(aes(x = treatment, y = nh4n_mg_kg, color = as.character(ftc), shape = time))+
    geom_point(position = position_dodge(width = 0.4))+
    facet_wrap(~horizon, scales = "free_y")+
    theme_kp()+
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

make_graphs_weoc = function(){
  weoc_processed %>% 
    ggplot(aes(x = treatment, y = weoc_mg_kg, color = as.character(ftc), shape = time))+
    geom_point(position = position_dodge(width = 0.4))+
    facet_wrap(~horizon, scales = "free_y")+
    theme_kp()+
    NULL  
  
  weoc_processed %>% 
    ggplot(aes(x = treatment, y = suva_L_mg_m, color = as.character(ftc), shape = time))+
    geom_point(position = position_dodge(width = 0.4))+
    facet_wrap(~horizon)+
    theme_kp()+
    NULL  
}

compute_stats_weoc = function(){
  summary(aov((weoc_mg_kg) ~ ftc, data = weoc_processed %>% filter(treatment == "freeze-thaw" & horizon == "O" & time == "post-freeze")))
  summary(aov((suva_L_mg_m) ~ ftc, data = weoc_processed %>% filter(treatment == "freeze-thaw" & horizon == "O" & time == "post-freeze")))
}

