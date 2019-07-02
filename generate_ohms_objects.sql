CREATE DEFINER=[]@[] PROCEDURE `generate_ohms_objects`()
BEGIN

-- vars for end-state handler (done) and ID placeholder
DECLARE done BOOLEAN DEFAULT 0;
DECLARE ID INT;

-- cursor goes here, gets all the needed IDs
DECLARE ids_wo_ohms_obj CURSOR 
FOR
	SELECT 
		record_id 
	FROM oralhistory.omeka_element_texts
    WHERE record_id NOT IN (
		-- a subquery to pull all of the ids where the DON'T have an OHMS Object field but DO have an XML
        -- this speeds up the query in future use cases where we don't want to affect existing Items
		SELECT 
			record_id 
		FROM oralhistory.omeka_element_texts 
        WHERE element_id <> [OHMS Object element id]
	) AND 
		element_id = [XML element id];

-- continue clause
DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done=1;

-- open up the cursor
OPEN ids_wo_ohms_obj;

-- loop through the IDs and insert new rows for each
REPEAT
	FETCH ids_wo_ohms_obj INTO ID;
    
    SELECT 
	`text` 
	INTO
		@xml_text
	FROM
		oralhistory.omeka_element_texts 
	WHERE
		record_id = ID and element_id = [XML element id];
    
	SET @prefix_url = 'https://omeka.eku.edu/ohms-viewer/render.php?cachefile=';

	SET @ohms_object_text = concat(@prefix_url, @xml_text);

	INSERT INTO oralhistory.omeka_element_texts(record_id, record_type, element_id, html, `text`)
	VALUES(ID, 'Item', [OHMS Object element id], 0, @ohms_object_text);
UNTIL done END REPEAT;
CLOSE ids_wo_ohms_obj;
END
