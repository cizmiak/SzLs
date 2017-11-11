DECLARE
	@Today DATETIME
SET @Today = FLOOR(CAST(GETDATE() AS FLOAT))

DECLARE @skolenia TABLE (OrganizaciaID INT, SkolenieID INT, Email NVARCHAR(255))

INSERT @skolenia(OrganizaciaID, SkolenieID, Email)
SELECT
	s.OrganizaciaID
	,s.ID AS SkolenieID
	,COALESCE(notifikovany.Email, z.Email, 'miroslav.hanzen@gmail.com')
	+ ISNULL(';' + nad.Email, '')
	+ ISNULL(';' + zod.Email, '') AS Email
FROM
	dbo.Skolenie s
	LEFT JOIN dbo.Zamestnanec z
		ON z.ID = s.SkolitelID
		AND
		z.StavID != 2
	LEFT JOIN dbo.Zamestnanec notifikovany
		ON z.ID = s.NotifikovanyID
		AND
		z.StavID != 2
	LEFT JOIN dbo.Zamestnanec nad
		ON nad.ID = z.Nadriadeny
		AND
		nad.StavID != 2
	LEFT JOIN dbo.Zmluva zml
		ON zml.ID = s.ZmluvaID
	LEFT JOIN dbo.Zamestnanec zod
		ON zod.ID = zml.Zodpovedny
		AND
		zod.StavID != 2
WHERE
	FLOOR(CAST(s.Nasledujuce AS FLOAT)) - @Today IN (30,14)

DECLARE organizacie CURSOR FOR
SELECT OrganizaciaID FROM @skolenia GROUP BY OrganizaciaID