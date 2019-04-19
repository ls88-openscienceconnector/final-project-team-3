library(tidyverse)
library(showtext)
library(cowplot)
font_add('tnr', 'data/Times_New_Roman.ttf')
showtext_auto()

# Average Number of Candidates and Average Vote Share
dat = read_csv('data/cjps_replication_2018-07-22.csv')
datp = dat %>% 
       group_by(date) %>%
       summarize(`Average number of candidates per riding` = mean(n_candidates),
                 `Average vote share per candidate` = mean(vote_share_avg)) %>%
       gather(stat, value, -date)
p = ggplot(datp, aes(date, value)) +
    geom_line() +
    facet_wrap(~ stat, scales = 'free') +
    xlab('') + ylab('') +
    theme_bw() +
    #scale_x_date(breaks = seq(as.Date('1920'), as.Date('2000'), by = '30 years')) +
    scale_x_date(limits = c(as.Date('1920-01-01'), as.Date('2015-01-01'))) +
    theme(strip.background = element_blank(),
          text = element_text(family = 'tnr')) 
try(ggsave(p, file = 'txt/fig/candidates_per_riding.pdf', width = 7, height = 3))

# Women candidates + Women elected
dat = read_csv('data/cjps_replication_2018-07-22.csv')
datp = dat %>% 
       mutate(woman_elected = ifelse((woman == 1) & (elected == 1), 1, 0)) %>% 
       group_by(date) %>%
       summarize(`Share of candidates` = mean(woman),
                 `Share of elected candidates` = sum(woman_elected, na.rm = TRUE) / sum(elected, na.rm = TRUE)) %>%
       gather(stat, value, -date)
p = ggplot(datp, aes(date, value)) +
    geom_line() +
    facet_wrap(~ stat) +
    xlab('') + ylab('') +
    theme_bw() +
    #scale_x_date(breaks = seq(as.Date('1920'), as.Date('2000'), by = '30 years')) +
    scale_x_date(limits = c(as.Date('1920-01-01'), as.Date('2015-01-01'))) +
    theme(strip.background = element_blank(),
          text = element_text(family = 'tnr')) 
try(ggsave(p, file = 'txt/fig/gender_over_time.pdf', width = 7, height = 3))

# Vote Share 
datp = read_csv('data/cjps_replication_2018-07-22.csv') %>%
      mutate(gender = ifelse(woman > 0, 'Women', 'Men'))
a = ggplot(datp, aes(date, vote_share, linetype = gender)) + 
    geom_smooth(color = 'black', se = FALSE, method = 'loess', alpha = .2, size = 1) +
    theme_bw() +
    theme(strip.background = element_blank(),
          text = element_text(family = 'tnr'),
          legend.title = element_blank(),
          legend.position = 'bottom',
          legend.justification = 'left') +
    scale_x_date(limits = as.Date(c('1920-01-01','2010-01-01'))) +
    xlab('') +
    ylab('Average vote share') 
dat = read_delim('data/mfx_ols.csv', delim = '\t') %>%
      mutate(b = as.numeric(b),
             ll = as.numeric(ll),
             ul = as.numeric(ul),
             year = 1921:2015) %>%
      select(year, b, ll, ul)
b = ggplot(dat, aes(year, b)) +
    geom_line() +
    geom_line(aes(year, ll), linetype = 3, size = 1) +
    geom_line(aes(year, ul), linetype = 3, size = 1) +
    theme_bw() +
    theme(text = element_text(family = 'tnr')) +
    xlab('') +
    ylab("Marginal effect of woman on vote share\n(95% Confidence intervals)")
pdf('txt/fig/time_vote_share.pdf', width = 7, height= 3)
p = plot_grid(a + theme(legend.position = 'none'), b, align = 'v') 
plot_grid(p, get_legend(a), ncol = 1, rel_heights = c(1, .05), rel_widths = c(1, .1), axis = 'lb')
dev.off()

# Elected
datp = read_csv('data/cjps_replication_2018-07-22.csv') %>%
      mutate(gender = ifelse(woman > 0, 'Women', 'Men'))
a = ggplot(datp, aes(date, elected, linetype = gender)) + 
    geom_smooth(color = 'black', se = FALSE, method = 'loess', alpha = .2) +
    theme_bw() +
    theme(strip.background = element_blank(),
          text = element_text(family = 'tnr'),
          legend.title = element_blank(),
          legend.position = 'bottom',
          legend.justification = 'left') +
    xlab('') +
    ylab('Pr(Elected)') 
datp = read_delim('data/mfx_logit.csv', delim = '\t') %>%
       mutate(b = as.numeric(b),
              ll = as.numeric(ll),
              ul = as.numeric(ul),
              year = 1921:2015) %>%
       select(year, b, ll, ul)
b = ggplot(datp, aes(year, b)) +
    geom_line() +
    geom_line(aes(year, ll), linetype = 3) +
    geom_line(aes(year, ul), linetype = 3) +
    theme_bw() +
    theme(text = element_text(family = 'tnr')) +
    xlab('') +
    ylab("Marginal effect of woman on Pr(Elected)\n(95% Confidence intervals)")
pdf('txt/fig/time_elected.pdf', width = 7, height= 3)
p = plot_grid(a + theme(legend.position = 'none'), b, align = 'v') 
plot_grid(p, get_legend(a), ncol = 1, rel_heights = c(1, .05), rel_widths = c(1, .1), axis = 'lb')
dev.off()

# Provinces
p_alpha = c("AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YU")
p_geog = c("BC", "AB", "SK", "MB", "ON", "QC", "NB", "PE", "NS", "NL")
dat = read_delim('data/provinces.csv', delim = '\t') 
dat$X1[1:13] = p_alpha
dat = dat[1:13,] %>%
      rename(province = X1) %>%
      mutate(b = as.numeric(b),
             se = as.numeric(se),
             ll = b + qnorm(.005) * se,
             ul = b - qnorm(.005) * se) %>%
      select(province, b, ll, ul) %>%
      filter(province %in% p_geog) %>%
      mutate(province = as_factor(province),
             province = fct_relevel(province, p_geog))

p = ggplot(dat) + 
    geom_linerange(aes(province, ymin = ll, ymax = ul)) +
    geom_hline(yintercept = 0) +
    xlab('') +
    ylab('Marginal effect of "woman" on vote share') +
    theme_bw() +
    theme(text = element_text(family = 'tnr'),
          panel.grid = element_blank(),
          panel.border = element_blank()) +
    scale_color_grey()

pdf('txt/fig/provinces.pdf', width = 4, height= 3)
p
dev.off()
