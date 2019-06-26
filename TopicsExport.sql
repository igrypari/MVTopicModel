
select 
TopicId, 
Document.id, 
round(Weight,2), 
Title  ,
batchid,
--Abstract,
 --journalISSN   ,
   --DOI     ,
  repository 
  from doc_topic
Inner Join Document on Document.id=Doc_Topic.DocId 
where ExperimentId = 'PubMed_500T_550IT_7000CHRs_4M_OneWay'
and weight > 0.6	
--And topicId=0 
Order by TopicId, Weight desc;




select a.TopicId
, b.Title,b.Category , NormWeight
,Modality, 
 string_agg( concept, ','::text ORDER BY WeightedCounts DESC) AS concepts
 from 
 
(
SELECT TopicDescription.TopicId AS TopicId,
           Round(TopicDetails.Weight,5) AS TopicWeight,
           TopicDetails.TotalTokens,
           TopicDescription.ItemType,
           CASE TopicDescription.Itemtype 
           WHEN - 2 THEN 'KeyPhrase' 
           WHEN - 1 THEN 'Phrase' 
           WHEN 0 THEN 'Word' 
           WHEN 1 THEN 'Keyword' 
           WHEN 2 THEN 'MeshTerm'  
           WHEN 3 THEN 'DBpedia'                   
           --WHEN 4 THEN 'Citation'            
           END AS Modality,          

           CASE TopicDescription.Itemtype 
           WHEN - 2 THEN Item
           WHEN - 1 THEN Item 
           WHEN 0 THEN Item 
           WHEN 1 THEN Item
           WHEN 2 THEN Item
           WHEN 3 THEN substring(item,29,length(item))                   
           --WHEN 4 THEN Publication.title            
           END AS concept,   
           Item,
           Counts,
           DiscrWeight,
           WeightedCounts,           
           --document.title AS Citation,
           DBPediaResourceDetails.Label AS DBpedia_Label,           
		  DBPediaResourceDetails.icd10 AS DBpedia_icd10,           
	      DBPediaResourceDetails.mesh||':'||DBPediaResourceDetails.meshId AS DBpedia_MeSH,           
		  DBPediaResourceDetails.Type as DBpedia_type,
           TopicDescription.ExperimentId AS ExperimentId
      FROM (
               SELECT TopicId,
                      TopicAnalysis.Item,
                      TopicAnalysis.ItemType,
                      TopicsCnt,
                      TopicAnalysis.Counts * (CASE TopicAnalysis.itemType WHEN - 1 THEN Experiment.PhraseBoost ELSE 1 END) AS counts,
                      CASE TopicAnalysis.itemType WHEN - 1 THEN Experiment.PhraseBoost ELSE 1 END AS TypeWeight,
                      CAST (PowSum / (TotalSum * TotalSum) AS REAL) AS DiscrWeight,
                      round(CASE TopicAnalysis.itemType WHEN - 1 THEN Experiment.PhraseBoost ELSE 1 END * CAST(PowSum / (TotalSum * TotalSum) * TopicAnalysis.Counts AS REAL)) AS WeightedCounts,
                      TopicAnalysis.ExperimentId
                 FROM TopicAnalysis
                      INNER JOIN
                      Experiment ON TopicAnalysis.ExperimentId = Experiment.ExperimentId AND Experiment.ExperimentId =  'PubMed_500T_550IT_7000CHRs_4M_OneWay'
                      INNER JOIN
                      (
                          SELECT ExperimentId,
                                 Item,
                                 ItemType,
                                 CAST (count(*) AS REAL)  AS TopicsCnt,
                                 sum(Counts * CAST (Counts AS REAL))  AS PowSum,
                                 CAST (sum(Counts) AS REAL) AS TotalSum
                            FROM TopicAnalysis
                           WHERE counts > 3
                           GROUP BY ExperimentId,
                                    ItemType,
                                    Item
                      )
                      AS FreqItems ON FreqItems.ExperimentId = TopicAnalysis.ExperimentId AND 
                                      FreqItems.ItemType = TopicAnalysis.itemType AND 
                                      FreqItems.Item = TopicAnalysis.item
                WHERE counts > 3
               
           )
           AS TopicDescription
           LEFT OUTER JOIN
           TopicDetails ON TopicDetails.TopicId = TopicDescription.TopicId AND 
                           TopicDetails.ExperimentId = TopicDescription.ExperimentId AND 
                           TopicDetails.Itemtype = 0
           
           LEFT OUTER JOIN
          (select DBPediaResource.id, DBPediaResource.label, DBPediaResource.icd10, DBPediaResource.meshId, DBPediaResource.mesh, dbpediaresourcetype.typelabel as type
		   from DBPediaResource
	       left join dbpediaresourcetype on dbpediaresourcetype.resourceid = id
				  ) DBPediaResourceDetails  ON DBPediaResourceDetails.Id = Item AND 
                     TopicDescription.ItemType = 3
           
           --LEFT OUTER JOIN
           --document ON document.Id = Item AND 
             --          TopicDescription.ItemType = 4
     WHERE Counts > 20  
     -- and TopicDescription.topicid=0   
     Order By TopicDescription.ExperimentId , TopicDescription.TopicId, TopicDescription.ItemType, WeightedCounts DESC

     
     )
	 as a 
     INNER JOIN  (
           
                          SELECT  PubTopic.TopicId, round(sum(PubTopic.weight) / SumTopicWeightPerProjectView.ProjectSumWeight,5) as NormWeight,
		                          TopicDescriptionExpert.Title,TopicDescriptionExpert.Category 
                                              FROM doc_topic
                                              Inner join Topic on PubTodoc_topicpic.topicId = Topic.TopicId 
		 								--and visibilityindex=4
                                              --inner join embopmcid on 
                                          --    INNER JOIN  embopmcid ON PubTopic.PubId = embopmcid.pmcid AND PubTopic.weight > 0.1
                                              and  doc_topic.ExperimentId='PubMed_500T_550IT_7000CHRs_4M_OneWay' 
                                            
                                                   INNER JOIN (SELECT  sum(weight) AS ProjectSumWeight,    ExperimentId
                                                   FROM doc_topic
                                                   --INNER JOIN  embopmcid ON PubTopic.PubId = embopmcid.pmcid AND PubTopic.weight > 0.1
                                                   
                                                   GROUP BY  ExperimentId)
                                                   SumTopicWeightPerProjectView ON 
                                                                                   SumTopicWeightPerProjectView.ExperimentId = doc_topic.ExperimentId                                            
                                             GROUP BY 
                                                      SumTopicWeightPerProjectView.ProjectSumWeight,
                                                      doc_topic.TopicId,
                                                      doc_topic.ExperimentId,
                                                      TopicDescriptionExpert.TopicId
                                                      order by  doc_topic.ExperimentId,   NormWeight Desc
     --                                                 limit 50
	 ) b on b.TopicID = a.TopicID
                                                      
     group by a.topicid, b.TopicID, NormWeight, Modality, b.Title,b.Category 
     --group by a.topicid,  Modality 
     order by a.topicid Desc
	 
----------------------------

--Group 

select 
a.TopicId
, TopicWeight
, Modality 
 ,string_agg( concept, ','::text ORDER BY WeightedCounts DESC) AS concepts
 from 
 
(
SELECT TopicDescription.TopicId AS TopicId,
           Round(TopicDetails.Weight,5) AS TopicWeight,
           TopicDetails.TotalTokens,
           TopicDescription.ItemType,
           CASE TopicDescription.Itemtype 
           WHEN - 2 THEN 'KeyPhrase' 
           WHEN - 1 THEN 'Phrase' 
           WHEN 0 THEN 'Word' 
           WHEN 1 THEN 'Keyword' 
           WHEN 2 THEN 'MeshTerm'  
           WHEN 3 THEN 'DBpedia'                   
           --WHEN 4 THEN 'Citation'            
           END AS Modality,          

           CASE TopicDescription.Itemtype 
           WHEN - 2 THEN Item
           WHEN - 1 THEN Item 
           WHEN 0 THEN Item 
           WHEN 1 THEN Item
           WHEN 2 THEN Item
           WHEN 3 THEN substring(item,29,length(item))                   
           --WHEN 4 THEN Publication.title            
           END AS concept,   
           Item,
           Counts,
           DiscrWeight,
           WeightedCounts,           
           --document.title AS Citation,
           DBPediaResourceDetails.Label AS DBpedia_Label,           
		  DBPediaResourceDetails.icd10 AS DBpedia_icd10,           
	      DBPediaResourceDetails.mesh||':'||DBPediaResourceDetails.meshId AS DBpedia_MeSH,           
		  DBPediaResourceDetails.Type as DBpedia_type,
           TopicDescription.ExperimentId AS ExperimentId
      FROM (
               SELECT TopicId,
                      TopicAnalysis.Item,
                      TopicAnalysis.ItemType,
                      TopicsCnt,
                      TopicAnalysis.Counts * (CASE TopicAnalysis.itemType WHEN - 1 THEN Experiment.PhraseBoost ELSE 1 END) AS counts,
                      CASE TopicAnalysis.itemType WHEN - 1 THEN Experiment.PhraseBoost ELSE 1 END AS TypeWeight,
                      CAST (PowSum / (TotalSum * TotalSum) AS REAL) AS DiscrWeight,
                      round(CASE TopicAnalysis.itemType WHEN - 1 THEN Experiment.PhraseBoost ELSE 1 END * CAST(PowSum / (TotalSum * TotalSum) * TopicAnalysis.Counts AS REAL)) AS WeightedCounts,
                      TopicAnalysis.ExperimentId
                 FROM TopicAnalysis
                      INNER JOIN
                      Experiment ON TopicAnalysis.ExperimentId = Experiment.ExperimentId AND Experiment.ExperimentId =  'PubMed_500T_550IT_7000CHRs_4M_OneWay'
                      INNER JOIN
                      (
                          SELECT ExperimentId,
                                 Item,
                                 ItemType,
                                 CAST (count(*) AS REAL)  AS TopicsCnt,
                                 sum(Counts * CAST (Counts AS REAL))  AS PowSum,
                                 CAST (sum(Counts) AS REAL) AS TotalSum
                            FROM TopicAnalysis
                           WHERE counts > 3
                           GROUP BY ExperimentId,
                                    ItemType,
                                    Item
                      )
                      AS FreqItems ON FreqItems.ExperimentId = TopicAnalysis.ExperimentId AND 
                                      FreqItems.ItemType = TopicAnalysis.itemType AND 
                                      FreqItems.Item = TopicAnalysis.item
                WHERE counts > 3
               
           )
           AS TopicDescription
           LEFT OUTER JOIN
           TopicDetails ON TopicDetails.TopicId = TopicDescription.TopicId AND 
                           TopicDetails.ExperimentId = TopicDescription.ExperimentId AND 
                           TopicDetails.Itemtype = 0
           
           LEFT OUTER JOIN
          (select DBPediaResource.id, DBPediaResource.label, DBPediaResource.icd10, DBPediaResource.meshId, DBPediaResource.mesh, dbpediaresourcetype.typelabel as type
		   from DBPediaResource
	       left join dbpediaresourcetype on dbpediaresourcetype.resourceid = id
				  ) DBPediaResourceDetails  ON DBPediaResourceDetails.Id = Item AND 
                     TopicDescription.ItemType = 3
           
           --LEFT OUTER JOIN
           --document ON document.Id = Item AND 
             --          TopicDescription.ItemType = 4
     WHERE Counts > 20  
     -- and TopicDescription.topicid=0   
     Order By TopicDescription.ExperimentId , TopicDescription.TopicId, TopicDescription.ItemType, WeightedCounts DESC

     
     )
	 as a 
                            
     group by a.topicid, TopicWeight, Modality
     --group by a.topicid,  Modality 
     order by a.topicid
