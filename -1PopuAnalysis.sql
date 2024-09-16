--Make analysis on v3 bins, the vintage, delinquentm, and account status for those -1 clients
DROP TABLE IF EXISTS negative_one_user_data;
CREATE TEMPORARY TABLE negative_one_user_data AS
SELECT DISTINCT evb3.appl_id, evb3.user_id, scdl2.vintage, scdl2.delinq_status, scdl2.acct_status_desc, evb4.decisioning_bin
FROM model_tables.ecrm_v3_bin AS evb3
LEFT JOIN (
    SELECT user_id, vintage, delinq_status, acct_status_desc
    FROM stori_ccm_pl.stori_cc_daily_ledger_v2
    WHERE (user_id, snap_dt) IN (
        SELECT user_id, MAX(snap_dt) AS snap_dt
        FROM stori_ccm_pl.stori_cc_daily_ledger_v2
        GROUP BY user_id)
) AS scdl2
ON evb3.user_id = scdl2.user_id
LEFT JOIN model_tables.ecrm_v4_bin AS evb4
ON evb3.appl_id = evb4.appl_id
WHERE evb3.model_bin_ecrm_v3 = -1
ORDER BY evb3.appl_id;

--Analyze the number of customers gained risk score in v4
SELECT
	COUNT(CASE WHEN decisioning_bin IS NOT NULL THEN 1 END) AS risk_score_user,
	COUNT(CASE WHEN decisioning_bin IS NULL THEN 1 END) AS non_risk_score_user
FROM negative_one_user_data;

--Analyze vintage
SELECT vintage,COUNT(*) AS customer_count
FROM negative_one_user_data
WHERE vintage IS NOT NULL
GROUP BY vintage
ORDER BY vintage;

--Analyze Delinquent Status
SELECT delinq_status,COUNT(*) AS customer_delinq_status
FROM negative_one_user_data
WHERE delinq_status IS NOT NULL
GROUP BY delinq_status
ORDER BY 
    CASE 
        WHEN delinq_status = 'Current' THEN 1
        WHEN delinq_status = 'DQ 1-30' THEN 2
        WHEN delinq_status = 'DQ 31-60' THEN 3
        WHEN delinq_status = 'DQ 61-90' THEN 4
        WHEN delinq_status = 'DQ 91-120' THEN 5
        WHEN delinq_status = 'DQ 121-150' THEN 6
        WHEN delinq_status = 'DQ 151-180' THEN 7
        WHEN delinq_status = 'DQ 181-210' THEN 8
        WHEN delinq_status = 'DQ 210+' THEN 9
        
    END;

--Analyze Account Status
SELECT acct_status_desc,COUNT(*) AS customer_chargeoff_status
FROM negative_one_user_data
WHERE acct_status_desc IS NOT NULL
GROUP BY acct_status_desc
ORDER BY acct_status_desc;

--Counting the populations of risk bin change in <0, =0, and >0 criteria(-1 population included)
SELECT
    SUM(CASE WHEN risk_difference < 0 THEN 1 ELSE 0 END) AS count_less_than_zero,
    SUM(CASE WHEN risk_difference = 0 THEN 1 ELSE 0 END) AS count_equal_to_zero,
    SUM(CASE WHEN risk_difference > 0 THEN 1 ELSE 0 END) AS count_greater_than_zero
FROM (
    SELECT 
        v3.appl_id,
        v3.risk_twentile_v3,
        v4.risk_twentile_v4,
        CAST(SUBSTRING(v3.risk_twentile_v3 FROM 5) AS INTEGER) - CAST(SUBSTRING(v4.risk_twentile_v4 FROM 5) AS INTEGER) AS risk_difference
    FROM binned_ecrm_v3 v3
    JOIN binned_ecrm_v4 v4
    ON v3.appl_id = v4.appl_id
) AS combined;

--Analyze the population movement without counting the -1 population
SELECT
    SUM(CASE WHEN risk_difference = 0 THEN 1 ELSE 0 END) AS count_0,
    SUM(CASE WHEN risk_difference BETWEEN 1 AND 2 THEN 1 ELSE 0 END) AS count_1_to_2,
    SUM(CASE WHEN risk_difference BETWEEN 3 AND 4 THEN 1 ELSE 0 END) AS count_3_to_4,
    SUM(CASE WHEN risk_difference BETWEEN 5 AND 6 THEN 1 ELSE 0 END) AS count_5_to_6,
    SUM(CASE WHEN risk_difference BETWEEN 7 AND 10 THEN 1 ELSE 0 END) AS count_7_to_10,
    SUM(CASE WHEN risk_difference > 10 THEN 1 ELSE 0 END) AS count_above_10,
    SUM(CASE WHEN risk_difference BETWEEN -2 AND -1 THEN 1 ELSE 0 END) AS count_minus_2_to_minus_1,
    SUM(CASE WHEN risk_difference BETWEEN -4 AND -3 THEN 1 ELSE 0 END) AS count_minus_4_to_minus_3,
    SUM(CASE WHEN risk_difference BETWEEN -6 AND -5 THEN 1 ELSE 0 END) AS count_minus_6_to_minus_5,
    SUM(CASE WHEN risk_difference BETWEEN -10 AND -7 THEN 1 ELSE 0 END) AS count_minus_10_to_minus_7,
    SUM(CASE WHEN risk_difference < -10 THEN 1 ELSE 0 END) AS count_below_minus_10
FROM (
    SELECT 
        v3.appl_id,
        v3.risk_twentile_v3,
        v4.risk_twentile_v4,
        v3_bin.model_bin_ecrm_v3,
        CAST(SUBSTRING(v3.risk_twentile_v3 FROM 5) AS INTEGER) - CAST(SUBSTRING(v4.risk_twentile_v4 FROM 5) AS INTEGER) AS risk_difference
    FROM binned_ecrm_v3 v3
    JOIN binned_ecrm_v4 v4
    ON v3.appl_id = v4.appl_id
    JOIN model_tables.ecrm_v3_bin v3_bin
    ON v3.appl_id = v3_bin.appl_id
    WHERE v3_bin.model_bin_ecrm_v3 != -1
) AS combined;