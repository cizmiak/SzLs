USE [SpravaZmluv]
GO
/****** Object:  StoredProcedure [report].[SkoleniePosluchac]    Script Date: 19.02.2016 16:10:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [report].[SkoleniePosluchac]
	@SkolenieID VARCHAR(MAX) = NULL,
	@OrganizaciaID VARCHAR(MAX) = NULL,
	@UskutocneneOD DATETIME = NULL,
	@UskutocneneDO DATETIME = NULL
AS

--DECLARE
--	@SkolenieID INT = NULL

SELECT
	s.ID
	,s.Referencia
	,s.Nazov
	,s.Uskutocnene
	,s.UcastCelkom
	,s.Vyhovelo
	,s.Nevyhovelo
	,s.MiestoKonania
	,s.Vyska15
	,s.Plosina
	,s.Rebrik5
	,s.Hlbka13
	,skp.Nazov AS SkoleniePreKoho
	,st.Nazov AS Typ
	,sd.Nazov AS Druh
	,sfs.Nazov AS FormaSkusania
	,o.Nazov AS Organizacia
	,matka.Nazov AS Matka
	,z.Priezvisko + ' ' + z.Meno AS Lektor
	,p.Priezvisko + ' ' + p.Meno AS PredsedaKomisie
	,c1.Priezvisko + ' ' + c1.Meno AS ClenKomisie1
	,c2.Priezvisko + ' ' + c2.Meno AS ClenKomisie2
	,posl.ID AS PosluchacID
	,posl.Priezvisko + ' ' + posl.Meno AS PosluchacMeno
	,posl.Titul AS PosluchacTitul
	,pz.Nazov AS PosluchacPracovneZaradenie
	,posl.Bydlisko AS PosluchacBydlisko
	,posl.DatumNarodenia AS PosluchacDatumNarodenia
	
	/*obsluha motorovych vozikov*/
	,ISNULL(sp.PreukazVydany, s.PreukazyVydane) AS PreukazyVydane
	,ISNULL(sp.PreukazVydal, s.PreukazyVydal) AS PreukazyVydal
	,ISNULL(sp.CisloPreukazu, s.CisloPreukazu) AS CisloPreukazu
	,st.CisloOpravnenia
	
	,CASE WHEN ISNULL(s.I, '') = 1 THEN 'I. ' ELSE '' END
	+CASE WHEN ISNULL(s.II, '') = 1 THEN 'II. ' ELSE '' END  AS TriedaMotorovychVozikov
	
	,CASE WHEN ISNULL(s.I, '') = 1 THEN 'I.' ELSE '' END	AS I
	,CASE WHEN ISNULL(s.II, '') = 1 THEN 'II.' ELSE '' END	AS II

	,CASE WHEN ISNULL(s.A, '') = 1 THEN 'A ' ELSE '' END
	+CASE WHEN ISNULL(s.B, '') = 1 THEN 'B ' ELSE '' END
	+CASE WHEN ISNULL(s.C, '') = 1 THEN 'C ' ELSE '' END
	+CASE WHEN ISNULL(s.D, '') = 1 THEN 'D ' ELSE '' END
	+CASE WHEN ISNULL(s.E, '') = 1 THEN 'E ' ELSE '' END
	+CASE WHEN ISNULL(s.W1, '') = 1 THEN 'W1 ' ELSE '' END
	+CASE WHEN ISNULL(s.W2, '') = 1 THEN 'W2 ' ELSE '' END
	+CASE WHEN ISNULL(s.G, '') = 1 THEN 'G ' ELSE '' END
	+CASE WHEN ISNULL(s.Z, '') = 1 THEN 'Z ' ELSE '' END  AS DruhMotorovychVozikov

	,CASE WHEN ISNULL(s.A, '') = 1 THEN 'A ' ELSE '' END	AS A
	,CASE WHEN ISNULL(s.B, '') = 1 THEN 'B ' ELSE '' END	AS B
	,CASE WHEN ISNULL(s.C, '') = 1 THEN 'C ' ELSE '' END	AS C
	,CASE WHEN ISNULL(s.D, '') = 1 THEN 'D ' ELSE '' END	AS D
	,CASE WHEN ISNULL(s.E, '') = 1 THEN 'E ' ELSE '' END	AS E
	,CASE WHEN ISNULL(s.W1, '') = 1 THEN 'W1 ' ELSE '' END	AS W1
	,CASE WHEN ISNULL(s.W2, '') = 1 THEN 'W2 ' ELSE '' END	AS W2
	,CASE WHEN ISNULL(s.G, '') = 1 THEN 'G ' ELSE '' END  	AS G
	,CASE WHEN ISNULL(s.Z, '') = 1 THEN 'Z ' ELSE '' END  	AS Z
FROM
	dbo.Skolenie s
	LEFT JOIN dbo.Organizacia o
		ON o.ID = s.OrganizaciaID
	LEFT JOIN dbo.Organizacia matka
		ON matka.ID = o.Matka
	LEFT JOIN dbo.Zamestnanec z
		ON z.ID = s.SkolitelID
	LEFT JOIN dbo.Zamestnanec p
		ON p.ID = s.PredsedaKomisieID
	LEFT JOIN dbo.Zamestnanec c1
		ON c1.ID = s.ClenKomisie1ID
	LEFT JOIN dbo.Zamestnanec c2
		ON c2.ID = s.ClenKomisie2ID
	LEFT JOIN dbo.SkolenieTyp st
		ON st.ID = s.TypID
	LEFT JOIN dbo.SkolenieDruh sd
		ON sd.ID = s.DruhID
	LEFT JOIN dbo.SkolenieFormaSkusania sfs
		ON sfs.ID = s.FormaSkusaniaID
	LEFT JOIN dbo.SkoleniePreKoho skp
		ON skp.ID = s.PreKohoID
	LEFT JOIN dbo.SkoleniePosluchac sp
		ON sp.SkolenieID = s.ID
	LEFT JOIN dbo.Posluchac posl
		ON posl.ID = sp.PosluchacID
	LEFT JOIN dbo.PracovneZaradenie pz
		ON pz.ID = posl.PracovneZaradenieID
WHERE
	(
		@SkolenieID IS NULL
		OR
		@SkolenieID LIKE '-1%'
		OR
		s.ID IN (SELECT Item FROM report.TableFromList(',', @SkolenieID))
	)
	AND
	(
		@OrganizaciaID IS NULL
		OR
		@OrganizaciaID LIKE '-1%'
		OR
		s.OrganizaciaID IN (SELECT Item FROM report.TableFromList(',', @OrganizaciaID))
	)
	AND
	(
		@UskutocneneOD IS NULL
		OR
		s.Uskutocnene >= @UskutocneneOD
	)
	AND
	(
		@UskutocneneDO IS NULL
		OR
		s.Uskutocnene < @UskutocneneDO
	)
