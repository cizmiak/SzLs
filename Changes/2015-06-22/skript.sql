USE SpravaZmluv
GO
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Organizacia') AND name = 'Referencia' AND max_length = 50)
ALTER TABLE dbo.Organizacia ALTER COLUMN Referencia VARCHAR(50)
GO
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Skolenie') AND name = 'NotifikovanyID')
ALTER TABLE dbo.Skolenie ADD NotifikovanyID INT, CONSTRAINT FK_Skolenie_Notifikovany FOREIGN KEY (NotifikovanyID) REFERENCES dbo.Zamestnanec(ID)
GO
ALTER PROCEDURE [dbo].[SkolenieNotification]
AS
--SET DATEFIRST 1
DECLARE
	@ID VARCHAR(200),
	@Referencia VARCHAR(200),
	@Nazov VARCHAR(200),
	@Uskutocnene VARCHAR(200),
	@Nasledujuce VARCHAR(200),
	@Lehota VARCHAR(200),
	@UcastCelkom VARCHAR(200),
	@Vyhovelo VARCHAR(200),
	@Nevyhovelo VARCHAR(200),
	@MiestoKonania VARCHAR(200),
	@SkoleniePreKoho VARCHAR(200),
	@Typ VARCHAR(200),
	@Druh VARCHAR(200),
	@FormaSkusania VARCHAR(200),
	@Organizacia VARCHAR(200),
	@Lektor VARCHAR(200),
	@PredsedaKomisie VARCHAR(200),
	@ClenKomisie1 VARCHAR(200),
	@ClenKomisie2 VARCHAR(200),
	@Email VARCHAR(200),
	@NasledujuceZa VARCHAR(200),
	@KontaktnaOsobaEmail VARCHAR(MAX),

	@body VARCHAR(MAX),
	@subject VARCHAR(100),
	@spravaZmluvURL VARCHAR(500),
	@aElement VARCHAR(1000),
	@Today DATETIME

SET @Today = FLOOR(CAST(GETDATE() AS FLOAT))
SET @subject = 'Notifik·cia nasleduj˙ceho ökolenia'
--SET @Today = '2014-09-01'
--SET @subject = '!!!test vymazte(ako by bolo 1.9.2014)!!! Notifik·cia nasleduj˙ceho ökolenia'

DELETE FROM dbo.SkolenieNotificated WHERE InsertedDateTime < @Today - 90

SELECT @spravaZmluvURL = Hodnota FROM dbo.Konfiguracia WHERE Nastavenie = 'SpravaZmluvURL'
SET @spravaZmluvURL = @spravaZmluvURL + '/#/'

DECLARE cur CURSOR FOR
SELECT
	s.ID AS ID
	,ISNULL(s.Referencia, 'NezadanÈ') AS Referencia
	,ISNULL(s.Nazov, 'NezadanÈ') AS  SkolenieNazov
	,ISNULL(CONVERT(VARCHAR(50), s.Uskutocnene, 104), 'NezadanÈ') AS Uskutocnene
	,CONVERT(VARCHAR(50), s.Nasledujuce, 104) AS Nasledujuce
	,ISNULL(CAST(YEAR(s.Nasledujuce) - YEAR(s.Uskutocnene) AS VARCHAR(5)), 'NezadanÈ') AS Lehota
	,ISNULL(CAST(s.UcastCelkom AS VARCHAR(50)), 'NezadanÈ') AS UcastCelkom
	,ISNULL(CAST(s.Vyhovelo AS VARCHAR(50)), 'NezadanÈ') AS Vyhovelo
	,ISNULL(CAST(s.Nevyhovelo AS VARCHAR(50)), 'NezadanÈ') AS Nevyhovelo
	,ISNULL(s.MiestoKonania, 'NezadanÈ') AS MiestoKonania
	,ISNULL(skp.Nazov, 'NezadanÈ') AS SkoleniePreKoho
	,ISNULL(st.Nazov, 'NezadanÈ')  AS Typ
	,ISNULL(sd.Nazov, 'NezadanÈ')  AS Druh
	,ISNULL(sfs.Nazov, 'NezadanÈ')  AS FormaSkusania
	,ISNULL(o.Nazov, 'NezadanÈ')  AS Organizacia
	,COALESCE(notifikovany.Priezvisko + ' ' + notifikovany.Meno, z.Priezvisko + ' ' + z.Meno, 'NezadanÈ')  AS Lektor
	,ISNULL(p.Priezvisko + ' ' + p.Meno, 'NezadanÈ')  AS PredsedaKomisie
	,ISNULL(c1.Priezvisko + ' ' + c1.Meno, 'NezadanÈ')  AS ClenKomisie1
	,ISNULL(c2.Priezvisko + ' ' + c2.Meno, 'NezadanÈ')  AS ClenKomisie2
	,COALESCE(notifikovany.Email, z.Email, 'miroslav.hanzen@gmail.com') + ISNULL(';' + nad.Email, '') + ISNULL(';' + zod.Email, '') AS Email
	,ISNULL(CAST(CAST(FLOOR(CAST(s.Nasledujuce AS FLOAT)) - @Today AS INT) AS VARCHAR(20)), 'xy') AS NasledujuceZa
	,ISNULL(report.GetKontaktnaOsobaEmail(s.OrganizaciaID), 'NezadanÈ') AS KontaktnaOsobaEmail
FROM
	dbo.Skolenie s
	LEFT JOIN dbo.Organizacia o
		ON o.ID = s.OrganizaciaID
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
	LEFT JOIN dbo.Zmluva zml
		ON zml.ID = s.ZmluvaID
	LEFT JOIN dbo.Zamestnanec zod
		ON zod.ID = zml.Zodpovedny
		AND
		zod.StavID != 2
WHERE
	FLOOR(CAST(s.Nasledujuce AS FLOAT)) - @Today IN (30,14)
	/*2014-10-01 pondelokove notifikacie davame do precu*/
	--OR
	--s.Nasledujuce BETWEEN @Today AND @Today + 7
	--AND
	--DATEPART(DW, GETDATE()) = 1

OPEN cur

FETCH NEXT FROM cur INTO
	@ID,
	@Referencia,
	@Nazov,
	@Uskutocnene,
	@Nasledujuce,
	@Lehota,
	@UcastCelkom,
	@Vyhovelo,
	@Nevyhovelo,
	@MiestoKonania,
	@SkoleniePreKoho,
	@Typ,
	@Druh,
	@FormaSkusania,
	@Organizacia,
	@Lektor,
	@PredsedaKomisie,
	@ClenKomisie1,
	@ClenKomisie2,
	@Email,
	@NasledujuceZa,
	@KontaktnaOsobaEmail

WHILE @@FETCH_STATUS = 0
BEGIN

--SELECT
--	@ID,
--	@Referencia,
--	@Nazov,
--	@Uskutocnene,
--	@Nasledujuce,
--	@UcastCelkom,
--	@Vyhovelo,
--	@Nevyhovelo,
--	@MiestoKonania,
--	@SkoleniePreKoho,
--	@Typ,
--	@Druh,
--	@FormaSkusania,
--	@Organizacia,
--	@Lektor,
--	@PredsedaKomisie,
--	@ClenKomisie1,
--	@ClenKomisie2,
--	@Email,
--	@NasledujuceZa
	
SET @body = '<!DOCTYPE html>
<html>
	<head>
		<style type="text/css">
			body {font-family: Tahoma; font-size: 10pt;}
			.label {font-weight: bold; padding-right: 10px;}
			.bold {font-weight: bold;}
			th {font-weight: bold; text-align: left; padding-left: 10px;}
			td {padding-left: 10px;}
			.red {color: red;}
		 </style>
	</head>
	<body>
'

SET @body = @body + @Lektor + ',<br/>
Nasleduj˙ce ökolenie sa m· konaù za ' + @NasledujuceZa + ' dnÌ:<br/><br/>
'
--SET @aElement = '<a href="' + @spravaZmluvURL + 'SkoleniaVM?SkolenieID=' + @ID + '">Naviguj na skolenie...</a>'
--SET @aElement = NULL;

SET @body = @body + '
<table>
<tr>
<td class="label">ID: </td><td>' + @ID + '</td>
</tr>
<tr>
<td class="label">Organiz·cia:</td><td>' + @Organizacia + '</td>
</tr>
<tr>
<td class="label">Referencia:</td><td>' + @Referencia + '</td>
</tr>
<tr>
<td class="label">N·zov:</td><td>' + @Nazov + '</td>
</tr>
<tr>
<td class="label">Typ:</td><td>' + @Typ + '</td>
</tr>
<tr>
<td class="label">Druh:</td><td> ' + @Druh + '</td>
</tr>
<tr>
<td class="label">UskutoËnenÈ:</td><td>' + @Uskutocnene + '</td>
</tr>
<tr>
<td class="label">Nasleduj˙ce:</td><td>' + @Nasledujuce + '</td>
</tr>
<tr>
<td class="label">Miesto konania:</td><td>' + @MiestoKonania + '</td>
</tr>
<tr>
<td class="label">äkolenie pre koho:</td><td>' + @SkoleniePreKoho + '</td>
</tr>
</table>
<br/>
--------------------------------------------------------------------------------------------------
<br/>E-mail kontaktn˝ch osÙb:<br/>
' + @KontaktnaOsobaEmail + '<br/>
--------------------------------------------------------------------------------------------------
<br/>
Dobr˝ deÚ,

<br/><br/>dÚa ' + @Uskutocnene + ' sme vykonali, vo Vaöej spoloËnosti, ökolenie: <span class="bold">' + @Typ +
'</span>. Dovoæte, aby sme V·s touto cestou upozornili, ûe o ' + @NasledujuceZa +
' ' +
CASE
	WHEN ISNUMERIC(@NasledujuceZa) = 1 THEN
		CASE
			WHEN @NasledujuceZa = 1 THEN 'deÚ'
			WHEN @NasledujuceZa BETWEEN 2 AND 4 THEN 'dni'
			ELSE 'dnÌ'
		END
	ELSE 'dnÌ'
END +
' uplynie ' + @Lehota  + ' roËn· lehota, v r·mci ktorej by ste mali vykonaù periodickÈ ökolenie.
<br/>Zoznam osÙb, ktorÈ absolvovali ökolenie:
<br/><br/>' + report.PosluchaciNaSkoleniXML(@ID) +
'
<br/>ProsÌme V·s o aktualiz·ciu zoznamu osÙb ako aj n·vrh moûnÈho termÌnu periodickÈho ökolenia.

<br/><br/>œakujem,
<br/>
'

SET @body = @body + '
	</body>
</html>'

--PRINT ''
--PRINT @Email
--PRINT @subject
--PRINT @body

EXEC msdb.dbo.sp_send_dbmail
--@profile_name = 'cizmiak@gmail.com',
@recipients = @Email,
@copy_recipients = 'miroslav.hanzen@gmail.com;monika.hanzenova@gmail.com',

--@recipients = 'matej.cizmarik@2ring.com;miroslav.hanzen@gmail.com',
--@recipients = 'matej.cizmarik@2ring.com',
--@blind_copy_recipients = 'matej.cizmarik@2ring.com',

@subject = @subject,
@body = @body,
@body_format = 'HTML'

INSERT INTO dbo.SkolenieNotificated(ID, Referencia, SkolenieNazov, Uskutocnene, Nasledujuce, UcastCelkom, Vyhovelo, Nevyhovelo, MiestoKonania, SkoleniePreKoho, Typ, Druh, FormaSkusania, Organizacia, Lektor, PredsedaKomisie, ClenKomisie1, ClenKomisie2, Email, NasledujuceZa)
VALUES
(	@ID,
	@Referencia,
	@Nazov,
	@Uskutocnene,
	@Nasledujuce,
	@UcastCelkom,
	@Vyhovelo,
	@Nevyhovelo,
	@MiestoKonania,
	@SkoleniePreKoho,
	@Typ,
	@Druh,
	@FormaSkusania,
	@Organizacia,
	@Lektor,
	@PredsedaKomisie,
	@ClenKomisie1,
	@ClenKomisie2,
	@Email,
	@NasledujuceZa
)

FETCH NEXT FROM cur INTO
	@ID,
	@Referencia,
	@Nazov,
	@Uskutocnene,
	@Nasledujuce,
	@Lehota,
	@UcastCelkom,
	@Vyhovelo,
	@Nevyhovelo,
	@MiestoKonania,
	@SkoleniePreKoho,
	@Typ,
	@Druh,
	@FormaSkusania,
	@Organizacia,
	@Lektor,
	@PredsedaKomisie,
	@ClenKomisie1,
	@ClenKomisie2,
	@Email,
	@NasledujuceZa,
	@KontaktnaOsobaEmail
END

CLOSE cur
DEALLOCATE cur
GO