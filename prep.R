library(Hmisc)
library(tidyverse)
options(stringsAsFactors = FALSE)

dat = read_csv('data/federal_candidates_2018-07-22.csv') %>%
      # drop acclamation
      dplyr::group_by(province, riding, date) %>%
      dplyr::filter(!any(acclamation == 1)) %>%
      dplyr::ungroup() %>%
      # woman dummy
      dplyr::mutate(woman = as.numeric(gender == 'F')) %>%
      # number of candidates and average vote share
      dplyr::group_by(province, riding, date) %>%
      dplyr::mutate(n_candidates = n()) %>%
      dplyr::ungroup() %>%
      dplyr::group_by(date) %>%
      dplyr::mutate(n_candidates = mean(n_candidates),
                    vote_share_avg = mean(vote_share)) %>%
      dplyr::ungroup() %>%
      # combine multiple candidates per party
      dplyr::arrange(province, riding, party, date) %>%
      # distance from contention
      dplyr::group_by(province, riding, date) %>%
      dplyr::mutate(contention = max(vote_share, na.rm = TRUE) - vote_share) %>%
      dplyr::ungroup() %>%
      # drop by-elections
      dplyr::filter(general_election == 1) %>%
      # party/riding-level variables
      dplyr::group_by(province, riding, party, date) %>%
      dplyr::summarize(woman = mean(woman),
                       elected = mean(elected),
                       elected = ifelse(elected %in% 0:1, elected, NA),
                       vote_share = sum(vote_share), 
                       incumbent_party = as.numeric(any(incumbent == 1)),
                       contention = min(contention),
                       n_candidates = unique(n_candidates),
                       vote_share_avg = unique(vote_share_avg)) %>%
      dplyr::ungroup() %>%
      # average vote share by party, province, election
      dplyr::group_by(party, province, date) %>%
      dplyr::mutate(party_province_date_vote_share = mean(vote_share)) %>%
      dplyr::ungroup() %>%
      # lags
      dplyr::arrange(province, riding, party, date) %>%
      dplyr::group_by(province, riding, party) %>%
      dplyr::mutate(vote_share_lag = Hmisc::Lag(vote_share),
                    contention_lag = Hmisc::Lag(contention)) %>%
      dplyr::ungroup() %>%
      # start when women were first candidates (do this after lags)
      dplyr::filter(date >= '1921-12-06') %>%
      # fixed effects index and numeric time
      dplyr::mutate(province_riding_party = paste(province, riding, party),
                    time = as.numeric(date),
                    year = lubridate::year(date),
                    #date01 = ifelse(date >= '1946-01-01', date, NA),
                    date_factor = as.numeric(as.factor((date))))

dat %>% write_csv(paste0('data/cjps_replication_', Sys.Date(), '.csv'), na = '')
