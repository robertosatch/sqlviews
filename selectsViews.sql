--Total de Custodiados por pavilhão
CREATE OR REPLACE VIEW siapen.vwcount_custodiado_pavilhao AS
    SELECT 
        c.unidade_prisional,
        p.id,
        p.nome,
        COUNT(p.id) AS t_cust_pavilhao
    FROM
        siapen.vwcustodiado_alojamento c
            INNER JOIN
        siapen.geral_setor p ON c.geral_setor_id = p.id
    GROUP BY p.id , c.unidade_prisional_id
    ORDER BY COUNT(p.id) DESC;

-- Total de custodiado com visita por palilhão (ao menos uma visita)
CREATE OR REPLACE VIEW siapen.vwcount_custodiado_visita_pavilhao AS
    SELECT 
        cust.unidade_prisional,
        p.id,
        p.nome,
        COUNT(p.id) AS t_cust_visita
    FROM
        siapen.vwcustodiado_alojamento AS cust
            INNER JOIN
        siapen.geral_setor AS p ON cust.geral_setor_id = p.id
    WHERE
        cust.id IN (SELECT DISTINCT
                (iv.idinterno)
            FROM
                siapen.interno_visitante AS iv
            WHERE
                iv.idstatus = 12)
    GROUP BY p.id , cust.unidade_prisional_id
    ORDER BY COUNT(p.id) DESC;

-- mae, pai e companheiras do custodiado todos >= 18 e <= 60 
CREATE OR REPLACE VIEW siapen.vwvinculo_pessoa_custodiado AS
    SELECT 
        p.idpessoa,
        p.nome_pessoa,
        p.data_nascimento,
        TIMESTAMPDIFF(YEAR,
            p.data_nascimento,
            CURRENT_DATE()) AS idade,
        p.sexo,
        pv.idvinculo,
        gpv.vinculo,
        pv.idpessoa_vinculo
    FROM
        siapen.pessoa AS p
            INNER JOIN
        siapen.pessoa_vinculo AS pv ON p.idpessoa = pv.idpessoa
            INNER JOIN
        siapen.geral_pessoa_vinculo AS gpv ON pv.idvinculo = gpv.idvinculo
    WHERE
        p.data_nascimento IS NOT NULL
            AND TIMESTAMPDIFF(YEAR,
            p.data_nascimento,
            CURRENT_DATE()) <= 60
            AND TIMESTAMPDIFF(YEAR,
            p.data_nascimento,
            CURRENT_DATE()) >= 18
            AND pv.idvinculo IN (1 , 2, 9, 10, 11, 12)
            AND pv.idpessoa NOT IN (SELECT 
                p.idpessoa
            FROM
                siapen.pessoa AS p
                    INNER JOIN
                siapen.interno AS i ON p.idpessoa = i.idpessoa);

-- total de custodiado com visita apta por pavilhão
CREATE OR REPLACE VIEW siapen.vwcount_custodiado_visita_apta AS
    SELECT 
        cust.unidade_prisional,
        p.id,
        p.nome,
        COUNT(p.id) AS t_cust_vis_apta
    FROM
        siapen.vwcustodiado_alojamento AS cust
            INNER JOIN
        siapen.geral_setor AS p ON cust.geral_setor_id = p.id
    WHERE
        cust.id IN (SELECT DISTINCT
                (iv.idinterno)
            FROM
                siapen.interno_visitante AS iv
                    INNER JOIN
                siapen.vwvinculo_pessoa_custodiado AS vp ON iv.idvisitante = vp.idpessoa
            WHERE
                iv.idstatus = 12)
    GROUP BY p.id , cust.unidade_prisional_id
    ORDER BY COUNT(p.id) DESC;



--total dos internos com visitantes < 18 e > 60
create or replace view vwcount_custodiado_visita_fora_idade as
select p.id, p.nome, count(p.id) as total_visita_fora_idade from siapen.vwcustodiado_alojamento as c
	inner join siapen.geral_setor as p on c.geral_setor_id = p.id
    where c.id in (
        select distinct(iv.idinterno) from siapen.interno_visitante iv
            where iv.idstatus = 12 and iv.idvisitante not in 
            (select p.idpessoa from siapen.pessoa as p
                where p.data_nascimento is not null
                and TIMESTAMPDIFF(YEAR, p.data_nascimento, CURRENT_DATE()) >= 18
                and TIMESTAMPDIFF(YEAR, p.data_nascimento, CURRENT_DATE()) <= 60))
    group by p.id, c.unidade_prisional_id
    order by count(p.id) desc;


-- Relatório com todos os totais de custodiado, de visitante, de fora de idade 
CREATE OR REPLACE VIEW siapen.vwcount_custodiado_visita_geral AS
    SELECT 
        tcp.unidade_prisional,
        tcp.id,
        tcp.nome,
        tcp.t_cust_pavilhao AS custodiado,
        tcvp.t_cust_visita AS cust_visita,
        tcva.t_cust_vis_apta AS visita_apta,
        tcvp.t_cust_visita - tcva.t_cust_vis_apta AS visita_inapta
    FROM
        siapen.vwcount_custodiado_pavilhao AS tcp
            INNER JOIN
        siapen.vwcount_custodiado_visita_pavilhao AS tcvp ON tcp.id = tcvp.id
            INNER JOIN
        siapen.vwcount_custodiado_visita_apta AS tcva ON tcp.id = tcva.id
    ORDER BY tcva.t_cust_vis_apta DESC;

-- Count de custodiados por regime
SELECT 
    r.idprisao_regime, r.prisao_regime, COUNT(*)
FROM
    siapen.interno AS i
        INNER JOIN
    siapen.interno_alojamento AS ia ON i.idinterno = ia.idinterno
        INNER JOIN
    siapen.pessoa AS p ON i.idpessoa = p.idpessoa
        INNER JOIN
    siapen.juridico_prisao_regime AS r ON i.idprisao_regime = r.idprisao_regime
WHERE
    ia.status = 0
GROUP BY r.idprisao_regime
ORDER BY r.idprisao_regime;