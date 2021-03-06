USE [SpravaZmluv]
GO
/****** Object:  StoredProcedure [dbo].[SkolenieNotification]    Script Date: 26.01.2016 19:44:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
SET @subject = 'Notifikácia nasledujúceho školenia'
--SET @Today = '2014-09-01'
--SET @subject = '!!!test vymazte(ako by bolo 1.9.2014)!!! Notifikácia nasledujúceho školenia'

DELETE FROM dbo.SkolenieNotificated WHERE InsertedDateTime < @Today - 90

SELECT @spravaZmluvURL = Hodnota FROM dbo.Konfiguracia WHERE Nastavenie = 'SpravaZmluvURL'
SET @spravaZmluvURL = @spravaZmluvURL + '/#/'

DECLARE cur CURSOR FOR
SELECT
	s.ID AS ID
	,ISNULL(s.Referencia, 'Nezadané') AS Referencia
	,ISNULL(s.Nazov, 'Nezadané') AS  SkolenieNazov
	,ISNULL(CONVERT(VARCHAR(50), s.Uskutocnene, 104), 'Nezadané') AS Uskutocnene
	,CONVERT(VARCHAR(50), s.Nasledujuce, 104) AS Nasledujuce
	,ISNULL(CAST(YEAR(s.Nasledujuce) - YEAR(s.Uskutocnene) AS VARCHAR(5)), 'Nezadané') AS Lehota
	,ISNULL(CAST(s.UcastCelkom AS VARCHAR(50)), 'Nezadané') AS UcastCelkom
	,ISNULL(CAST(s.Vyhovelo AS VARCHAR(50)), 'Nezadané') AS Vyhovelo
	,ISNULL(CAST(s.Nevyhovelo AS VARCHAR(50)), 'Nezadané') AS Nevyhovelo
	,ISNULL(s.MiestoKonania, 'Nezadané') AS MiestoKonania
	,ISNULL(skp.Nazov, 'Nezadané') AS SkoleniePreKoho
	,ISNULL(st.Nazov, 'Nezadané')  AS Typ
	,ISNULL(sd.Nazov, 'Nezadané')  AS Druh
	,ISNULL(sfs.Nazov, 'Nezadané')  AS FormaSkusania
	,ISNULL(o.Nazov, 'Nezadané')  AS Organizacia
	,COALESCE(notifikovany.Priezvisko + ' ' + notifikovany.Meno, z.Priezvisko + ' ' + z.Meno, 'Nezadané')  AS Lektor
	,ISNULL(p.Priezvisko + ' ' + p.Meno, 'Nezadané')  AS PredsedaKomisie
	,ISNULL(c1.Priezvisko + ' ' + c1.Meno, 'Nezadané')  AS ClenKomisie1
	,ISNULL(c2.Priezvisko + ' ' + c2.Meno, 'Nezadané')  AS ClenKomisie2
	,COALESCE(notifikovany.Email, z.Email, 'miroslav.hanzen@gmail.com') + ISNULL(';' + nad.Email, '') + ISNULL(';' + zod.Email, '') AS Email
	,ISNULL(CAST(CAST(FLOOR(CAST(s.Nasledujuce AS FLOAT)) - @Today AS INT) AS VARCHAR(20)), 'xy') AS NasledujuceZa
	,ISNULL(report.GetKontaktnaOsobaEmail(s.OrganizaciaID), 'Nezadané') AS KontaktnaOsobaEmail
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
Nasledujúce školenie sa má konať za ' + @NasledujuceZa + ' dní:<br/><br/>
'
--SET @aElement = '<a href="' + @spravaZmluvURL + 'SkoleniaVM?SkolenieID=' + @ID + '">Naviguj na skolenie...</a>'
--SET @aElement = NULL;

SET @body = @body + '
<table>
<tr>
<td class="label">ID: </td><td>' + @ID + '</td>
</tr>
<tr>
<td class="label">Organizácia:</td><td>' + @Organizacia + '</td>
</tr>
<tr>
<td class="label">Referencia:</td><td>' + @Referencia + '</td>
</tr>
<tr>
<td class="label">Názov:</td><td>' + @Nazov + '</td>
</tr>
<tr>
<td class="label">Typ:</td><td>' + @Typ + '</td>
</tr>
<tr>
<td class="label">Druh:</td><td> ' + @Druh + '</td>
</tr>
<tr>
<td class="label">Uskutočnené:</td><td>' + @Uskutocnene + '</td>
</tr>
<tr>
<td class="label">Nasledujúce:</td><td>' + @Nasledujuce + '</td>
</tr>
<tr>
<td class="label">Miesto konania:</td><td>' + @MiestoKonania + '</td>
</tr>
<tr>
<td class="label">Školenie pre koho:</td><td>' + @SkoleniePreKoho + '</td>
</tr>
</table>
<br/>
--------------------------------------------------------------------------------------------------
<br/>E-mail kontaktných osôb:<br/>
' + @KontaktnaOsobaEmail + '<br/>
--------------------------------------------------------------------------------------------------
<br/>
Dobrý deň,

<br/><br/>dňa ' + @Uskutocnene + ' sme vykonali, vo Vašej spoločnosti, školenie: <span class="bold">' + @Typ +
'</span>. Dovoľte, aby sme Vás touto cestou upozornili, že o ' + @NasledujuceZa +
' ' +
CASE
	WHEN ISNUMERIC(@NasledujuceZa) = 1 THEN
		CASE
			WHEN @NasledujuceZa = 1 THEN 'deň'
			WHEN @NasledujuceZa BETWEEN 2 AND 4 THEN 'dni'
			ELSE 'dní'
		END
	ELSE 'dní'
END +
' uplynie ' + @Lehota  + ' ročná lehota, v rámci ktorej by ste mali vykonať periodické školenie.
<br/>Zoznam osôb, ktoré absolvovali školenie:
<br/><br/>' + report.PosluchaciNaSkoleniXML(@ID) +
'
<br/>Prosíme Vás o aktualizáciu zoznamu osôb ako aj návrh možného termínu periodického školenia.

<br/><br/>Ďakujem,
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