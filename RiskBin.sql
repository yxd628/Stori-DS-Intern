--Risk Bin Reallocation for ECRM_V3
drop table if exists binned_ecrm_v3;
create temporary table binned_ecrm_v3 as
select appl_id,
case
	when (model_bin_ecrm_v3 is null or model_bin_ecrm_v3 = -1) then 'Bin 20'
	else 'Bin ' || CEIL(model_bin_ecrm_v3 / 5.0)::TEXT
end as risk_twentile_v3
from model_tables.ecrm_v3_bin;

select risk_twentile_v3, count(*) as count_v3
from binned_ecrm_v3 group by risk_twentile_v3
ORDER BY CAST(SUBSTRING(risk_twentile_v3 FROM 5) AS INTEGER);


--Risk Bin Reallocation for ECRM_V3 without -1 population
drop table if exists binned_ecrm_v3_g;
create temporary table binned_ecrm_v3_g as
select appl_id,
	'Bin ' || CEIL(model_bin_ecrm_v3 / 5.0)::TEXT
as risk_twentile_v3_g
from model_tables.ecrm_v3_bin
where model_bin_ecrm_v3 != -1;

select risk_twentile_v3_g, count(*) as count_v3_g
from binned_ecrm_v3_g group by risk_twentile_v3_g
ORDER BY CAST(SUBSTRING(risk_twentile_v3_g FROM 5) AS INTEGER);


--Risk Bin Reallocation for ECRM_V4
drop table if exists binned_ecrm_v4;
create temporary table binned_ecrm_v4 as
select appl_id,
case
	when (decisioning_bin is null or decisioning_bin = -1) then 'Bin 20'
	else 'Bin ' || CEIL(decisioning_bin / 5.0)::TEXT
end as risk_twentile_v4
from model_tables.ecrm_v4_bin;

select risk_twentile_v4, count(*) as count_v4
from binned_ecrm_v4 group by risk_twentile_v4
ORDER BY CAST(SUBSTRING(risk_twentile_v4 FROM 5) AS INTEGER);
