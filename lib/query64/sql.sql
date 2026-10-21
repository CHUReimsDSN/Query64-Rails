
        SELECT DISTINCT ON
        (start_table_final.id)
        start_table_final.*
        FROM (
        SELECT DISTINCT ON
        (start_table_sub_request.id, localisations__target.libelle)
        start_table_sub_request.id, start_table_sub_request.code, start_table_sub_request.urgence, start_table_sub_request.observation_technique, start_table_sub_request.demande, start_table_sub_request.demandeur_nom, start_table_sub_request.demandeur_tel, start_table_sub_request.demandeur_mail, start_table_sub_request.est_reforme, start_table_sub_request.date_de_reforme, start_table_sub_request.created_at, start_table_sub_request.updated_at, start_table_sub_request.statut, start_table_sub_request.type_intervention, start_table_sub_request.date_de_fin, start_table_sub_request.ticket_id, start_table_sub_request.mixte, 
              COALESCE(
                json_agg(
                  DISTINCT jsonb_build_object(
                    'libelle', localisations__target.libelle
                  )
                )
              )::text as localisation
            , 
              COALESCE(
                json_agg(
                  DISTINCT jsonb_build_object(
                    'libelle', equipements__target.libelle
                  )
                )
              )::text as equipement
            , 
              COALESCE(
                json_agg(
                  DISTINCT jsonb_build_object(
                    'libelle', corps_metiers__target.libelle
                  )
                )
              )::text as corps_metier
            , 
              COALESCE(
                json_agg(
                  DISTINCT jsonb_build_object(
                    'libelle', causes__target.libelle
                  )
                )
              )::text as cause
            , start_table_sub_request.localisation_id, start_table_sub_request.equipement_id, start_table_sub_request.corps_metier_id, start_table_sub_request.cause_id
        FROM interventions AS start_table_sub_request
        
            LEFT OUTER JOIN localisations
            AS localisations__target
            ON localisations__target.id = start_table_sub_request.localisation_id
           
            LEFT OUTER JOIN equipements
            AS equipements__target
            ON equipements__target.id = start_table_sub_request.equipement_id
           
            LEFT OUTER JOIN corps_metiers
            AS corps_metiers__target
            ON corps_metiers__target.id = start_table_sub_request.corps_metier_id
           
            LEFT OUTER JOIN causes
            AS causes__target
            ON causes__target.id = start_table_sub_request.cause_id
          
        WHERE  (start_table_sub_request.est_reforme IN ('false'))  AND (start_table_sub_request.id::text ILIKE '%%' OR start_table_sub_request.code::text ILIKE '%%' OR start_table_sub_request.urgence::text ILIKE '%%' OR start_table_sub_request.observation_technique::text ILIKE '%%' OR start_table_sub_request.demande::text ILIKE '%%' OR start_table_sub_request.demandeur_nom::text ILIKE '%%' OR start_table_sub_request.demandeur_tel::text ILIKE '%%' OR start_table_sub_request.demandeur_mail::text ILIKE '%%' OR start_table_sub_request.est_reforme::text ILIKE '%%' OR start_table_sub_request.date_de_reforme::text ILIKE '%%' OR start_table_sub_request.created_at::text ILIKE '%%' OR start_table_sub_request.updated_at::text ILIKE '%%' OR start_table_sub_request.statut::text ILIKE '%%' OR start_table_sub_request.type_intervention::text ILIKE '%%' OR start_table_sub_request.date_de_fin::text ILIKE '%%' OR start_table_sub_request.ticket_id::text ILIKE '%%' OR start_table_sub_request.mixte::text ILIKE '%%' OR localisations__target.libelle::text ILIKE '%%' OR equipements__target.libelle::text ILIKE '%%' OR corps_metiers__target.libelle::text ILIKE '%%' OR causes__target.libelle::text ILIKE '%%' OR start_table_sub_request.localisation_id::text ILIKE '%%' OR start_table_sub_request.equipement_id::text ILIKE '%%' OR start_table_sub_request.corps_metier_id::text ILIKE '%%' OR start_table_sub_request.cause_id::text ILIKE '%%') 
        GROUP BY start_table_sub_request.id, start_table_sub_request.code, start_table_sub_request.urgence, start_table_sub_request.observation_technique, start_table_sub_request.demande, start_table_sub_request.demandeur_nom, start_table_sub_request.demandeur_tel, start_table_sub_request.demandeur_mail, start_table_sub_request.est_reforme, start_table_sub_request.date_de_reforme, start_table_sub_request.created_at, start_table_sub_request.updated_at, start_table_sub_request.statut, start_table_sub_request.type_intervention, start_table_sub_request.date_de_fin, start_table_sub_request.ticket_id, start_table_sub_request.mixte, localisations__target.libelle, start_table_sub_request.localisation_id, start_table_sub_request.equipement_id, start_table_sub_request.corps_metier_id, start_table_sub_request.cause_id
        ORDER BY localisations__target.libelle ASC
        LIMIT 50 OFFSET 0
        ) AS start_table_final
        
        
        GROUP BY start_table_final.id, start_table_final.code, start_table_final.urgence, start_table_final.observation_technique, start_table_final.demande, start_table_final.demandeur_nom, start_table_final.demandeur_tel, start_table_final.demandeur_mail, start_table_final.est_reforme, start_table_final.date_de_reforme, start_table_final.created_at, start_table_final.updated_at, start_table_final.statut, start_table_final.type_intervention, start_table_final.date_de_fin, start_table_final.ticket_id, start_table_final.mixte, start_table_final.localisation, start_table_final.equipement, start_table_final.corps_metier, start_table_final.cause, start_table_final.localisation_id, start_table_final.equipement_id, start_table_final.corps_metier_id, start_table_final.cause_id
        
        
        ;
      