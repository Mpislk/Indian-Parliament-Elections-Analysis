create database Codebasics11
use Codebasics11

select * from data14
select * from data19

-- (1) List top/ bottom 5 constituencies of 2014 and 2019 in terms of voter turnout ratio

-- top 5 constituencies of 2014
-- using CTE
with cte as 
(select pc_name, state, SUM(total_votes) polled_votes, avg(total_electors) total_electors from data14
group by pc_name, state)
select top 8 *, 100*cte.polled_votes/cte.total_electors voter_turnout_ratio from cte
order by voter_turnout_ratio desc, total_electors desc;

-- bottom 5 constituencies of 2014
with cte as 
(select pc_name, state, SUM(total_votes) polled_votes, avg(total_electors) total_electors from data14
group by pc_name, state)
select top 5 *, 100*cte.polled_votes/cte.total_electors voter_turnout_ratio from cte
order by voter_turnout_ratio, total_electors

-- top 5 constituencies of 2019
with cte as 
(select pc_name, state, SUM(total_votes) polled_votes, avg(total_electors) total_electors from data19
group by pc_name, state)
select top 8 *, 100*cte.polled_votes/cte.total_electors voter_turnout_ratio from cte
order by voter_turnout_ratio desc, total_electors desc;

-- bottom 5 constituencies of 2019
with cte as 
(select pc_name, state, SUM(total_votes) polled_votes, avg(total_electors) total_electors from data19
group by pc_name, state)
select top 5 *, 100*cte.polled_votes/cte.total_electors voter_turnout_ratio from cte
order by voter_turnout_ratio, total_electors

-- (2) List top/ bottom 5 states of 2014 and 2019 in terms of voter turnout ratio
ALTER TABLE data14
ALTER COLUMN total_votes BIGINT; -- to prevent arithmetic overflow error
ALTER TABLE data14
ALTER COLUMN total_electors BIGINT;
 --2014
 -- top 5
with cte as
 (select pc_name, state, SUM(total_votes) total_polled, AVG(total_electors) total_electors from data14
 group by pc_name, state)
 select top 5 state, SUM(cte.total_polled) tot_polled, SUM(cte.total_electors) tot_electors, 
 100*sum(cte.total_polled)/sum(cte.total_electors) voter_turnout_ratio from cte 
 group by state
 order by voter_turnout_ratio desc;
 -- bottom 5
 with cte as
 (select pc_name, state, SUM(total_votes) total_polled, AVG(total_electors) total_electors from data14
 group by pc_name, state)
 select top 5 state, SUM(cte.total_polled) tot_polled, SUM(cte.total_electors) tot_electors, 
 100*sum(cte.total_polled)/sum(cte.total_electors) voter_turnout_ratio from cte 
 group by state
 order by voter_turnout_ratio

 --2019
ALTER TABLE data19
ALTER COLUMN total_votes BIGINT;
ALTER TABLE data19
ALTER COLUMN total_electors BIGINT;

with cte as
 (select pc_name, state, SUM(total_votes) total_polled, AVG(total_electors) total_electors from data19
 group by pc_name, state)
 select top 5 state, SUM(cte.total_polled) tot_polled, SUM(cte.total_electors) tot_electors, 
 100*sum(cte.total_polled)/sum(cte.total_electors) voter_turnout_ratio from cte 
 group by state
 order by voter_turnout_ratio desc;

with cte as
 (select pc_name, state, SUM(total_votes) total_polled, AVG(total_electors) total_electors from data19
 group by pc_name, state)
 select top 5 state, SUM(cte.total_polled) tot_polled, SUM(cte.total_electors) tot_electors, 
 100*sum(cte.total_polled)/sum(cte.total_electors) voter_turnout_ratio from cte 
 group by state
 order by voter_turnout_ratio 

-- (3) which constituencies have elected the same party for two consecutive elections,
-- rank them by vote % to the winning party in 2019
with cte1 as
(select  pc_name, state, party, total_votes, 100*total_votes/total_electors vote_percent, 
RANK() over (partition by pc_name order by total_votes desc) ranks from data14),
cte2 as
(select  pc_name, state, party, total_votes, 100*total_votes/total_electors vote_percent, 
RANK() over (partition by pc_name order by total_votes desc) ranks from data19)
select top 10 cte1.pc_name, cte1.state, cte1.party, cte1.vote_percent,
cte2.party, cte2.vote_percent,
DENSE_RANK() over (order by cte2.vote_percent desc) rank2
from cte1
join
cte2
on cte1.pc_name = cte2.pc_name
where (cte1.ranks =1 and cte2.ranks=1) and (cte1.party = cte2.party)

-- (4) which constituencies have elected the different party for two consecutive elections,
-- list top 10 based on difference (2019-2014) by winning vote %
with cte1 as
(select  pc_name, state, party, total_votes, 100*total_votes/total_electors vote_percent, 
  RANK() over (partition by pc_name order by total_votes desc) ranks from data14),
cte2 as
(select  pc_name, state, party, total_votes, 100*total_votes/total_electors vote_percent, 
  RANK() over (partition by pc_name order by total_votes desc) ranks from data19)
select top 10 cte1.pc_name, cte1.state, cte1.party, cte1.ranks, cte1.vote_percent,
cte2.party, cte2.ranks, cte2.vote_percent,
cte2.vote_percent - cte1.vote_percent precent_diff
from cte1
join
cte2
on cte1.pc_name = cte2.pc_name
where (cte1.ranks =1 and cte2.ranks=1) and (cte1.party <> cte2.party)
order by cte2.vote_percent - cte1.vote_percent desc

-- (5) Top 5 candidates based on margin difference with runners in 2014, 2019
with cte as
(select pc_name, candidate, total_votes,
DENSE_RANK() over (PARTITION by pc_name ORDER BY total_votes desc) ranking from data14)
select top 5 t1.pc_name, t1.candidate, t1.total_votes-t2.total_votes margin from cte t1
join
cte t2
on 1=1
where (t1.ranking =1 and t2.ranking=2) and t1.pc_name = t2.pc_name
order by margin desc

-- (6) party wise % vote split between 2014 and 2019 at national level   
select 2014 year, party,
100*SUM(total_votes)/(select SUM(total_votes) from data14) vote_percent from data14
group by party
order by vote_percent desc

select 2019 year, party, 
100*SUM(total_votes)/(select SUM(total_votes) from data14) vote_percent from data19
group by party
order by vote_percent desc;

-- (7) party wise % vote split between 2014 and 2019 at state level 
with cte1 as 
(select state, party, sum(total_votes) party_votes from data14
group by state, party),
cte2 as
(select state, SUM(total_votes) state_votes from data14
group by state)
select cte1.state, cte1.party, cte1.party_votes, cte2.state_votes, 100*cte1.party_votes/cte2.state_votes vote_percent 
from cte1
join cte2
on cte1.state = cte2.state
where  100*cte1.party_votes/cte2.state_votes > 5
order by state, vote_percent desc

-- (8) List 5 constituencies for 2 major national parties where they have gained vote share in 2019 compared to 2014 
select top 5 d14.pc_name, d14.party, d14.total_votes votes_14, d19.total_votes votes_19, 
d19.total_votes - d14.total_votes gain 
from data14 d14
join data19 d19
on (d14.pc_name = d19.pc_name) and (d14.party=d19.party)
where d14.party in ('BJP', 'INC')
order by gain desc;

-- (9) List 5 constituencies for 2 major national parties where they have lost vote share in 2019 compared to 2014 
select top 5 d14.pc_name, d14.party, d14.total_votes votes_14, d19.total_votes votes_19, 
d19.total_votes - d14.total_votes loss 
from data14 d14
join data19 d19
on (d14.pc_name = d19.pc_name) and (d14.party=d19.party)
where d14.party in ('BJP', 'INC')
order by loss

-- (10) which constituency has voted the most for NOTA
select top 3 pc_name, state, party, total_votes, total_electors, 
100*total_votes/total_electors nota_ratio from data14
where party = 'NOTA'
order by nota_ratio desc

select top 3 pc_name, state, party, total_votes, total_electors, 
100*total_votes/total_electors nota_ratio from data19
where party = 'NOTA'
order by total_votes desc

-- (11) which constituencies have elected candidates whose party has less than 10% vote share at state level in 2019  --incomplete
-- pc_name   candidate   party    vote_share_percent
WITH state_votes AS (
    SELECT  state, party, SUM(total_votes) AS party_votes, (SUM(total_votes) * 1.0) / SUM(SUM(total_votes)) OVER (PARTITION BY state) AS vote_share
    FROM data19
    GROUP BY state, party
),
constituency_winners AS (
    SELECT  pc_name, state, candidate, party, total_votes,  RANK() OVER (PARTITION BY pc_name ORDER BY total_votes DESC) AS rank
    FROM data19
)
SELECT
    cw.pc_name
FROM
    constituency_winners cw
JOIN state_votes sv ON cw.state = sv.state AND cw.party = sv.party
WHERE
    cw.rank = 1
    AND sv.vote_share < 0.10;

-- other insights
select * from data14

with cte as
(select SUM(avg(total_electors))
select 2014 year, SUM(total_votes) total_voted_14 from data14
union
select 2019 year, SUM(total_votes) total_votes_19 from data19
